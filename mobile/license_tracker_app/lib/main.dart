import 'package:flutter/material.dart';
import 'navigation.dart';
import 'screens/login_screen.dart';

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
      theme: ThemeData(primarySwatch: Colors.green, useMaterial3: true),
      home: const LoginScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}