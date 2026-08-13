from django.db.models.signals import post_save
from django.dispatch import receiver
from datetime import timedelta
from .models import Licence, LicenceEntry, ReminderSchedule

REMINDER_THRESHOLDS = [30, 15, 7, 0]


@receiver(post_save, sender=Licence)
def create_or_update_reminders(sender, instance, created, **kwargs):
    # Pesticide licences don't collect a top-level expiry date - their
    # reminders come from each LicenceEntry.valid_upto instead, via
    # create_or_update_entry_reminders below.
    if instance.expiry_date is None:
        return

    for days in REMINDER_THRESHOLDS:
        scheduled_date = instance.expiry_date - timedelta(days=days)

        reminder, was_created = ReminderSchedule.objects.get_or_create(
            licence=instance,
            entry=None,
            days_before_expiry=days,
            defaults={"scheduled_date": scheduled_date, "is_sent": False},
        )

        # If the licence's expiry_date changed (e.g. renewed), update the
        # existing reminder's scheduled_date and reset it to unsent.
        if not was_created and reminder.scheduled_date != scheduled_date:
            reminder.scheduled_date = scheduled_date
            reminder.is_sent = False
            reminder.save()


@receiver(post_save, sender=LicenceEntry)
def create_or_update_entry_reminders(sender, instance, created, **kwargs):
    # Entries only exist for Fertilizer (O-form entries) and Pesticide (PC
    # entries) - Seed licences have no entry table and rely solely on the
    # licence-level signal above.
    if instance.licence.licence_type.category.name not in ("Fertilizer", "Pesticide"):
        return

    for days in REMINDER_THRESHOLDS:
        scheduled_date = instance.valid_upto - timedelta(days=days)

        reminder, was_created = ReminderSchedule.objects.get_or_create(
            entry=instance,
            days_before_expiry=days,
            defaults={
                "licence": instance.licence,
                "scheduled_date": scheduled_date,
                "is_sent": False,
            },
        )

        if not was_created and reminder.scheduled_date != scheduled_date:
            reminder.scheduled_date = scheduled_date
            reminder.is_sent = False
            reminder.save()