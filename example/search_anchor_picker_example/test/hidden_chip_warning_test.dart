import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:search_anchor_picker_example/card_gallery/people.dart';
import 'package:search_anchor_picker_example/card_gallery/simple_card.dart';

Widget _hiddenCard() {
  return MaterialApp(
    home: Scaffold(
      body: SingleChildScrollView(
        child: SimpleCard(
          title: 'Hidden selected ID',
          persistLabel: 'onClose',
          difference: '',
          source: '',
          seed: const {1, 12},
          itemsLoader: (_, _) async => people.take(4).toList(),
          warnHiddenChip: true,
          visibleCatalogIds: {for (final person in people.take(4)) person.id},
        ),
      ),
    ),
  );
}

Finder _chipClear(String label) {
  return find.descendant(
    of: find.widgetWithText(InputChip, label),
    matching: find.byIcon(Icons.clear),
  );
}

void main() {
  testWidgets('hidden chip X asks before removing', (tester) async {
    await tester.pumpWidget(_hiddenCard());

    await tester.tap(_chipClear('Radia Perlman'));
    await tester.pumpAndSettle();

    expect(find.text('Hidden selection'), findsOneWidget);
    expect(find.widgetWithText(InputChip, 'Radia Perlman'), findsOneWidget);

    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
    expect(find.widgetWithText(InputChip, 'Radia Perlman'), findsOneWidget);

    await tester.tap(_chipClear('Radia Perlman'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Remove'));
    await tester.pumpAndSettle();
    expect(find.widgetWithText(InputChip, 'Radia Perlman'), findsNothing);
    expect(find.widgetWithText(InputChip, 'Ada Lovelace'), findsOneWidget);
  });

  testWidgets('visible chip X has no hidden warning', (tester) async {
    await tester.pumpWidget(_hiddenCard());

    await tester.tap(_chipClear('Ada Lovelace'));
    await tester.pumpAndSettle();

    expect(find.text('Hidden selection'), findsNothing);
    expect(find.widgetWithText(InputChip, 'Ada Lovelace'), findsNothing);
    expect(find.widgetWithText(InputChip, 'Radia Perlman'), findsOneWidget);
  });
}
