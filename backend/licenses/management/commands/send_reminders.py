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

            is_expiring_today = reminder.days_before_expiry == 0

            if reminder.entry:
                entry = reminder.entry
                if is_expiring_today:
                    message = (
                        f"Reminder: {entry.company_name} on your licence "
                        f"{licence.licence_number} ({licence.licence_type.name}) "
                        f"is valid only through today ({entry.valid_upto})."
                    )
                else:
                    message = (
                        f"Reminder: {entry.company_name} on your licence "
                        f"{licence.licence_number} ({licence.licence_type.name}) "
                        f"is valid upto {entry.valid_upto}. "
                        f"({reminder.days_before_expiry} days remaining)"
                    )
            else:
                if is_expiring_today:
                    message = (
                        f"Reminder: Your licence {licence.licence_number} "
                        f"({licence.licence_type.name}) expires today "
                        f"({licence.expiry_date})."
                    )
                else:
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