// ignore_for_file: unnecessary_underscores

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:search_anchor_picker/search_anchor_picker.dart';

void main() {
  testWidgets('optimistic gate updates checkbox before gate completes', (
    tester,
  ) async {
    final gate = Completer<bool>();

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SearchAnchorPicker<int>(
            config: PickerConfig(
              loadItems: (_) async => [1, 2],
              idOf: (i) => i,
              labelOf: (i) => '$i',
              searchTermsOf: (_) => [],
            ),
            initialSelectedIds: const [],
            canChangeSelection: (_) => gate.future,
            persistence: PickerPersistence.immediate(
              persist: _noopPersist,
              applyMode: PickerApplyMode.optimistic,
            ),
            triggerBuilder: (_, open, __) =>
                ElevatedButton(onPressed: open, child: const Text('open')),
          ),
        ),
      ),
    );

    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('1'));
    await tester.pump();

    final checkbox = tester.widget<CheckboxListTile>(
      find.byType(CheckboxListTile).first,
    );
    expect(checkbox.value, true);

    gate.complete(false);
    await tester.pumpAndSettle();

    final reverted = tester.widget<CheckboxListTile>(
      find.byType(CheckboxListTile).first,
    );
    expect(reverted.value, false);
  });

  testWidgets('pessimistic gate blocks checkbox until gate returns true', (
    tester,
  ) async {
    final gate = Completer<bool>();

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SearchAnchorPicker<int>(
            config: PickerConfig(
              loadItems: (_) async => [1, 2],
              idOf: (i) => i,
              labelOf: (i) => '$i',
              searchTermsOf: (_) => [],
            ),
            initialSelectedIds: const [],
            canChangeSelection: (_) => gate.future,
            triggerBuilder: (_, open, __) =>
                ElevatedButton(onPressed: open, child: const Text('open')),
          ),
        ),
      ),
    );

    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('1'));
    await tester.pump();

    var checkbox = tester.widget<CheckboxListTile>(
      find.byType(CheckboxListTile).first,
    );
    expect(checkbox.value, false);

    gate.complete(true);
    await tester.pumpAndSettle();

    checkbox = tester.widget<CheckboxListTile>(
      find.byType(CheckboxListTile).first,
    );
    expect(checkbox.value, true);
  });

  testWidgets('pessimistic rejection leaves selection and deltas unchanged', (
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
            canChangeSelection: (_) async => false,
            onFinish: (result) {
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
    expect(
      tester.widget<CheckboxListTile>(find.byType(CheckboxListTile)).value,
      false,
    );
    await tester.tap(find.byTooltip('Back'));
    await tester.pumpAndSettle();
    expect(addedIds, isEmpty);
  });

  testWidgets('optimistic success remains selected and reports delta', (
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
            canChangeSelection: (_) async => true,
            persistence: PickerPersistence.immediate(
              persist: _noopPersist,
              applyMode: PickerApplyMode.optimistic,
            ),
            onFinish: (result) {
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

Future<void> _noopPersist(PickerDelta<int> delta) async {}
