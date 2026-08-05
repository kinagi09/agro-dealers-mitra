from django.core.management.base import BaseCommand
from django.utils import timezone
from licenses.models import ReminderSchedule, NotificationLog


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

            message = (
                f"Reminder: Your licence {licence.licence_number} "
                f"({licence.licence_type.name}) expires on {licence.expiry_date}. "
                f"({reminder.days_before_expiry} days remaining)"
            )

            # STUB: real push/WhatsApp sending goes here later.
            self.stdout.write(f"[STUB SEND] To {dealer.shop_name}: {message}")

            NotificationLog.objects.create(
                dealer=dealer,
                licence=licence,
                channel="WHATSAPP",
                status="STUBBED",
                message_content=message,
            )

            reminder.is_sent = True
            reminder.save()

        self.stdout.write(self.style.SUCCESS("Reminder scan complete."))