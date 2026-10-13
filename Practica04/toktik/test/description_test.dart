import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:toktik_app/presentation/widgets/video/expandable_caption.dart';

void main() {
  testWidgets('Long caption expands in bounded scroll panel and collapses', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 240,
            child: ExpandableCaption(
              text: List.filled(40, 'Una historia original.').join(' '),
              maxHeight: 120,
            ),
          ),
        ),
      ),
    );
    expect(find.text('Ver más'), findsOneWidget);
    expect(find.byType(SingleChildScrollView), findsNothing);
    await tester.tap(find.text('Ver más'));
    await tester.pump();
    expect(find.text('Ver menos'), findsOneWidget);
    expect(
      tester.getSize(find.byKey(const ValueKey('expanded-description'))).height,
      lessThanOrEqualTo(120),
    );
    await tester.drag(
      find.byType(SingleChildScrollView),
      const Offset(0, -150),
    );
    await tester.pump();
    await tester.tap(find.text('Ver menos'));
    await tester.pump();
    expect(find.byType(SingleChildScrollView), findsNothing);
    expect(tester.takeException(), isNull);
  });
  testWidgets('Short caption has no redundant expansion control', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(body: ExpandableCaption(text: 'Hola', maxHeight: 100)),
      ),
    );
    expect(find.text('Ver más'), findsNothing);
  });
}
