import 'package:flutter/material.dart';

/// The brand leaf mark (green on transparent).
class AppLogo extends StatelessWidget {
  final double size;

  const AppLogo({super.key, this.size = 64});

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      'assets/icon/app_logo.png',
      width: size,
      height: size,
      fit: BoxFit.contain,
    );
  }
}
