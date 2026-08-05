from django.contrib import admin
from .models import (
    State, District, Taluka, Dealer,
    LicenceCategory, LicenceType, Licence,
    NotificationPreference, ReminderSchedule, NotificationLog,
    OTPVerification, LicenceEntry, FertilizerType
)


@admin.register(State)
class StateAdmin(admin.ModelAdmin):
    list_display = ("name",)
    search_fields = ("name",)


@admin.register(District)
class DistrictAdmin(admin.ModelAdmin):
    list_display = ("name", "state")
    list_filter = ("state",)
    search_fields = ("name",)
    autocomplete_fields = ("state",)


@admin.register(Taluka)
class TalukaAdmin(admin.ModelAdmin):
    list_display = ("name", "district")
    list_filter = ("district__state", "district")
    search_fields = ("name",)
    autocomplete_fields = ("district",)


@admin.register(Dealer)
class DealerAdmin(admin.ModelAdmin):
    list_display = ("shop_name", "name", "whatsapp_number", "taluka", "created_at")
    list_filter = ("taluka__district__state", "taluka__district")
    search_fields = ("shop_name", "name", "whatsapp_number")
    autocomplete_fields = ("taluka",)
    readonly_fields = ("created_at",)


@admin.register(LicenceCategory)
class LicenceCategoryAdmin(admin.ModelAdmin):
    list_display = ("name",)
    search_fields = ("name",)


@admin.register(LicenceType)
class LicenceTypeAdmin(admin.ModelAdmin):
    list_display = ("name", "category")
    list_filter = ("category",)
    search_fields = ("name",)
    autocomplete_fields = ("category",)


@admin.register(Licence)
class LicenceAdmin(admin.ModelAdmin):
    list_display = (
        "licence_number", "dealer", "licence_type",
        "issue_date", "expiry_date", "status"
    )
    list_filter = ("status", "licence_type")
    search_fields = ("licence_number", "dealer__shop_name", "dealer__name")
    autocomplete_fields = ("dealer", "licence_type")
    date_hierarchy = "expiry_date"


@admin.register(NotificationPreference)
class NotificationPreferenceAdmin(admin.ModelAdmin):
    list_display = ("dealer", "push_enabled", "whatsapp_enabled")
    autocomplete_fields = ("dealer",)


@admin.register(ReminderSchedule)
class ReminderScheduleAdmin(admin.ModelAdmin):
    list_display = ("licence", "days_before_expiry", "scheduled_date", "is_sent")
    list_filter = ("is_sent", "days_before_expiry")
    autocomplete_fields = ("licence",)
    date_hierarchy = "scheduled_date"


@admin.register(NotificationLog)
class NotificationLogAdmin(admin.ModelAdmin):
    list_display = ("dealer", "licence", "channel", "status", "sent_at")
    list_filter = ("channel", "status")
    search_fields = ("dealer__shop_name",)
    autocomplete_fields = ("dealer", "licence")
    date_hierarchy = "sent_at"
    readonly_fields = ("sent_at",)


@admin.register(OTPVerification)
class OTPVerificationAdmin(admin.ModelAdmin):
    list_display = ("whatsapp_number", "otp_code", "is_verified", "created_at")
    list_filter = ("is_verified",)
    search_fields = ("whatsapp_number",)


@admin.register(LicenceEntry)
class LicenceEntryAdmin(admin.ModelAdmin):
    list_display = ("licence", "source_type", "company_name", "valid_upto")
    search_fields = ("company_name", "licence__licence_number")
    autocomplete_fields = ("licence",)
    filter_horizontal = ("fertilizer_type",)

@admin.register(FertilizerType)
class FertilizerTypeAdmin(admin.ModelAdmin):
    list_display = ("name",)
    search_fields = ("name",)