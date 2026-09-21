// ignore_for_file: avoid_relative_lib_imports

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:search_anchor_picker/search_anchor_picker.dart';

import '../example/search_anchor_picker_example/lib/main.dart'; // for DemoItem

void main() {
  testWidgets('Generic Selection: String IDs', (tester) async {
    final items = <DemoItem>[
      const DemoItem(id: 1, label: 'Item 1', group: 'A'),
      const DemoItem(id: 2, label: 'Item 2', group: 'A'),
      const DemoItem(id: 3, label: 'Item 3', group: 'A'),
    ];

    final selected = <String>{'2'};
    var finishCount = 0;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: GenericSearchAnchorPicker<DemoItem, String>(
              initialSelectedIds: const <String>['2'],
              config: GenericPickerConfig<DemoItem, String>(
                loadItems: (context, query) async => items,
                idOf: (item) => item.id.toString(), // ID is String "1", "2"...
                labelOf: (item) => item.label,
                searchTermsOf: (item) => [item.label],
              ),
              onClose: (result) {
                finishCount++;
                selected
                  ..addAll(result.added)
                  ..removeAll(result.removed);
              },
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.byType(IconButton));
    await tester.pumpAndSettle();

    // Verify "Item 2" is selected (checkbox checked)
    final cb2 = tester.widget<CheckboxListTile>(
      find.ancestor(
        of: find.text('Item 2'),
        matching: find.byType(CheckboxListTile),
      ),
    );
    expect(cb2.value, isTrue);

    // Select "Item 1"
    await tester.tap(find.text('Item 1'));
    await tester.pump();

    // Verify selection updated
    final cb1 = tester.widget<CheckboxListTile>(
      find.ancestor(
        of: find.text('Item 1'),
        matching: find.byType(CheckboxListTile),
      ),
    );
    expect(cb1.value, isTrue);

    // Close
    await tester.tap(find.byTooltip('Back'));
    await tester.pumpAndSettle();

    expect(finishCount, 1);
    expect(selected, <String>{'2', '1'});
  });

  testWidgets('Generic Selection: Record IDs (int, int)', (tester) async {
    final items = <DemoItem>[
      const DemoItem(id: 1, label: 'Item 1', group: 'A'),
      const DemoItem(id: 2, label: 'Item 2', group: 'A'),
      const DemoItem(id: 3, label: 'Item 3', group: 'A'),
    ];

    final selected = <(int, int)>{(1, 100), (3, 300)};
    var finishCount = 0;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: GenericSearchAnchorPicker<DemoItem, (int, int)>(
              initialSelectedIds: const <(int, int)>[(1, 100), (3, 300)],
              config: GenericPickerConfig<DemoItem, (int, int)>(
                loadItems: (context, query) async => items,
                // ID is a tuple (id, id*100)
                idOf: (item) => (item.id, item.id * 100),
                labelOf: (item) => item.label,
                searchTermsOf: (item) => [item.label],
              ),
              onClose: (result) {
                finishCount++;
                selected
                  ..addAll(result.added)
                  ..removeAll(result.removed);
              },
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.byType(IconButton));
    await tester.pumpAndSettle();

    // Verify Item 1 ((1,100)) and Item 3 ((3,300)) are checked
    final cb1 = tester.widget<CheckboxListTile>(
      find.ancestor(
        of: find.text('Item 1'),
        matching: find.byType(CheckboxListTile),
      ),
    );
    expect(cb1.value, isTrue);

    final cb3 = tester.widget<CheckboxListTile>(
      find.ancestor(
        of: find.text('Item 3'),
        matching: find.byType(CheckboxListTile),
      ),
    );
    expect(cb3.value, isTrue);

    // Unselect Item 1
    await tester.tap(find.text('Item 1'));
    await tester.pump();

    // Select Item 2 ((2,200)) -> ID = (2, 200)
    await tester.tap(find.text('Item 2'));
    await tester.pump();

    // Close
    await tester.tap(find.byTooltip('Back'));
    await tester.pumpAndSettle();

    expect(finishCount, 1);
    expect(selected, <(int, int)>{(3, 300), (2, 200)});
  });
}
