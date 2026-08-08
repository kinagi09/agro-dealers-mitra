import 'package:flutter/material.dart';
import 'navigation.dart';
import 'screens/auth_gate.dart';
import 'theme/app_theme.dart';
import 'widgets/keyboard_dismiss_unfocus.dart';

void main() {
  runApp(const LicenseTrackerApp());
}

class LicenseTrackerApp extends StatelessWidget {
  const LicenseTrackerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: navigatorKey,
      title: 'License Tracker',
      theme: AppTheme.theme,
      home: const AuthGate(),
      debugShowCheckedModeBanner: false,
      builder: (context, child) =>
          KeyboardDismissUnfocus(child: child ?? const SizedBox.shrink()),
    );
  }
}
