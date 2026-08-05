import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:license_tracker_app/main.dart';

void main() {
  testWidgets('App loads the login screen', (WidgetTester tester) async {
    await tester.pumpWidget(const LicenseTrackerApp());

    // Verify the login screen's WhatsApp Number field is present.
    expect(find.text('WhatsApp Number'), findsOneWidget);
  });
}