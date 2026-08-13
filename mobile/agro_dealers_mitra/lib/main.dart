import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'navigation.dart';
import 'screens/auth_gate.dart';
import 'services/fcm_service.dart';
import 'theme/app_theme.dart';
import 'widgets/keyboard_dismiss_unfocus.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
  runApp(const AgroDealersMitraApp());
  FcmService().listenForNotificationTaps();
}

class AgroDealersMitraApp extends StatelessWidget {
  const AgroDealersMitraApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: navigatorKey,
      title: 'Agro Dealers Mitra',
      theme: AppTheme.theme,
      home: const AuthGate(),
      debugShowCheckedModeBanner: false,
      builder: (context, child) =>
          KeyboardDismissUnfocus(child: child ?? const SizedBox.shrink()),
    );
  }
}
