import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:pinput/pinput.dart';
import '../theme/app_theme.dart';

/// A 6-box OTP entry field with paste and platform autofill support.
///
/// Autofill only actually pops a suggestion when the code arrives by SMS -
/// this app's OTP is delivered over WhatsApp, so on-device SMS autofill
/// won't trigger for it today. The `autofillHints` wiring here is kept so
/// this starts working automatically if an SMS delivery path is ever
/// added, and pasting a copied code always works regardless.
class OtpInput extends StatelessWidget {
  final TextEditingController controller;
  final FocusNode? focusNode;
  final ValueChanged<String>? onCompleted;

  const OtpInput({
    super.key,
    required this.controller,
    this.focusNode,
    this.onCompleted,
  });

  @override
  Widget build(BuildContext context) {
    final defaultPinTheme = PinTheme(
      width: 48,
      height: 52,
      textStyle: const TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.bold,
        color: AppColors.black,
      ),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.greyBorder),
      ),
    );

    return Pinput(
      length: 6,
      controller: controller,
      focusNode: focusNode,
      defaultPinTheme: defaultPinTheme,
      focusedPinTheme: defaultPinTheme.copyWith(
        decoration: defaultPinTheme.decoration!.copyWith(
          border: Border.all(color: AppColors.green, width: 2),
        ),
      ),
      submittedPinTheme: defaultPinTheme.copyWith(
        decoration: defaultPinTheme.decoration!.copyWith(
          color: AppColors.green.withValues(alpha: 0.08),
          border: Border.all(color: AppColors.green),
        ),
      ),
      keyboardType: TextInputType.number,
      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
      autofillHints: const [AutofillHints.oneTimeCode],
      onCompleted: onCompleted,
    );
  }
}
