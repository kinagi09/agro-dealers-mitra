import 'dart:async';
import 'package:flutter/material.dart';

/// "Resend OTP" link with a cooldown, shown under the OTP field once an
/// OTP has already been sent once. Disabled (showing a countdown) for
/// [cooldownSeconds] after each send/resend to discourage hammering the
/// OTP endpoint, then becomes tappable again.
class ResendOtpButton extends StatefulWidget {
  final Future<void> Function() onResend;
  final int cooldownSeconds;

  const ResendOtpButton({
    super.key,
    required this.onResend,
    this.cooldownSeconds = 30,
  });

  @override
  State<ResendOtpButton> createState() => _ResendOtpButtonState();
}

class _ResendOtpButtonState extends State<ResendOtpButton> {
  Timer? _timer;
  int _secondsLeft = 0;

  @override
  void initState() {
    super.initState();
    _startCooldown();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _startCooldown() {
    _timer?.cancel();
    setState(() => _secondsLeft = widget.cooldownSeconds);
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      if (_secondsLeft <= 1) {
        timer.cancel();
        setState(() => _secondsLeft = 0);
      } else {
        setState(() => _secondsLeft -= 1);
      }
    });
  }

  Future<void> _handleResend() async {
    await widget.onResend();
    // Restart the cooldown regardless of outcome, so a failed attempt
    // can't be used to hammer the endpoint either.
    if (mounted) _startCooldown();
  }

  @override
  Widget build(BuildContext context) {
    final canResend = _secondsLeft == 0;
    return Center(
      child: TextButton(
        onPressed: canResend ? _handleResend : null,
        child: Text(
          canResend ? 'Resend OTP' : 'Resend OTP in ${_secondsLeft}s',
        ),
      ),
    );
  }
}
