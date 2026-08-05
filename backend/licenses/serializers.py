from rest_framework import serializers
from .models import (
    State, District, Taluka, Dealer, LicenceCategory, LicenceType, Licence,
    NotificationPreference, LicenceEntry, FertilizerType,
)


class StateSerializer(serializers.ModelSerializer):
    class Meta:
        model = State
        fields = ["id", "name"]


class DistrictSerializer(serializers.ModelSerializer):
    class Meta:
        model = District
        fields = ["id", "name", "state"]


class TalukaSerializer(serializers.ModelSerializer):
    class Meta:
        model = Taluka
        fields = ["id", "name", "district"]


class DealerSerializer(serializers.ModelSerializer):
    class Meta:
        model = Dealer
        fields = [
            "id", "name", "shop_name", "whatsapp_number",
            "address", "taluka", "created_at",
        ]
        read_only_fields = ["id", "created_at"]


class LicenceCategorySerializer(serializers.ModelSerializer):
    class Meta:
        model = LicenceCategory
        fields = ["id", "name"]


class LicenceTypeSerializer(serializers.ModelSerializer):
    class Meta:
        model = LicenceType
        fields = ["id", "name", "category"]


class LicenceSerializer(serializers.ModelSerializer):
    dealer_name = serializers.CharField(source="dealer.name", read_only=True)
    licence_type_name = serializers.CharField(source="licence_type.name", read_only=True)

    class Meta:
        model = Licence
        fields = [
            "id", "dealer", "dealer_name", "licence_type", "licence_type_name",
            "licence_number", "issue_date", "expiry_date", "status", "created_at", "updated_at",         
        ]
        read_only_fields = ["id", "status", "created_at", "updated_at"]


class NotificationPreferenceSerializer(serializers.ModelSerializer):
    class Meta:
        model = NotificationPreference
        fields = ["id", "dealer", "push_enabled", "whatsapp_enabled", "fcm_token"]


class SendOTPSerializer(serializers.Serializer):
    whatsapp_number = serializers.CharField(max_length=15)
    purpose = serializers.ChoiceField(choices=["register", "login"], default="register")


class VerifyOTPSerializer(serializers.Serializer):
    whatsapp_number = serializers.CharField(max_length=15)
    otp_code = serializers.CharField(max_length=6)


class DealerRegistrationSerializer(serializers.ModelSerializer):
    class Meta:
        model = Dealer
        fields = ["name", "shop_name", "whatsapp_number", "address", "taluka"]


class FertilizerTypeSerializer(serializers.ModelSerializer):
    class Meta:
        model = FertilizerType
        fields = ["id", "name"]


class LicenceEntrySerializer(serializers.ModelSerializer):
    fertilizer_type = serializers.PrimaryKeyRelatedField(
        queryset=FertilizerType.objects.all(), many=True, required=False
    )

    class Meta:
        model = LicenceEntry
        fields = ["id", "licence", "source_type", "company_name", "fertilizer_type", "valid_upto"]