import firebase_admin
from firebase_admin import credentials, messaging
from django.conf import settings

_firebase_app = None


def _get_app():
    global _firebase_app
    if _firebase_app is None:
        cred = credentials.Certificate(str(settings.FIREBASE_CREDENTIALS_PATH))
        _firebase_app = firebase_admin.initialize_app(cred)
    return _firebase_app


def send_push(fcm_token, title, body):
    """Sends a push notification via FCM. Returns (success, error_message)."""
    _get_app()
    message = messaging.Message(
        notification=messaging.Notification(title=title, body=body),
        token=fcm_token,
    )
    try:
        messaging.send(message)
        return True, None
    except Exception as e:
        return False, str(e)
