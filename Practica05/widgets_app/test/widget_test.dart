// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:widgets_app/main.dart';

void main() {
  testWidgets('Home opens the Riverpod counter and increments it', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const ProviderScope(child: MainApp()));
    await tester.pumpAndSettle();

    expect(find.text('Flutter + Material 3'), findsOneWidget);
    await tester.tap(find.text('Riverpod Counter'));
    await tester.pumpAndSettle();
    expect(find.text('Valor: 5'), findsOneWidget);

    // Tap the '+' icon and trigger a frame.
    await tester.tap(find.byIcon(Icons.add));
    await tester.pump();

    // Verify that our counter has incremented.
    expect(find.text('Valor: 5'), findsNothing);
    expect(find.text('Valor: 6'), findsOneWidget);
  });
}
