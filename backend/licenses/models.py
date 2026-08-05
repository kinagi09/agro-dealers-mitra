from django.db import models
from django.contrib.auth.models import User
from django.core.exceptions import ValidationError
from django.core.validators import RegexValidator
import random
from django.utils import timezone
from datetime import timedelta


class State(models.Model):
    name = models.CharField(max_length=100, unique=True)

    class Meta:
        ordering = ["name"]

    def __str__(self):
        return self.name


class District(models.Model):
    state = models.ForeignKey(State, on_delete=models.CASCADE, related_name="districts")
    name = models.CharField(max_length=100)

    class Meta:
        ordering = ["name"]
        unique_together = ("state", "name")

    def __str__(self):
        return f"{self.name}, {self.state.name}"


class Taluka(models.Model):
    district = models.ForeignKey(District, on_delete=models.CASCADE, related_name="talukas")
    name = models.CharField(max_length=100)

    class Meta:
        ordering = ["name"]
        unique_together = ("district", "name")

    def __str__(self):
        return f"{self.name}, {self.district.name}"


class Dealer(models.Model):
    name = models.CharField(max_length=200)
    shop_name = models.CharField(max_length=200)
    whatsapp_number = models.CharField(
        max_length=15,
        unique=True,
        validators=[RegexValidator(r'^(\+91|91)?\d{10}$', 'Enter a valid Indian WhatsApp number.')],
        help_text="Used for OTP login and WhatsApp notifications."
    )
    address = models.TextField()
    taluka = models.ForeignKey(
        Taluka,
        on_delete=models.PROTECT,
        related_name="dealers"
    )
    created_at = models.DateTimeField(auto_now_add=True)
    user = models.OneToOneField(
        User,
        on_delete=models.CASCADE,
        null=True,
        blank=True
    )

    class Meta:
        ordering = ["shop_name"]

    def __str__(self):
        return f"{self.shop_name} ({self.name})"


class LicenceCategory(models.Model):
    name = models.CharField(max_length=100, unique=True)

    class Meta:
        ordering = ["name"]
        verbose_name = "Licence Category"
        verbose_name_plural = "Licence Categories"

    def __str__(self):
        return self.name


class LicenceType(models.Model):
    category = models.ForeignKey(
        LicenceCategory,
        on_delete=models.CASCADE,
        related_name="licence_types"
    )
    name = models.CharField(max_length=150)

    class Meta:
        ordering = ["name"]
        unique_together = ("category", "name")
        verbose_name = "Licence Type"
        verbose_name_plural = "Licence Types"

    def __str__(self):
        return f"{self.category.name} - {self.name}"


class Licence(models.Model):

    STATUS_CHOICES = [
        ("ACTIVE", "Active"),
        ("EXPIRING_SOON", "Expiring Soon"),
        ("EXPIRED", "Expired"),
        ("RENEWED", "Renewed"),
    ]

    dealer = models.ForeignKey(Dealer, on_delete=models.CASCADE, related_name="licences")
    licence_type = models.ForeignKey(
        LicenceType,
        on_delete=models.PROTECT,
        related_name="licences"
    )

    licence_number = models.CharField(max_length=100, unique=True)
    issue_date = models.DateField()
    expiry_date = models.DateField()
    status = models.CharField(max_length=20, choices=STATUS_CHOICES, default="ACTIVE")
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        ordering = ["expiry_date"]
        verbose_name = "Licence"
        verbose_name_plural = "Licences"
        indexes = [
            models.Index(fields=["expiry_date"]),
            models.Index(fields=["status"]),
            models.Index(fields=["dealer"]),
            models.Index(fields=["licence_type"]),
        ]

    def clean(self):
        if self.expiry_date and self.issue_date and self.expiry_date <= self.issue_date:
            raise ValidationError("Expiry date must be after issue date.")

    def save(self, *args, **kwargs):
        self.full_clean()
        super().save(*args, **kwargs)

    def __str__(self):
        return f"{self.licence_number} - {self.licence_type.name}"


class NotificationPreference(models.Model):
    dealer = models.OneToOneField(
        Dealer,
        on_delete=models.CASCADE,
        related_name="notification_preference"
    )
    push_enabled = models.BooleanField(default=True)
    whatsapp_enabled = models.BooleanField(default=True)
    fcm_token = models.CharField(max_length=255, blank=True, null=True)

    class Meta:
        verbose_name = "Notification Preference"
        verbose_name_plural = "Notification Preferences"

    def __str__(self):
        return f"Preferences - {self.dealer.shop_name}"


class ReminderSchedule(models.Model):
    licence = models.ForeignKey(
        Licence,
        on_delete=models.CASCADE,
        related_name="reminders"
    )
    days_before_expiry = models.PositiveIntegerField()
    scheduled_date = models.DateField()
    is_sent = models.BooleanField(default=False)

    class Meta:
        ordering = ["scheduled_date"]
        indexes = [
            models.Index(fields=["scheduled_date"]),
            models.Index(fields=["is_sent"]),
        ]

    def __str__(self):
        return f"{self.licence.licence_number} ({self.days_before_expiry} days)"


class NotificationLog(models.Model):
    CHANNEL_CHOICES = [
        ("PUSH", "Push Notification"),
        ("WHATSAPP", "WhatsApp"),
    ]

    STATUS_CHOICES = [
        ("PENDING", "Pending"),
        ("SENT", "Sent"),
        ("FAILED", "Failed"),
        ("STUBBED", "Stubbed (not actually sent)"),
    ]

    dealer = models.ForeignKey(
        Dealer,
        on_delete=models.CASCADE,
        related_name="notification_logs"
    )
    licence = models.ForeignKey(
        Licence,
        on_delete=models.CASCADE,
        related_name="notification_logs"
    )
    channel = models.CharField(max_length=10, choices=CHANNEL_CHOICES)
    status = models.CharField(max_length=10, choices=STATUS_CHOICES, default="PENDING")
    message_content = models.TextField(blank=True, null=True)
    sent_at = models.DateTimeField(auto_now_add=True)
    error_message = models.TextField(blank=True, null=True)

    class Meta:
        ordering = ["-sent_at"]
        indexes = [
            models.Index(fields=["channel"]),
            models.Index(fields=["status"]),
            models.Index(fields=["sent_at"]),
        ]

    def __str__(self):
        return f"{self.channel} | {self.dealer.shop_name} | {self.status}"


class OTPVerification(models.Model):
    whatsapp_number = models.CharField(max_length=15)
    otp_code = models.CharField(max_length=6)
    created_at = models.DateTimeField(auto_now_add=True)
    is_verified = models.BooleanField(default=False)

    class Meta:
        ordering = ["-created_at"]

    def is_expired(self):
        return timezone.now() > self.created_at + timedelta(minutes=5)

    @staticmethod
    def generate_otp():
        return str(random.randint(100000, 999999))

    def __str__(self):
        return f"{self.whatsapp_number} - {self.otp_code}"

class FertilizerType(models.Model):
    name = models.CharField(max_length=150, unique=True)

    class Meta:
        ordering = ["name"]

    def __str__(self):
        return self.name


class LicenceEntry(models.Model):
    licence = models.ForeignKey(Licence, on_delete=models.CASCADE, related_name="entries")
    source_type = models.CharField(max_length=200, blank=True, null=True)
    company_name = models.CharField(max_length=200)
    fertilizer_type = models.ManyToManyField(
        FertilizerType, blank=True, related_name="licence_entries"
    )
    valid_upto = models.DateField()

    class Meta:
        ordering = ["id"]

    def __str__(self):
        return f"{self.company_name} - {self.licence.licence_number}"