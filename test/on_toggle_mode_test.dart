// ignore_for_file: unnecessary_underscores

import 'dart:async';

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

  testWidgets(
    'failed onChange rolls back only its own ids after a concurrent success',
    (tester) async {
      final errors = <FlutterErrorDetails>[];
      final previous = FlutterError.onError;
      FlutterError.onError = errors.add;
      addTearDown(() => FlutterError.onError = previous);

      final failTwo = Completer<void>();
      final okThree = Completer<void>();
      var addedOnClose = <int>{};

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SearchAnchorPicker<int>(
              config: PickerConfig(
                loadItems: (_) async => [1, 2, 3],
                idOf: (item) => item,
                labelOf: (item) => '$item',
                searchTermsOf: (_) => const [],
              ),
              initialSelectedIds: const [1],
              onChange: (delta) {
                if (delta.added.contains(2)) return failTwo.future;
                if (delta.added.contains(3)) return okThree.future;
              },
              onClose: (result) {
                addedOnClose = result.added;
              },
              triggerBuilder: (_, open, __) =>
                  ElevatedButton(onPressed: open, child: const Text('open')),
            ),
          ),
        ),
      );
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('2'));
      await tester.pump();
      await tester.tap(find.text('3'));
      await tester.pump();
      okThree.complete();
      await tester.pump();
      failTwo.completeError(StateError('save failed'), StackTrace.current);
      await tester.pumpAndSettle();

      CheckboxListTile tileFor(String label) {
        return tester.widget<CheckboxListTile>(
          find.ancestor(
            of: find.text(label),
            matching: find.byType(CheckboxListTile),
          ),
        );
      }

      expect(tileFor('1').value, isTrue);
      expect(tileFor('2').value, isFalse);
      expect(tileFor('3').value, isTrue);
      expect(errors, hasLength(1));

      await tester.tap(find.byTooltip('Back'));
      await tester.pumpAndSettle();
      expect(addedOnClose, {3});
    },
  );

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
