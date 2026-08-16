import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../widgets/app_logo.dart';
import 'login_screen.dart';
import 'subscription_gate.dart';

/// Decides whether to show the home screen or the login screen at startup,
/// based on whether a session was already saved on this device. Without
/// this check the app always opened on the login screen regardless of an
/// existing session, which looked like the app had logged the user out
/// every time it was closed and reopened (e.g. after pressing back).
class AuthGate extends StatefulWidget {
  const AuthGate({super.key});

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  final ApiService _apiService = ApiService();
  bool? _isLoggedIn;

  @override
  void initState() {
    super.initState();
    _checkSession();
  }

  Future<void> _checkSession() async {
    bool loggedIn;
    try {
      loggedIn = await _apiService.isLoggedIn();
    } catch (e) {
      // If the session check itself fails, fall back to the login screen
      // rather than leaving the user stuck on the loading state forever.
      loggedIn = false;
    }
    if (!mounted) return;
    setState(() => _isLoggedIn = loggedIn);
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoggedIn == null) {
      return const Scaffold(body: Center(child: AppLogo(size: 72)));
    }
    return _isLoggedIn! ? const SubscriptionGate() : const LoginScreen();
  }
}
