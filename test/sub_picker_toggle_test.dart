import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:search_anchor_picker/search_anchor_picker.dart';

class _Harness {
  final parent = ValueNotifier<Set<int>>({1, 9});
  final finishes = <(List<int>, List<int>)>[];
  late GenericPickerController<int, int> child;
  int notifications = 0;
  final saves = <PickerDelta<int>>[];

  Future<void> open(
    WidgetTester tester, {
    SelectionMode selectionMode = SelectionMode.multi,
    PickerUnselectPolicy policy = PickerUnselectPolicy.allow,
    SubPickerParentSelectionEffect effect =
        SubPickerParentSelectionEffect.mirror,
    Future<void> Function(PickerDelta<int> delta)? onChange,
    bool withClose = true,
  }) async {
    addTearDown(parent.dispose);
    parent.addListener(() => notifications++);
    final controller = GenericPickerController<int, int>(
      pendingN: parent,
      idOf: (item) => item,
      close: ([_]) {},
      selectionMode: SelectionMode.multi,
      getKey: (_) => GlobalKey(),
      refresh: () {},
      loadedIds: () => [1, 2],
      filteredIds: () => [1, 2],
      applyDelta: (_, _) =>
          throw StateError('Parent sync must not create a delta'),
    );
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SubPickerTile<int>(
            title: 'Child',
            config: PickerConfig<int>(
              loadItems: (_, _) async => [1, 2, 3],
              idOf: (item) => item,
              labelOf: (item) => 'Item $item',
              searchTermsOf: (item) => ['$item'],
              relatedListItemStatusOf: (_) =>
                  PickerRelatedListItemStatus(unselectPolicy: policy),
              unselectConfirmationBuilder: (_, _) async => false,
            ),
            initialSelectedIds: const [1],
            parentController: controller,
            parentSelectionEffect: effect,
            selectionMode: selectionMode,
            onChange: (delta) async {
              saves.add(delta);
              await onChange?.call(delta);
            },
            onClose: withClose
                ? (result) {
                    finishes.add((
                      result.added.toList(),
                      result.removed.toList(),
                    ));
                  }
                : null,
            headerBuilder: (_, controller, _) {
              child = controller;
              return const [];
            },
          ),
        ),
      ),
    );
    await tester.tap(find.text('Child'));
    await tester.pumpAndSettle();
  }

  Future<void> close(WidgetTester tester) async {
    await tester.tap(find.byTooltip('Back'));
    await tester.pumpAndSettle();
  }
}

void main() {
  testWidgets('failed onChange restores the checkbox', (tester) async {
    final errors = <FlutterErrorDetails>[];
    final previous = FlutterError.onError;
    FlutterError.onError = errors.add;
    addTearDown(() => FlutterError.onError = previous);
    final h = _Harness();
    var changes = 0;
    await h.open(
      tester,
      onChange: (delta) async {
        changes++;
        if (changes > 1) throw StateError('bulk failed');
      },
    );
    await tester.tap(find.text('Item 2'));
    await tester.pumpAndSettle();
    h.child.clearLoaded();
    await tester.pumpAndSettle();
    expect(h.child.pendingIds, {1, 2});
    expect(h.parent.value, {1, 2, 9});
    expect(h.notifications, 1);
    expect(errors, hasLength(1));
    await h.close(tester);
  });

  testWidgets('independent saves may complete out of order', (tester) async {
    final h = _Harness();
    final saves = {2: Completer<void>(), 3: Completer<void>()};
    await h.open(
      tester,
      onChange: (delta) => saves[delta.added.first]!.future,
    );
    await tester.tap(find.text('Item 2'));
    await tester.pump();
    await tester.tap(find.text('Item 3'));
    await tester.pump();
    expect(h.child.pendingIds, {1, 2, 3});
    expect(h.parent.value, {1, 9});
    saves[3]!.complete();
    await tester.pumpAndSettle();
    expect(h.parent.value, {1, 3, 9});
    saves[2]!.complete();
    await tester.pumpAndSettle();
    expect(h.parent.value, {1, 2, 3, 9});
    await h.close(tester);
    expect(h.finishes.single.$1, unorderedEquals([2, 3]));
    expect(h.finishes.single.$2, isEmpty);
  });

  testWidgets('late child onClose cannot change a closed or reopened parent', (
    tester,
  ) async {
    final save = Completer<void>();
    late GenericPickerController<int, int> parent;
    final config = PickerConfig<int>(
      loadItems: (_, _) async => [1],
      idOf: (item) => item,
      labelOf: (item) => 'Row $item',
      searchTermsOf: (_) => [],
    );
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SearchAnchorPicker<int>(
            config: config,
            initialSelectedIds: const [1],
            triggerChild: const Text('Parent'),
            headerBuilder: (_, controller, _) {
              parent = controller;
              return [
                SubPickerTile<int>(
                  title: 'Child',
                  config: config.copyWith(),
                  initialSelectedIds: const [1],
                  parentController: controller,
                  parentSelectionEffect:
                      SubPickerParentSelectionEffect.deselectRemoved,
                  onClose: (_) => save.future,
                ),
              ];
            },
          ),
        ),
      ),
    );
    await tester.tap(find.text('Parent'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Child'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Row 1').last);
    await tester.pumpAndSettle();
    expect(parent.pendingIds, isEmpty);
    await tester.tap(find.byTooltip('Back').last);
    await tester.pump();
    expect(find.text('Saving…'), findsOneWidget);
    parent.close();
    await tester.pumpAndSettle();
    await tester.tap(find.text('Parent'));
    await tester.pumpAndSettle();
    save.complete();
    await tester.pumpAndSettle();
    expect(parent.pendingIds, {1});
    expect(tester.takeException(), isNull);
  });

  testWidgets('syncs only after the save succeeds and never replays on close', (
    tester,
  ) async {
    final h = _Harness();
    final saved = Completer<void>();
    await h.open(tester, onChange: (_) => saved.future);
    await tester.tap(find.text('Item 2'));
    await tester.pump();
    expect(h.parent.value, {1, 9});
    expect(h.child.pendingIds, {1, 2});
    await tester.tap(find.text('Item 2'));
    await tester.pump();
    expect(h.saves, hasLength(1));
    saved.complete();
    await tester.pumpAndSettle();
    expect(h.parent.value, {1, 2, 9});
    expect(h.notifications, 1);
    await h.close(tester);
    expect(h.finishes.single.$1, unorderedEquals([2]));
    expect(h.finishes.single.$2, isEmpty);
    expect(h.notifications, 1);
  });

  testWidgets('a thrown save leaves no parent delta', (tester) async {
    final errors = <FlutterErrorDetails>[];
    final previous = FlutterError.onError;
    FlutterError.onError = errors.add;
    addTearDown(() => FlutterError.onError = previous);
    final h = _Harness();
    await h.open(
      tester,
      onChange: (_) async => throw StateError('save failed'),
    );
    await tester.tap(find.text('Item 1'));
    await tester.pumpAndSettle();
    expect(h.child.pendingIds, {1});
    expect(h.parent.value, {1, 9});
    await h.close(tester);
    expect(h.finishes.single.$1, isEmpty);
    expect(h.finishes.single.$2, isEmpty);
    expect(h.notifications, 0);
    expect(errors, hasLength(1));
  });

  testWidgets('defers close until the pending save settles', (tester) async {
    final h = _Harness();
    final saved = Completer<void>();
    await h.open(tester, onChange: (_) => saved.future);
    await tester.tap(find.text('Item 2'));
    await tester.pump();
    await h.close(tester);
    expect(h.finishes, isEmpty);
    expect(find.byType(SearchBar), findsOneWidget);
    saved.complete();
    await tester.pumpAndSettle();
    expect(find.byType(SearchBar), findsNothing);
    expect(h.parent.value, {1, 2, 9});
    expect(h.finishes.single.$1, unorderedEquals([2]));
    expect(h.finishes.single.$2, isEmpty);
  });

  testWidgets('ignores save completion after disposal', (tester) async {
    final h = _Harness();
    final saved = Completer<void>();
    await h.open(tester, onChange: (_) => saved.future);
    await tester.tap(find.text('Item 2'));
    await tester.pump();
    await tester.pumpWidget(const SizedBox());
    saved.complete();
    await tester.pumpAndSettle();
    expect(h.parent.value, {1, 9});
    expect(h.finishes, isEmpty);
    expect(tester.takeException(), isNull);
  });

  for (final policy in [
    PickerUnselectPolicy.blocked,
    PickerUnselectPolicy.confirm,
  ]) {
    testWidgets('$policy stops removal before onChange or parent sync', (
      tester,
    ) async {
      final h = _Harness();
      await h.open(tester, policy: policy);
      await tester.tap(find.text('Item 1'));
      await tester.pumpAndSettle();
      expect(h.saves, isEmpty);
      expect(h.parent.value, {1, 9});
      await h.close(tester);
      expect(h.finishes.single.$1, isEmpty);
      expect(h.finishes.single.$2, isEmpty);
    });
  }

  testWidgets('bulk reversal syncs parent when the child selection changes', (
    tester,
  ) async {
    final h = _Harness();
    final saved = Completer<void>();
    await h.open(
      tester,
      onChange: (delta) async {
        if (delta.removed.isNotEmpty && delta.added.isEmpty) {
          await saved.future;
        }
      },
    );
    await tester.tap(find.text('Item 2'));
    await tester.pumpAndSettle();
    expect(h.parent.value, {1, 2, 9});
    h.child.clearLoaded();
    await tester.pump();
    await tester.pump();
    expect(h.child.pendingIds, isEmpty);
    expect(h.parent.value, {1, 2, 9});
    saved.complete();
    await tester.pumpAndSettle();
    expect(h.parent.value, {9});
    await h.close(tester);
    expect(h.finishes.single.$1, isEmpty);
    expect(h.finishes.single.$2, unorderedEquals([1]));
    expect(h.saves, hasLength(2));
  });

  testWidgets('bulk selection after a saved removal is applied immediately', (
    tester,
  ) async {
    final h = _Harness();
    await h.open(tester);
    await tester.tap(find.text('Item 1'));
    await tester.pumpAndSettle();
    expect(h.parent.value, {9});
    h.child.selectLoaded();
    await tester.pumpAndSettle();
    await h.close(tester);
    expect(h.finishes.single.$1, unorderedEquals([2, 3]));
    expect(h.finishes.single.$2, isEmpty);
    expect(h.parent.value, {1, 2, 3, 9});
  });

  testWidgets('bulk commands also sync the parent', (tester) async {
    final h = _Harness();
    await h.open(tester, withClose: false);
    h.child.clearLoaded();
    await tester.pumpAndSettle();
    await h.close(tester);
    expect(h.parent.value, {9});
    expect(h.notifications, 1);
  });

  testWidgets('a bulk command reaches onChange as one delta', (tester) async {
    final h = _Harness();
    final deltas = <PickerDelta<int>>[];
    await h.open(
      tester,
      onChange: (delta) async => deltas.add(delta),
      withClose: false,
    );
    h.child.selectLoaded();
    await tester.pumpAndSettle();
    expect(deltas, hasLength(1));
    expect(deltas.single.added, unorderedEquals([2, 3]));
    expect(deltas.single.removed, isEmpty);
    await h.close(tester);
  });

  for (final (effect, expected) in [
    (SubPickerParentSelectionEffect.none, {1, 9}),
    (SubPickerParentSelectionEffect.selectAdded, {1, 2, 9}),
    (SubPickerParentSelectionEffect.deselectRemoved, {9}),
    (SubPickerParentSelectionEffect.mirror, {2, 9}),
  ]) {
    testWidgets('toggle-time $effect respects the selected direction', (
      tester,
    ) async {
      final h = _Harness();
      await h.open(tester, effect: effect);
      await tester.tap(find.text('Item 2'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Item 1'));
      await tester.pumpAndSettle();
      expect(h.parent.value, expected);
      final notifications = h.notifications;
      await h.close(tester);
      expect(h.notifications, notifications);
      expect(h.finishes.single.$1, unorderedEquals([2]));
      expect(h.finishes.single.$2, unorderedEquals([1]));
    });
  }

  testWidgets(
    'single replacement syncs displaced selection before auto-close',
    (
      tester,
    ) async {
      final h = _Harness();
      await h.open(
        tester,
        selectionMode: SelectionMode.single,
      );
      await tester.tap(find.text('Item 2'));
      await tester.pumpAndSettle();
      expect(h.parent.value, {2, 9});
      expect(h.finishes.single.$1, unorderedEquals([2]));
      expect(h.finishes.single.$2, unorderedEquals([1]));
      expect(h.notifications, 1);
    },
  );

  testWidgets('reopen starts a new session from the current seed', (
    tester,
  ) async {
    final h = _Harness();
    await h.open(tester);
    await tester.tap(find.text('Item 2'));
    await tester.pumpAndSettle();
    await h.close(tester);
    await tester.tap(find.text('Child'));
    await tester.pumpAndSettle();
    h.child.selectLoaded();
    await tester.pumpAndSettle();
    await h.close(tester);
    expect(h.finishes.last.$1, unorderedEquals([2, 3]));
    expect(h.finishes.last.$2, isEmpty);
  });
}
