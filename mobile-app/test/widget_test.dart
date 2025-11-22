// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:upvista_mobile/app.dart';

void main() {
  testWidgets('App loads with splash screen', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(
      const ProviderScope(
        child: UpvistaApp(),
      ),
    );

    // Verify that the splash screen displays the app name
    expect(find.text('Upvista Community'), findsOneWidget);
    expect(find.text('Beautiful real-time social platform'), findsOneWidget);
    expect(find.byIcon(Icons.rocket_launch), findsOneWidget);
  });
}
