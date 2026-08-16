import 'package:flutter/material.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';
import '../services/api_service.dart';
import '../widgets/app_logo.dart';
import 'home_screen.dart';
import 'login_screen.dart';

/// Shown after registration/login when the dealer has no active
/// subscription. Blocks access to the rest of the app - there is no free
/// trial, payment is required before Home is reachable.
class PaymentScreen extends StatefulWidget {
  const PaymentScreen({super.key});

  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  final ApiService _apiService = ApiService();
  late final Razorpay _razorpay;

  bool _isLoading = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _razorpay = Razorpay();
    _razorpay.on(Razorpay.EVENT_PAYMENT_SUCCESS, _onPaymentSuccess);
    _razorpay.on(Razorpay.EVENT_PAYMENT_ERROR, _onPaymentError);
  }

  @override
  void dispose() {
    _razorpay.clear();
    super.dispose();
  }

  Future<void> _startCheckout() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      final subscription = await _apiService.createSubscription();
      _razorpay.open({
        'key': subscription['key_id'],
        'subscription_id': subscription['subscription_id'],
        'name': 'Agro Dealers Mitra',
        'description': 'Yearly Subscription',
        'theme': {'color': '#216E39'},
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Could not start payment. Please try again.';
        _isLoading = false;
      });
    }
  }

  Future<void> _onPaymentSuccess(PaymentSuccessResponse response) async {
    final subscriptionId = response.data?['razorpay_subscription_id'];
    if (response.paymentId == null ||
        subscriptionId == null ||
        response.signature == null) {
      setState(() {
        _errorMessage = 'Payment response was incomplete. Please try again.';
        _isLoading = false;
      });
      return;
    }
    try {
      await _apiService.verifySubscription(
        razorpayPaymentId: response.paymentId!,
        razorpaySubscriptionId: subscriptionId,
        razorpaySignature: response.signature!,
      );
      if (!mounted) return;
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const HomeScreen()),
        (route) => false,
      );
    } catch (e) {
      setState(() {
        _errorMessage =
            'Payment succeeded but could not be verified. Please contact support.';
        _isLoading = false;
      });
    }
  }

  void _onPaymentError(PaymentFailureResponse response) {
    setState(() {
      _isLoading = false;
      _errorMessage = response.code == Razorpay.PAYMENT_CANCELLED
          ? 'Payment cancelled.'
          : 'Payment failed. Please try again.';
    });
  }

  Future<void> _logout() async {
    await _apiService.logout();
    if (!mounted) return;
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Center(child: AppLogo(size: 72)),
              const SizedBox(height: 24),
              const Text(
                'Subscribe to continue',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              const Text(
                'Track your Fertilizer, Pesticide, and Seed licences and get renewal reminders.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.black54),
              ),
              const SizedBox(height: 24),
              const Text(
                '₹499 / year',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 24),
              if (_errorMessage != null) ...[
                Text(
                  _errorMessage!,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.red),
                ),
                const SizedBox(height: 16),
              ],
              ElevatedButton(
                onPressed: _isLoading ? null : _startCheckout,
                child: _isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Subscribe Now'),
              ),
              const SizedBox(height: 12),
              TextButton(
                onPressed: _isLoading ? null : _logout,
                child: const Text('Logout'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
