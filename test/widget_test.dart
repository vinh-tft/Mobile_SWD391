// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:greenloop/main.dart';

void main() {
  testWidgets('Green Loop app smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const GreenLoopApp());

    // Verify that our app title is displayed.
    expect(find.text('Green Loop'), findsOneWidget);
    
    // Verify that the main heading is displayed.
    expect(find.text('Circular Fashion for a Greener Future'), findsOneWidget);
    
    // Verify that the tagline is displayed.
    expect(find.text('Sustainable Fashion Platform'), findsOneWidget);
    
    // Verify that navigation items are present.
    expect(find.text('Features'), findsOneWidget);
    expect(find.text('About'), findsOneWidget);
    expect(find.text('Contact'), findsOneWidget);
  });
}
