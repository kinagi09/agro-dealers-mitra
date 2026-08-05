from django.db.models.signals import post_save
from django.dispatch import receiver
from datetime import timedelta
from .models import Licence, ReminderSchedule

REMINDER_THRESHOLDS = [30, 15, 7]


@receiver(post_save, sender=Licence)
def create_or_update_reminders(sender, instance, created, **kwargs):
    for days in REMINDER_THRESHOLDS:
        scheduled_date = instance.expiry_date - timedelta(days=days)

        reminder, was_created = ReminderSchedule.objects.get_or_create(
            licence=instance,
            days_before_expiry=days,
            defaults={"scheduled_date": scheduled_date, "is_sent": False},
        )

        # If the licence's expiry_date changed (e.g. renewed), update the
        # existing reminder's scheduled_date and reset it to unsent.
        if not was_created and reminder.scheduled_date != scheduled_date:
            reminder.scheduled_date = scheduled_date
            reminder.is_sent = False
            reminder.save()