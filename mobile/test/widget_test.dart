// Widget test file for National Medical Record System
// This is a placeholder test that ensures the app builds correctly.

import 'package:flutter_test/flutter_test.dart';

import 'package:mobileprojects/main.dart';

void main() {
  testWidgets('Medical App renders correctly', (WidgetTester tester) async {
    // Build the MedicalApp and trigger a frame.
    await tester.pumpWidget(MedicalApp());

    // Verify that the app renders with the correct title
    expect(find.text('National Medical Record'), findsOneWidget);
  });
}
