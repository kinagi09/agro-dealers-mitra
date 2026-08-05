from rest_framework import viewsets, permissions, status
from rest_framework.response import Response
from .models import (
    State, District, Taluka, Dealer,
    LicenceCategory, LicenceType, Licence,
    NotificationPreference, LicenceEntry, FertilizerType,
)
from .serializers import (
    StateSerializer, DistrictSerializer, TalukaSerializer, DealerSerializer,
    LicenceCategorySerializer, LicenceTypeSerializer,
    LicenceSerializer, NotificationPreferenceSerializer,
    LicenceEntrySerializer, FertilizerTypeSerializer,
)


class StateViewSet(viewsets.ReadOnlyModelViewSet):
    queryset = State.objects.all()
    serializer_class = StateSerializer
    permission_classes = [permissions.AllowAny]


class DistrictViewSet(viewsets.ReadOnlyModelViewSet):
    queryset = District.objects.all()
    serializer_class = DistrictSerializer
    permission_classes = [permissions.AllowAny]

    def get_queryset(self):
        queryset = super().get_queryset()
        state_id = self.request.query_params.get("state")
        if state_id:
            queryset = queryset.filter(state_id=state_id)
        return queryset


class TalukaViewSet(viewsets.ReadOnlyModelViewSet):
    queryset = Taluka.objects.all()
    serializer_class = TalukaSerializer
    permission_classes = [permissions.AllowAny]

    def get_queryset(self):
        queryset = super().get_queryset()
        district_id = self.request.query_params.get("district")
        if district_id:
            queryset = queryset.filter(district_id=district_id)
        return queryset


class DealerViewSet(viewsets.ModelViewSet):
    queryset = Dealer.objects.all()
    serializer_class = DealerSerializer
    permission_classes = [permissions.IsAuthenticated]

    def get_queryset(self):
        queryset = super().get_queryset()
        # A dealer should only ever see their own record, not everyone else's
        if not self.request.user.is_staff:
            queryset = queryset.filter(user=self.request.user)
        return queryset


class LicenceCategoryViewSet(viewsets.ReadOnlyModelViewSet):
    queryset = LicenceCategory.objects.all()
    serializer_class = LicenceCategorySerializer
    permission_classes = [permissions.AllowAny]


class LicenceTypeViewSet(viewsets.ReadOnlyModelViewSet):
    queryset = LicenceType.objects.all()
    serializer_class = LicenceTypeSerializer
    permission_classes = [permissions.AllowAny]

    def get_queryset(self):
        queryset = super().get_queryset()
        category_id = self.request.query_params.get("category")
        if category_id:
            queryset = queryset.filter(category_id=category_id)
        return queryset


class LicenceViewSet(viewsets.ModelViewSet):
    queryset = Licence.objects.all()
    serializer_class = LicenceSerializer
    permission_classes = [permissions.IsAuthenticated]

    def get_queryset(self):
        queryset = super().get_queryset()
        if not self.request.user.is_staff:
            queryset = queryset.filter(dealer__user=self.request.user)
        category_id = self.request.query_params.get("category")
        if category_id:
            queryset = queryset.filter(licence_type__category_id=category_id)
        return queryset

    def create(self, request, *args, **kwargs):
        dealer_id = request.data.get("dealer")
        licence_type_id = request.data.get("licence_type")
        if dealer_id and licence_type_id:
            existing = Licence.objects.filter(
                dealer_id=dealer_id,
                licence_type_id=licence_type_id,
            ).first()
            if existing:
                return Response(
                    {"detail": f"A licence already exists for this licence type (ID {existing.id}). Please update it instead."},
                    status=status.HTTP_400_BAD_REQUEST,
                )
        return super().create(request, *args, **kwargs)


class NotificationPreferenceViewSet(viewsets.ModelViewSet):
    queryset = NotificationPreference.objects.all()
    serializer_class = NotificationPreferenceSerializer
    permission_classes = [permissions.IsAuthenticated]

    def get_queryset(self):
        queryset = super().get_queryset()
        if not self.request.user.is_staff:
            queryset = queryset.filter(dealer__user=self.request.user)
        return queryset


class LicenceEntryViewSet(viewsets.ModelViewSet):
    queryset = LicenceEntry.objects.all()
    serializer_class = LicenceEntrySerializer
    permission_classes = [permissions.IsAuthenticated]

    def get_queryset(self):
        queryset = super().get_queryset()
        if not self.request.user.is_staff:
            queryset = queryset.filter(licence__dealer__user=self.request.user)
        licence_id = self.request.query_params.get("licence")
        if licence_id:
            queryset = queryset.filter(licence_id=licence_id)
        return queryset


class FertilizerTypeViewSet(viewsets.ReadOnlyModelViewSet):
    queryset = FertilizerType.objects.all()
    serializer_class = FertilizerTypeSerializer
    permission_classes = [permissions.AllowAny]