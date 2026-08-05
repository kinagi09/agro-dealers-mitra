from rest_framework.views import APIView
from rest_framework.response import Response
from rest_framework import status, permissions
from rest_framework_simplejwt.tokens import RefreshToken
from django.contrib.auth.models import User
from .models import Dealer, OTPVerification, NotificationPreference
from .serializers import SendOTPSerializer, VerifyOTPSerializer, DealerRegistrationSerializer


class SendOTPView(APIView):
    permission_classes = [permissions.AllowAny]

    def post(self, request):
        serializer = SendOTPSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        whatsapp_number = serializer.validated_data["whatsapp_number"]
        purpose = serializer.validated_data["purpose"]

        dealer_exists = Dealer.objects.filter(whatsapp_number=whatsapp_number).exists()

        if purpose == "register" and dealer_exists:
            return Response(
                {"detail": "This number is already registered. Please log in instead."},
                status=status.HTTP_400_BAD_REQUEST,
            )
        if purpose == "login" and not dealer_exists:
            return Response(
                {"detail": "This number is not registered. Please register first."},
                status=status.HTTP_400_BAD_REQUEST,
            )

        otp_code = OTPVerification.generate_otp()
        OTPVerification.objects.create(whatsapp_number=whatsapp_number, otp_code=otp_code)

        print(f"[STUB OTP] Sending OTP {otp_code} to {whatsapp_number}")

        return Response({"detail": "OTP sent."}, status=status.HTTP_200_OK)


class VerifyOTPView(APIView):
    permission_classes = [permissions.AllowAny]

    def post(self, request):
        serializer = VerifyOTPSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        whatsapp_number = serializer.validated_data["whatsapp_number"]
        otp_code = serializer.validated_data["otp_code"]

        otp_entry = OTPVerification.objects.filter(
            whatsapp_number=whatsapp_number, otp_code=otp_code, is_verified=False
        ).first()

        if not otp_entry or otp_entry.is_expired():
            return Response({"detail": "Invalid or expired OTP."}, status=status.HTTP_400_BAD_REQUEST)

        otp_entry.is_verified = True
        otp_entry.save()

        return Response({"detail": "OTP verified."}, status=status.HTTP_200_OK)


class RegisterDealerView(APIView):
    permission_classes = [permissions.AllowAny]

    def post(self, request):
        whatsapp_number = request.data.get("whatsapp_number")

        if Dealer.objects.filter(whatsapp_number=whatsapp_number).exists():
            return Response(
                {"detail": "This number is already registered. Please log in instead."},
                status=status.HTTP_400_BAD_REQUEST,
            )

        verified_otp = OTPVerification.objects.filter(
            whatsapp_number=whatsapp_number, is_verified=True
        ).order_by("-created_at").first()

        if not verified_otp or verified_otp.is_expired():
            return Response(
                {"detail": "Please verify your OTP again before registering."},
                status=status.HTTP_400_BAD_REQUEST,
            )

        dealer_serializer = DealerRegistrationSerializer(data=request.data)
        dealer_serializer.is_valid(raise_exception=True)

        user = User.objects.create(username=whatsapp_number)
        user.set_unusable_password()
        user.save()

        dealer = dealer_serializer.save(user=user)
        NotificationPreference.objects.create(dealer=dealer)

        refresh = RefreshToken.for_user(user)
        return Response({
            "access": str(refresh.access_token),
            "refresh": str(refresh),
            "dealer_id": dealer.id,
        }, status=status.HTTP_201_CREATED)


class LoginView(APIView):
    permission_classes = [permissions.AllowAny]

    def post(self, request):
        serializer = VerifyOTPSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        whatsapp_number = serializer.validated_data["whatsapp_number"]
        otp_code = serializer.validated_data["otp_code"]

        otp_entry = OTPVerification.objects.filter(
            whatsapp_number=whatsapp_number, otp_code=otp_code, is_verified=False
        ).first()

        if not otp_entry or otp_entry.is_expired():
            return Response({"detail": "Invalid or expired OTP."}, status=status.HTTP_400_BAD_REQUEST)

        try:
            dealer = Dealer.objects.get(whatsapp_number=whatsapp_number)
        except Dealer.DoesNotExist:
            return Response({"detail": "No account found for this number."}, status=status.HTTP_404_NOT_FOUND)

        otp_entry.is_verified = True
        otp_entry.save()

        refresh = RefreshToken.for_user(dealer.user)
        return Response({
            "access": str(refresh.access_token),
            "refresh": str(refresh),
            "dealer_id": dealer.id,
        }, status=status.HTTP_200_OK)