import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import '../navigation.dart';
import '../screens/notifications_screen.dart';
import 'api_service.dart';

/// Registered with FirebaseMessaging.onBackgroundMessage in main.dart. Must
/// stay a top-level/static function (Flutter runs it in a separate isolate).
/// No work needed inside it - FCM shows the system notification on its own
/// for messages that include a `notification` payload, even when the app is
/// backgrounded or fully closed.
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {}

/// Requests notification permission, grabs this device's FCM token, and
/// saves it on the dealer's NotificationPreference so the backend can target
/// this device when sending push reminders.
class FcmService {
  final ApiService _apiService = ApiService();

  Future<void> initAndRegister() async {
    final messaging = FirebaseMessaging.instance;
    await messaging.requestPermission();

    final token = await messaging.getToken();
    if (token != null) {
      await _registerToken(token);
    }
    messaging.onTokenRefresh.listen(_registerToken);
  }

  /// Opens the Notifications screen when the user actually taps a push -
  /// either from the tray while the app was backgrounded, or one that
  /// launched the app from fully closed. A push just sitting in the
  /// notification shade unopened, or arriving in the foreground, does NOT
  /// go through here, so it stays unread until the user opens the screen
  /// themselves (see NotificationsScreen, which marks-all-read on load).
  void listenForNotificationTaps() {
    FirebaseMessaging.onMessageOpenedApp.listen((_) => _openNotifications());
    FirebaseMessaging.instance.getInitialMessage().then((message) {
      if (message != null) _openNotifications();
    });
  }

  void _openNotifications() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      navigatorKey.currentState?.push(
        MaterialPageRoute(builder: (_) => const NotificationsScreen()),
      );
    });
  }

  Future<void> _registerToken(String token) async {
    try {
      final preference = await _apiService.getMyNotificationPreference();
      final preferenceId = preference['id'];
      if (preferenceId == null) return;
      await _apiService.updateFcmToken(id: preferenceId, fcmToken: token);
    } catch (e) {
      // Non-critical - push just won't reach this device until the next
      // successful registration attempt (e.g. next app open).
    }
  }
}
