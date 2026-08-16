from rest_framework.permissions import BasePermission


class HasActiveSubscription(BasePermission):
    """Gates licence/notification data behind an active paid subscription.
    Staff bypass this entirely - dealers must pay to use these endpoints,
    staff never subscribe themselves. Not applied to the Dealer or
    Subscription endpoints, since a dealer needs those to pay in the first
    place.
    """

    message = "An active subscription is required to access this."

    def has_permission(self, request, view):
        user = request.user
        if not user.is_authenticated:
            return False
        if user.is_staff:
            return True
        dealer = getattr(user, "dealer", None)
        if dealer is None:
            return False
        subscription = getattr(dealer, "subscription", None)
        return bool(subscription and subscription.is_active)
