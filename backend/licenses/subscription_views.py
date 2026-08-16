from datetime import datetime, timezone as dt_timezone

import razorpay
from django.conf import settings
from django.shortcuts import get_object_or_404
from rest_framework import permissions, status
from rest_framework.response import Response
from rest_framework.views import APIView

from .models import Dealer, Subscription
from .razorpay_client import get_client


def _apply_razorpay_fields(subscription, rp_subscription):
    subscription.status = rp_subscription.get("status", subscription.status)
    if rp_subscription.get("current_start"):
        subscription.current_start = datetime.fromtimestamp(
            rp_subscription["current_start"], tz=dt_timezone.utc
        )
    if rp_subscription.get("current_end"):
        subscription.current_end = datetime.fromtimestamp(
            rp_subscription["current_end"], tz=dt_timezone.utc
        )


class SubscriptionCreateView(APIView):
    permission_classes = [permissions.IsAuthenticated]

    def post(self, request):
        try:
            dealer = request.user.dealer
        except Dealer.DoesNotExist:
            return Response(
                {"detail": "No dealer account found for this user."},
                status=status.HTTP_400_BAD_REQUEST,
            )

        existing = getattr(dealer, "subscription", None)
        if existing and existing.is_active:
            return Response(
                {"detail": "You already have an active subscription."},
                status=status.HTTP_400_BAD_REQUEST,
            )

        client = get_client()
        rp_subscription = client.subscription.create({
            "plan_id": settings.RAZORPAY_PLAN_ID,
            "customer_notify": 1,
            # Effectively indefinite auto-renewal (100 yearly cycles) rather
            # than a fixed end - the dealer/staff can cancel any time.
            "total_count": 100,
        })

        Subscription.objects.update_or_create(
            dealer=dealer,
            defaults={
                "razorpay_subscription_id": rp_subscription["id"],
                "status": rp_subscription["status"],
            },
        )

        return Response({
            "subscription_id": rp_subscription["id"],
            "key_id": settings.RAZORPAY_KEY_ID,
        }, status=status.HTTP_201_CREATED)


class SubscriptionVerifyView(APIView):
    permission_classes = [permissions.IsAuthenticated]

    def post(self, request):
        try:
            dealer = request.user.dealer
        except Dealer.DoesNotExist:
            return Response(
                {"detail": "No dealer account found for this user."},
                status=status.HTTP_400_BAD_REQUEST,
            )

        razorpay_payment_id = request.data.get("razorpay_payment_id")
        razorpay_subscription_id = request.data.get("razorpay_subscription_id")
        razorpay_signature = request.data.get("razorpay_signature")

        if not all([razorpay_payment_id, razorpay_subscription_id, razorpay_signature]):
            return Response(
                {"detail": "Missing payment verification fields."},
                status=status.HTTP_400_BAD_REQUEST,
            )

        client = get_client()
        try:
            client.utility.verify_subscription_payment_signature({
                "razorpay_payment_id": razorpay_payment_id,
                "razorpay_subscription_id": razorpay_subscription_id,
                "razorpay_signature": razorpay_signature,
            })
        except razorpay.errors.SignatureVerificationError:
            return Response(
                {"detail": "Payment verification failed."},
                status=status.HTTP_400_BAD_REQUEST,
            )

        # Signature is valid - pull the authoritative state from Razorpay
        # itself rather than trusting anything else the client sent.
        rp_subscription = client.subscription.fetch(razorpay_subscription_id)

        subscription = get_object_or_404(
            Subscription, dealer=dealer, razorpay_subscription_id=razorpay_subscription_id
        )
        _apply_razorpay_fields(subscription, rp_subscription)
        subscription.save()

        return Response({"status": subscription.status}, status=status.HTTP_200_OK)


class SubscriptionStatusView(APIView):
    permission_classes = [permissions.IsAuthenticated]

    def get(self, request):
        try:
            dealer = request.user.dealer
        except Dealer.DoesNotExist:
            return Response(
                {"detail": "No dealer account found for this user."},
                status=status.HTTP_400_BAD_REQUEST,
            )

        subscription = getattr(dealer, "subscription", None)
        if not subscription:
            return Response({"status": None, "is_active": False})

        return Response({
            "status": subscription.status,
            "is_active": subscription.is_active,
            "current_end": subscription.current_end,
        })


class RazorpayWebhookView(APIView):
    permission_classes = [permissions.AllowAny]

    def post(self, request):
        signature = request.headers.get("X-Razorpay-Signature")
        body = request.body.decode("utf-8")

        client = get_client()
        try:
            client.utility.verify_webhook_signature(
                body, signature, settings.RAZORPAY_WEBHOOK_SECRET
            )
        except razorpay.errors.SignatureVerificationError:
            return Response(status=status.HTTP_400_BAD_REQUEST)

        payload = request.data.get("payload", {})
        rp_subscription = payload.get("subscription", {}).get("entity")

        if rp_subscription:
            subscription = Subscription.objects.filter(
                razorpay_subscription_id=rp_subscription.get("id")
            ).first()
            if subscription:
                _apply_razorpay_fields(subscription, rp_subscription)
                subscription.save()

        return Response(status=status.HTTP_200_OK)
