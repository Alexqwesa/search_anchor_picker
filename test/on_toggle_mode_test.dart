// ignore_for_file: unnecessary_underscores

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:search_anchor_picker/search_anchor_picker.dart';

void main() {
  testWidgets('an unselectable row is disabled and ignores taps', (
    tester,
  ) async {
    var addedIds = <int>[];
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SearchAnchorPicker<int>(
            config: PickerConfig(
              loadItems: (_) async => [1],
              idOf: (item) => item,
              labelOf: (item) => '$item',
              searchTermsOf: (_) => const [],
              relatedListItemStatusOf: (_) =>
                  const PickerRelatedListItemStatus(selectable: false),
            ),
            initialSelectedIds: const [],
            onClose: (result) {
              addedIds = result.added.toList();
            },
          ),
        ),
      ),
    );
    await tester.tap(find.byIcon(Icons.search));
    await tester.pumpAndSettle();
    expect(
      tester.widget<CheckboxListTile>(find.byType(CheckboxListTile)).onChanged,
      isNull,
    );
    await tester.tap(find.text('1'));
    await tester.pumpAndSettle();
    expect(
      tester.widget<CheckboxListTile>(find.byType(CheckboxListTile)).value,
      false,
    );
    await tester.tap(find.byTooltip('Back'));
    await tester.pumpAndSettle();
    expect(addedIds, isEmpty);
  });

  testWidgets('bulk commands skip unselectable rows', (tester) async {
    var addedIds = <int>[];
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SearchAnchorPicker<int>(
            config: PickerConfig(
              loadItems: (_) async => [1, 2],
              idOf: (item) => item,
              labelOf: (item) => '$item',
              searchTermsOf: (_) => const [],
              relatedListItemStatusOf: (item) =>
                  PickerRelatedListItemStatus(selectable: item != 1),
            ),
            initialSelectedIds: const [],
            headerBuilder: (context, controller, items) => [
              TextButton(
                onPressed: controller.selectLoaded,
                child: const Text('Select all'),
              ),
            ],
            onClose: (result) {
              addedIds = result.added.toList();
            },
          ),
        ),
      ),
    );
    await tester.tap(find.byIcon(Icons.search));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Select all'));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Back'));
    await tester.pumpAndSettle();
    expect(addedIds, [2]);
  });

  testWidgets('thrown onChange restores the checkbox', (tester) async {
    final errors = <FlutterErrorDetails>[];
    final previous = FlutterError.onError;
    FlutterError.onError = errors.add;
    addTearDown(() => FlutterError.onError = previous);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SearchAnchorPicker<int>(
            config: PickerConfig(
              loadItems: (_) async => [1],
              idOf: (item) => item,
              labelOf: (item) => '$item',
              searchTermsOf: (_) => const [],
            ),
            initialSelectedIds: const [],
            onChange: (_) {
              throw StateError('save failed');
            },
            triggerBuilder: (_, open, __) =>
                ElevatedButton(onPressed: open, child: const Text('open')),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('1'));
    await tester.pumpAndSettle();
    expect(
      tester.widget<CheckboxListTile>(find.byType(CheckboxListTile)).value,
      false,
    );
    expect(errors, hasLength(1));
  });

  testWidgets('accepted change remains selected and is reported on close', (
    tester,
  ) async {
    var addedIds = <int>[];
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SearchAnchorPicker<int>(
            config: PickerConfig(
              loadItems: (_) async => [1],
              idOf: (item) => item,
              labelOf: (item) => '$item',
              searchTermsOf: (_) => const [],
            ),
            initialSelectedIds: const [],
            onClose: (result) {
              addedIds = result.added.toList();
            },
          ),
        ),
      ),
    );
    await tester.tap(find.byIcon(Icons.search));
    await tester.pumpAndSettle();
    await tester.tap(find.text('1'));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Back'));
    await tester.pumpAndSettle();
    expect(addedIds, [1]);
  });
}
