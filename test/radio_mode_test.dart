import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:search_anchor_picker/search_anchor_picker.dart';

void main() {
  testWidgets('SelectionMode.singleOptional allows deselection', (
    tester,
  ) async {
    final config = PickerConfig<int>(
      loadItems: (_) async => [1, 2],
      idOf: (i) => i,
      labelOf: (i) => 'Item $i',
      searchTermsOf: (_) => [],
    );

    // Track selection changes
    var currentSelection = <int>[];

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: StatefulBuilder(
            builder: (context, setState) {
              return SearchAnchorPicker<int>(
                config: config,
                initialSelectedIds: currentSelection,
                selectionMode: SelectionMode.singleOptional,
                onFinish: (result) {
                  setState(() {
                    currentSelection = [
                      ...currentSelection.where(
                        (id) => !result.removed.contains(id),
                      ),
                      ...result.added,
                    ];
                  });
                },
              );
            },
          ),
        ),
      ),
    );

    // 1. Open Picker
    await tester.tap(find.byIcon(Icons.search));
    await tester.pumpAndSettle();
    expect(find.text('Item 1'), findsOneWidget);

    // 2. Select Item 1
    await tester.tap(find.text('Item 1'));
    await tester.pumpAndSettle();

    // Verify it closed and selected Item 1
    expect(find.text('Item 1'), findsNothing); // Closed
    expect(currentSelection, [1]);

    // 3. Re-open Picker
    await tester.tap(find.byIcon(Icons.search));
    await tester.pumpAndSettle();

    // Verify Item 1 is checked (we trust state was passed).

    // 4. Tap Item 1 again (Deselect)
    await tester.tap(find.text('Item 1'));
    await tester.pumpAndSettle();

    // Verify it closed and selection is empty
    expect(find.text('Item 1'), findsNothing); // Closed
    expect(currentSelection, isEmpty);
  });

  testWidgets('SelectionMode.single enforces single selection (no deselect)', (
    tester,
  ) async {
    final config = PickerConfig<int>(
      loadItems: (_) async => [1, 2],
      idOf: (i) => i,
      labelOf: (i) => 'Item $i',
      searchTermsOf: (_) => [],
    );

    var currentSelection = <int>[];

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: StatefulBuilder(
            builder: (context, setState) {
              return SearchAnchorPicker<int>(
                config: config,
                initialSelectedIds: currentSelection,
                selectionMode: SelectionMode.single,
                onFinish: (result) {
                  setState(() {
                    currentSelection = [
                      ...currentSelection.where(
                        (id) => !result.removed.contains(id),
                      ),
                      ...result.added,
                    ];
                  });
                },
              );
            },
          ),
        ),
      ),
    );

    // 1. Select Item 1
    await tester.tap(find.byIcon(Icons.search));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Item 1'));
    await tester.pumpAndSettle();
    expect(currentSelection, [1]);

    // 2. Re-open and tap Item 1 again
    await tester.tap(find.byIcon(Icons.search));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Item 1'));
    await tester.pumpAndSettle();

    // Verify it did NOT close (single selection blocks unselect)
    // "Item 1" should still be visible because picker is open
    expect(find.text('Item 1'), findsOneWidget); // Still open

    // Close manually to finish
    await tester.tap(find.byTooltip('Back'));
    await tester.pumpAndSettle();
  });
}
