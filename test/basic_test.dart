import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:search_anchor_picker/search_anchor_picker.dart';

void main() {
  testWidgets('Basic SearchAnchorPicker renders', (tester) async {
    final config = PickerConfig<String>(
      loadItems: (_) async => ['A', 'B', 'C'],
      idOf: (s) => s.hashCode,
      labelOf: (s) => s,
      searchTermsOf: (s) => [s],
      title: 'Test',
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SearchAnchorPicker(
            config: config,
            initialSelectedIds: const [],
            onFinish: ({required added, required removed}) async {},
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    // Should find the trigger button
    expect(find.byType(IconButton), findsOneWidget);
  });

  testWidgets('Picker opens and shows items', (tester) async {
    final config = PickerConfig<String>(
      loadItems: (_) async => ['A', 'B', 'C'],
      idOf: (s) => s.hashCode,
      labelOf: (s) => s,
      searchTermsOf: (s) => [s],
      title: 'Test',
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SearchAnchorPicker(
            config: config,
            initialSelectedIds: const [],
            onFinish: ({required added, required removed}) async {},
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    // Tap to open
    await tester.tap(find.byType(IconButton));
    await tester.pumpAndSettle();

    // Should find the items
    expect(find.text('A'), findsOneWidget);
    expect(find.text('B'), findsOneWidget);
    expect(find.text('C'), findsOneWidget);
  });

  testWidgets('Picker selects item', (tester) async {
    var selectedIds = <int>[];

    final config = PickerConfig<String>(
      loadItems: (_) async => ['A', 'B', 'C'],
      idOf: (s) => s.hashCode,
      labelOf: (s) => s,
      searchTermsOf: (s) => [s],
      title: 'Test',
    );

    await tester.pumpWidget(
      MaterialApp(
        home: StatefulBuilder(
          builder: (context, setState) {
            return Scaffold(
              body: SearchAnchorPicker(
                config: config,
                initialSelectedIds: selectedIds,
                onFinish: ({required added, required removed}) async {
                  setState(() {
                    selectedIds = {
                      ...selectedIds,
                      ...added,
                    }.difference(removed.toSet()).toList();
                  });
                },
              ),
            );
          },
        ),
      ),
    );

    await tester.pumpAndSettle();

    // Open picker
    await tester.tap(find.byType(IconButton));
    await tester.pumpAndSettle();

    // Select item A
    await tester.tap(find.text('A'));
    await tester.pumpAndSettle();

    // Close picker by tapping back/close button
    final backButton = find.byTooltip('Back');
    if (backButton.evaluate().isNotEmpty) {
      await tester.tap(backButton);
      await tester.pumpAndSettle();
    }

    // Verify selection
    expect(selectedIds.length, 1);
    expect(selectedIds.first, 'A'.hashCode);
  });
}
