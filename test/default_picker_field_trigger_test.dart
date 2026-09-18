import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:search_anchor_picker/search_anchor_picker.dart';

void main() {
  testWidgets('multi-select field shows Add and chips', (tester) async {
    var opened = 0;
    final deleted = <int>[];

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: DefaultPickerFieldTrigger<int>(
            selectedIds: const [1, 2],
            labelOf: (id) => id == 1 ? 'Ada' : 'Alan',
            onOpen: () => opened++,
            onDeleted: deleted.add,
          ),
        ),
      ),
    );

    expect(find.text('Add'), findsOneWidget);
    expect(find.text('Change'), findsNothing);
    expect(find.widgetWithText(InputChip, 'Ada'), findsOneWidget);
    expect(find.widgetWithText(InputChip, 'Alan'), findsOneWidget);

    await tester.tap(find.text('Add'));
    expect(opened, 1);
  });

  testWidgets('single-select field shows Change', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: DefaultPickerFieldTrigger<int>(
            selectedIds: [4],
            labelOf: _labelOf,
            onOpen: _noop,
            selectionMode: SelectionMode.single,
          ),
        ),
      ),
    );

    expect(find.text('Change'), findsOneWidget);
    expect(find.text('Add'), findsNothing);
  });

  testWidgets('tapping empty field area opens the picker', (tester) async {
    var opened = 0;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 400,
            child: DefaultPickerFieldTrigger<int>(
              onOpen: () => opened++,
            ),
          ),
        ),
      ),
    );

    final field = tester.getRect(find.byType(InputDecorator));
    await tester.tapAt(Offset(field.right - 12, field.center.dy));
    expect(opened, 1);
  });

  testWidgets('chip delete removes without opening', (tester) async {
    var opened = 0;
    final deleted = <int>[];

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: DefaultPickerFieldTrigger<int>(
            selectedIds: const [1],
            labelOf: (_) => 'Ada',
            onOpen: () => opened++,
            onDeleted: deleted.add,
          ),
        ),
      ),
    );

    await tester.tap(find.byIcon(Icons.clear));
    expect(deleted, [1]);
    expect(opened, 0);
  });

  testWidgets('showChips: false hides selected chips', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: DefaultPickerFieldTrigger<int>(
            selectedIds: [1],
            labelOf: _labelOf,
            onOpen: _noop,
            showChips: false,
          ),
        ),
      ),
    );

    expect(find.byType(InputChip), findsNothing);
    expect(find.text('Ada'), findsNothing);
    expect(find.text('Add'), findsOneWidget);
  });

  testWidgets('field trigger opens SearchAnchorPicker', (tester) async {
    final selected = <int>{};

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SearchAnchorPicker<String>(
            config: PickerConfig<String>(
              loadItems: (_) async => const ['A', 'B'],
              idOf: (item) => item.hashCode,
              labelOf: (item) => item,
              searchTermsOf: (item) => [item],
            ),
            initialSelectedIds: const [],
            isFullScreen: false,
            onClose: (_) {},
            triggerBuilder: (context, open, _) =>
                DefaultPickerFieldTrigger<int>(
                  selectedIds: selected,
                  onOpen: open,
                  onDeleted: selected.remove,
                ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Add'));
    await tester.pumpAndSettle();
    expect(find.text('A'), findsOneWidget);
    expect(find.text('B'), findsOneWidget);
  });
}

void _noop() {}

String _labelOf(int id) => id == 1 ? 'Ada' : '#$id';
