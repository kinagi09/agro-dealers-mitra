import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:license_tracker_app/screens/login_screen.dart';
import 'package:license_tracker_app/theme/app_theme.dart';

void main() {
  testWidgets('Login screen shows the WhatsApp number field', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(theme: AppTheme.theme, home: const LoginScreen()),
    );

    // Verify the login screen's WhatsApp Number field is present.
    expect(find.text('WhatsApp Number'), findsOneWidget);
  });
}
