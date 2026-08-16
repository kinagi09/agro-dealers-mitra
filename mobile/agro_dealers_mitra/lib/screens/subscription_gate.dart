import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../widgets/app_logo.dart';
import 'home_screen.dart';
import 'payment_screen.dart';

/// Sits between login/register and the rest of the app - checks whether the
/// dealer has an active subscription and routes to Home or Payment
/// accordingly. Any check failure (e.g. network error) fails closed to the
/// payment screen rather than granting free access.
class SubscriptionGate extends StatefulWidget {
  const SubscriptionGate({super.key});

  @override
  State<SubscriptionGate> createState() => _SubscriptionGateState();
}

class _SubscriptionGateState extends State<SubscriptionGate> {
  final ApiService _apiService = ApiService();
  bool? _isActive;

  @override
  void initState() {
    super.initState();
    _checkStatus();
  }

  Future<void> _checkStatus() async {
    bool isActive;
    try {
      final result = await _apiService.getSubscriptionStatus();
      isActive = result['is_active'] == true;
    } catch (e) {
      isActive = false;
    }
    if (!mounted) return;
    setState(() => _isActive = isActive);
  }

  @override
  Widget build(BuildContext context) {
    if (_isActive == null) {
      return const Scaffold(body: Center(child: AppLogo(size: 72)));
    }
    return _isActive! ? const HomeScreen() : const PaymentScreen();
  }
}
