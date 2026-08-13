from django.core.management.base import BaseCommand
from django.utils import timezone
from licenses.models import ReminderSchedule, NotificationLog
from licenses.push import send_push

ENTRY_LABELS = {
    "Fertilizer": "O-form Entry",
    "Pesticide": "PC Entry",
}


def _display_date(date):
    return date.strftime("%d-%m-%Y")


class Command(BaseCommand):
    help = "Scans for due, unsent reminders and sends notifications (stubbed for now)"

    def handle(self, *args, **kwargs):
        today = timezone.now().date()
        due_reminders = ReminderSchedule.objects.filter(
            is_sent=False, scheduled_date__lte=today
        )

        self.stdout.write(f"Found {due_reminders.count()} due reminder(s).")

        for reminder in due_reminders:
            dealer = reminder.licence.dealer
            licence = reminder.licence
            category_name = licence.licence_type.category.name

            is_expiry_day = reminder.days_before_expiry == 0

            subject = f"Your {category_name} ({licence.licence_type.name}), Licence {licence.licence_number}"
            if reminder.entry:
                entry_label = ENTRY_LABELS.get(category_name, "Entry")
                subject += f" - {entry_label} ({reminder.entry.company_name})"
                expiry_date = reminder.entry.valid_upto
            else:
                expiry_date = licence.expiry_date

            if is_expiry_day:
                status_phrase = f"has expired today {_display_date(expiry_date)}."
            else:
                status_phrase = (
                    f"will expire on {_display_date(expiry_date)}. "
                    f"({reminder.days_before_expiry} days remaining)"
                )

            message = f"Hi, {dealer.shop_name}, Reminder: {subject} {status_phrase}"

            # STUB: real WhatsApp sending goes here later.
            self.stdout.write(f"[STUB SEND] To {dealer.shop_name}: {message}")

            NotificationLog.objects.create(
                dealer=dealer,
                licence=licence,
                channel="WHATSAPP",
                status="STUBBED",
                message_content=message,
                is_expiry_day=is_expiry_day,
            )

            preference = getattr(dealer, "notification_preference", None)
            if preference and preference.push_enabled and preference.fcm_token:
                success, error = send_push(
                    preference.fcm_token,
                    title="Agro Dealers Mitra",
                    body=message,
                )
                NotificationLog.objects.create(
                    dealer=dealer,
                    licence=licence,
                    channel="PUSH",
                    status="SENT" if success else "FAILED",
                    message_content=message,
                    is_expiry_day=is_expiry_day,
                    error_message=error,
                )
                if not success:
                    self.stdout.write(
                        self.style.WARNING(f"Push failed for {dealer.shop_name}: {error}")
                    )

            reminder.is_sent = True
            reminder.save()

        self.stdout.write(self.style.SUCCESS("Reminder scan complete."))
