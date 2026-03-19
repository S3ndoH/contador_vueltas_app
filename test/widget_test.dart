import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:contador_vueltas_app/main.dart';

void main() {
  testWidgets('App launches and shows splash screen test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    // Note: We don't initialize Supabase in this simple widget test.
    // The app should initially display the DeviceDetectionSplash.
    await tester.pumpWidget(const MyApp());

    // Verify that the splash screen (DeviceDetectionSplash) is showing.
    // It contains a CircularProgressIndicator.
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  });
}
