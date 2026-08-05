from rest_framework.routers import DefaultRouter
from django.urls import path
from .views import (
    StateViewSet, DistrictViewSet, TalukaViewSet, DealerViewSet,
    LicenceCategoryViewSet, LicenceTypeViewSet,
    LicenceViewSet, NotificationPreferenceViewSet, LicenceEntryViewSet, FertilizerTypeViewSet
)
from .auth_views import SendOTPView, RegisterDealerView, LoginView, VerifyOTPView

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

from rest_framework_simplejwt.views import TokenRefreshView

urlpatterns = router.urls + [
    path("auth/send-otp/", SendOTPView.as_view(), name="send-otp"),
    path("auth/verify-otp/", VerifyOTPView.as_view(), name="verify-otp"),
    path("auth/register/", RegisterDealerView.as_view(), name="register-dealer"),
    path("auth/login/", LoginView.as_view(), name="login"),
    path("token/refresh/", TokenRefreshView.as_view(), name="token-refresh"),
]