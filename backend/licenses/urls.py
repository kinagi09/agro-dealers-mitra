from rest_framework.routers import DefaultRouter
from django.urls import path
from .views import (
    StateViewSet, DistrictViewSet, TalukaViewSet, DealerViewSet,
    LicenceCategoryViewSet, LicenceTypeViewSet,
    LicenceViewSet, NotificationPreferenceViewSet, LicenceEntryViewSet, FertilizerTypeViewSet,
    NotificationLogViewSet,
)
from .auth_views import SendOTPView, RegisterDealerView, LoginView, VerifyOTPView
from .subscription_views import (
    SubscriptionCreateView, SubscriptionVerifyView, SubscriptionStatusView,
    RazorpayWebhookView,
)

router = DefaultRouter()
router.register(r"states", StateViewSet, basename="state")
router.register(r"districts", DistrictViewSet, basename="district")
router.register(r"talukas", TalukaViewSet, basename="taluka")
router.register(r"dealers", DealerViewSet, basename="dealer")
router.register(r"licence-categories", LicenceCategoryViewSet, basename="licence-category")
router.register(r"licence-types", LicenceTypeViewSet, basename="licence-type")
router.register(r"licences", LicenceViewSet, basename="licence")
router.register(r"notification-preferences", NotificationPreferenceViewSet, basename="notification-preference")
router.register(r"licence-entries", LicenceEntryViewSet, basename="licence-entry")
router.register(r"fertilizer-types", FertilizerTypeViewSet, basename="fertilizer-type")
router.register(r"notifications", NotificationLogViewSet, basename="notification")

from rest_framework_simplejwt.views import TokenRefreshView, TokenObtainPairView

urlpatterns = router.urls + [
    path("auth/send-otp/", SendOTPView.as_view(), name="send-otp"),
    path("auth/verify-otp/", VerifyOTPView.as_view(), name="verify-otp"),
    path("auth/register/", RegisterDealerView.as_view(), name="register-dealer"),
    path("auth/login/", LoginView.as_view(), name="login"),
    # Staff/admin login only - dealers authenticate via WhatsApp OTP above and
    # have an unusable Django password, so they can never reach this path.
    path("auth/staff-login/", TokenObtainPairView.as_view(), name="staff-login"),
    path("token/refresh/", TokenRefreshView.as_view(), name="token-refresh"),
    path("subscription/create/", SubscriptionCreateView.as_view(), name="subscription-create"),
    path("subscription/verify/", SubscriptionVerifyView.as_view(), name="subscription-verify"),
    path("subscription/status/", SubscriptionStatusView.as_view(), name="subscription-status"),
    path("subscription/webhook/", RazorpayWebhookView.as_view(), name="subscription-webhook"),
]