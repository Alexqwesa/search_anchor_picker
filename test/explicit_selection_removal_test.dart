// ignore_for_file: unnecessary_underscores

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:search_anchor_picker/search_anchor_picker.dart';

Widget _pendingIds(GenericPickerController<int, int> controller) {
  return ValueListenableBuilder<Set<int>>(
    valueListenable: controller.pendingIdsListenable,
    builder: (context, pending, _) {
      final sorted = pending.toList()..sort();
      return Text('Pending: ${sorted.join(',')}');
    },
  );
}

void main() {
  testWidgets(
    'partial results preserve unseen selections and report only explicit unselects',
    (tester) async {
      final finalIds = <int>{1, 2, 3};
      var addedIds = <int>[];
      var removedIds = <int>[];

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SearchAnchorPicker<int>(
              config: PickerConfig<int>(
                loadItems: (_) async => [2, 4],
                idOf: (i) => i,
                labelOf: (i) => 'Item $i',
                searchTermsOf: (i) => ['Item $i'],
              ),
              initialSelectedIds: const [1, 2, 3],
              triggerBuilder: (_, open, __) =>
                  ElevatedButton(onPressed: open, child: const Text('Open')),
              onClose: (result) {
                final added = result.added.toList();
                final removed = result.removed.toList();
                addedIds = added;
                removedIds = removed;
                finalIds
                  ..addAll(added)
                  ..removeAll(removed);
              },
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Item 2'));
      await tester.pumpAndSettle();
      await tester.tap(find.byIcon(Icons.arrow_back));
      await tester.pumpAndSettle();

      expect(finalIds, {1, 3});
      expect(addedIds, isEmpty);
      expect(removedIds, [2]);
    },
  );

  testWidgets('user row checks are reported as added', (tester) async {
    final finalIds = <int>{1, 2, 3};
    var addedIds = <int>[];
    var removedIds = <int>[];

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SearchAnchorPicker<int>(
            config: PickerConfig<int>(
              loadItems: (_) async => [2, 4],
              idOf: (i) => i,
              labelOf: (i) => 'Item $i',
              searchTermsOf: (i) => ['Item $i'],
            ),
            initialSelectedIds: const [1, 2, 3],
            triggerBuilder: (_, open, __) =>
                ElevatedButton(onPressed: open, child: const Text('Open')),
            onClose: (result) {
              final added = result.added.toList();
              final removed = result.removed.toList();
              addedIds = added;
              removedIds = removed;
              finalIds
                ..addAll(added)
                ..removeAll(removed);
            },
          ),
        ),
      ),
    );

    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Item 4'));
    await tester.pumpAndSettle();
    await tester.tap(find.byIcon(Icons.arrow_back));
    await tester.pumpAndSettle();

    expect(finalIds, {1, 2, 3, 4});
    expect(addedIds, [4]);
    expect(removedIds, isEmpty);
  });

  testWidgets(
    'closing partial results without toggles preserves all selected ids',
    (tester) async {
      final finalIds = <int>{1, 2, 3};
      var removedIds = <int>[];

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SearchAnchorPicker<int>(
              config: PickerConfig<int>(
                loadItems: (_) async => [4],
                idOf: (i) => i,
                labelOf: (i) => 'Item $i',
                searchTermsOf: (i) => ['Item $i'],
              ),
              initialSelectedIds: const [1, 2, 3],
              triggerBuilder: (_, open, __) =>
                  ElevatedButton(onPressed: open, child: const Text('Open')),
              onClose: (result) {
                final added = result.added.toList();
                final removed = result.removed.toList();
                removedIds = removed;
                finalIds
                  ..addAll(added)
                  ..removeAll(removed);
              },
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();
      await tester.tap(find.byIcon(Icons.arrow_back));
      await tester.pumpAndSettle();

      expect(finalIds, {1, 2, 3});
      expect(removedIds, isEmpty);
    },
  );

  testWidgets(
    'client-side reload missing selected ids does not auto-remove them',
    (tester) async {
      final refreshN = ValueNotifier<int>(0);
      var items = [1];
      final finalIds = <int>{1, 2};
      var removedIds = <int>[];

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SearchAnchorPicker<int>(
              config: PickerConfig<int>(
                loadItems: (_) async => items,
                idOf: (i) => i,
                labelOf: (i) => 'Item $i',
                searchTermsOf: (i) => ['Item $i'],
                listenable: refreshN,
              ),
              initialSelectedIds: const [1, 2],
              triggerBuilder: (_, open, __) =>
                  ElevatedButton(onPressed: open, child: const Text('Open')),
              onClose: (result) {
                final added = result.added.toList();
                final removed = result.removed.toList();
                removedIds = removed;
                finalIds
                  ..addAll(added)
                  ..removeAll(removed);
              },
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      items = [3];
      refreshN.value++;
      await tester.pumpAndSettle();
      await tester.tap(find.byIcon(Icons.arrow_back));
      await tester.pumpAndSettle();

      expect(finalIds, {1, 2});
      expect(removedIds, isEmpty);
    },
  );

  testWidgets(
    'parent changing initialSelectedIds while open explicitly reseeds pending',
    (tester) async {
      final selectedN = ValueNotifier<List<int>>(const [1, 2, 3]);
      var removedIds = <int>[];

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ValueListenableBuilder<List<int>>(
              valueListenable: selectedN,
              builder: (context, selectedIds, _) {
                return SearchAnchorPicker<int>(
                  config: PickerConfig<int>(
                    loadItems: (_) async => [1, 2, 3],
                    idOf: (i) => i,
                    labelOf: (i) => 'Item $i',
                    searchTermsOf: (i) => ['Item $i'],
                  ),
                  initialSelectedIds: selectedIds,
                  triggerBuilder: (_, open, __) => ElevatedButton(
                    onPressed: open,
                    child: const Text('Open'),
                  ),
                  onClose: (result) {
                    removedIds = result.removed.toList();
                  },
                );
              },
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      selectedN.value = const [1];
      await tester.pumpAndSettle();

      expect(
        tester
            .widget<CheckboxListTile>(
              find.ancestor(
                of: find.text('Item 1'),
                matching: find.byType(CheckboxListTile),
              ),
            )
            .value,
        isTrue,
      );
      expect(
        tester
            .widget<CheckboxListTile>(
              find.ancestor(
                of: find.text('Item 2'),
                matching: find.byType(CheckboxListTile),
              ),
            )
            .value,
        isFalse,
      );
      await tester.tap(find.byIcon(Icons.arrow_back));
      await tester.pumpAndSettle();

      expect(removedIds, isEmpty);
    },
  );

  testWidgets(
    'temporary empty initialSelectedIds while open does not report removals',
    (tester) async {
      final selectedN = ValueNotifier<List<int>>(const [1, 2, 3]);
      var removedIds = <int>[];

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ValueListenableBuilder<List<int>>(
              valueListenable: selectedN,
              builder: (context, selectedIds, _) {
                return SearchAnchorPicker<int>(
                  config: PickerConfig<int>(
                    loadItems: (_) async => [1, 2, 3],
                    idOf: (i) => i,
                    labelOf: (i) => 'Item $i',
                    searchTermsOf: (i) => ['Item $i'],
                  ),
                  initialSelectedIds: selectedIds,
                  triggerBuilder: (_, open, __) => ElevatedButton(
                    onPressed: open,
                    child: const Text('Open'),
                  ),
                  onClose: (result) {
                    removedIds = result.removed.toList();
                  },
                );
              },
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      selectedN.value = const [];
      await tester.pumpAndSettle();
      await tester.tap(find.byIcon(Icons.arrow_back));
      await tester.pumpAndSettle();

      expect(removedIds, isEmpty);
    },
  );

  testWidgets(
    'user add survives a later empty initialSelectedIds reseed',
    (tester) async {
      final selectedN = ValueNotifier<List<int>>(const [1]);
      var addedIds = <int>[];
      var removedIds = <int>[];

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ValueListenableBuilder<List<int>>(
              valueListenable: selectedN,
              builder: (context, selectedIds, _) {
                return SearchAnchorPicker<int>(
                  config: PickerConfig<int>(
                    loadItems: (_) async => [1, 2, 3],
                    idOf: (i) => i,
                    labelOf: (i) => 'Item $i',
                    searchTermsOf: (i) => ['Item $i'],
                  ),
                  initialSelectedIds: selectedIds,
                  triggerBuilder: (_, open, __) => ElevatedButton(
                    onPressed: open,
                    child: const Text('Open'),
                  ),
                  onClose: (result) {
                    addedIds = result.added.toList();
                    removedIds = result.removed.toList();
                  },
                );
              },
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Item 2'));
      await tester.pumpAndSettle();
      selectedN.value = const [];
      await tester.pumpAndSettle();
      await tester.tap(find.byIcon(Icons.arrow_back));
      await tester.pumpAndSettle();

      expect(addedIds, [2]);
      expect(removedIds, isEmpty);
    },
  );

  testWidgets('syncPending changes final ids without reporting deltas', (
    tester,
  ) async {
    var removedIds = <int>[];

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SearchAnchorPicker<int>(
            config: PickerConfig<int>(
              loadItems: (_) async => [1, 2, 3],
              idOf: (i) => i,
              labelOf: (i) => 'Item $i',
              searchTermsOf: (i) => ['Item $i'],
            ),
            initialSelectedIds: const [1, 2, 3],
            headerBuilder: (context, actions, _) {
              return [
                TextButton(
                  onPressed: () =>
                      actions.syncPending(removed: actions.pendingIds),
                  child: const Text('Clear from header'),
                ),
                _pendingIds(actions),
              ];
            },
            triggerBuilder: (_, open, __) =>
                ElevatedButton(onPressed: open, child: const Text('Open')),
            onClose: (result) {
              removedIds = result.removed.toList();
            },
          ),
        ),
      ),
    );

    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Clear from header'));
    await tester.pumpAndSettle();
    expect(find.text('Pending: '), findsOneWidget);
    await tester.tap(find.byIcon(Icons.arrow_back));
    await tester.pumpAndSettle();

    expect(removedIds, isEmpty);
  });

  testWidgets('syncPending preserves ids outside its explicit changes', (
    tester,
  ) async {
    var removedIds = <int>[];

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SearchAnchorPicker<int>(
            config: PickerConfig<int>(
              loadItems: (_) async => [2, 4],
              idOf: (i) => i,
              labelOf: (i) => 'Item $i',
              searchTermsOf: (i) => ['Item $i'],
            ),
            initialSelectedIds: const [1, 2, 3],
            headerBuilder: (context, actions, _) {
              return [
                TextButton(
                  onPressed: () => actions.syncPending(removed: const [2]),
                  child: const Text('Clear current list'),
                ),
                _pendingIds(actions),
              ];
            },
            triggerBuilder: (_, open, __) =>
                ElevatedButton(onPressed: open, child: const Text('Open')),
            onClose: (result) {
              removedIds = result.removed.toList();
            },
          ),
        ),
      ),
    );

    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Clear current list'));
    await tester.pumpAndSettle();
    expect(find.text('Pending: 1,3'), findsOneWidget);
    await tester.tap(find.byIcon(Icons.arrow_back));
    await tester.pumpAndSettle();

    expect(removedIds, isEmpty);
  });

  testWidgets('syncPending synchronization does not report removals', (
    tester,
  ) async {
    var removedIds = <int>[];

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SearchAnchorPicker<int>(
            config: PickerConfig<int>(
              loadItems: (_) async => [2, 4],
              idOf: (i) => i,
              labelOf: (i) => 'Item $i',
              searchTermsOf: (i) => ['Item $i'],
            ),
            initialSelectedIds: const [1, 2, 3],
            headerBuilder: (context, actions, _) {
              return [
                TextButton(
                  onPressed: () => actions.syncPending(removed: const [2]),
                  child: const Text('Clear loaded'),
                ),
                _pendingIds(actions),
              ];
            },
            triggerBuilder: (_, open, __) =>
                ElevatedButton(onPressed: open, child: const Text('Open')),
            onClose: (result) {
              removedIds = result.removed.toList();
            },
          ),
        ),
      ),
    );

    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Clear loaded'));
    await tester.pumpAndSettle();
    expect(find.text('Pending: 1,3'), findsOneWidget);
    await tester.tap(find.byIcon(Icons.arrow_back));
    await tester.pumpAndSettle();

    expect(removedIds, isEmpty);
  });

  testWidgets('clearLoaded reports loaded selected ids as removed', (
    tester,
  ) async {
    final finalIds = <int>{1, 2, 3};
    var removedIds = <int>[];

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SearchAnchorPicker<int>(
            config: PickerConfig<int>(
              loadItems: (_) async => [2, 4],
              idOf: (i) => i,
              labelOf: (i) => 'Item $i',
              searchTermsOf: (i) => ['Item $i'],
            ),
            initialSelectedIds: const [1, 2, 3],
            headerBuilder: (context, actions, _) {
              return [
                TextButton(
                  onPressed: actions.clearLoaded,
                  child: const Text('Clear loaded'),
                ),
              ];
            },
            triggerBuilder: (_, open, __) =>
                ElevatedButton(onPressed: open, child: const Text('Open')),
            onClose: (result) {
              final added = result.added.toList();
              final removed = result.removed.toList();
              removedIds = removed;
              finalIds
                ..addAll(added)
                ..removeAll(removed);
            },
          ),
        ),
      ),
    );

    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Clear loaded'));
    await tester.pumpAndSettle();
    await tester.tap(find.byIcon(Icons.arrow_back));
    await tester.pumpAndSettle();

    expect(finalIds, {1, 3});
    expect(removedIds, [2]);
  });

  testWidgets('selectLoaded reports loaded unselected ids as added', (
    tester,
  ) async {
    final finalIds = <int>{1, 2, 3};
    var addedIds = <int>[];

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SearchAnchorPicker<int>(
            config: PickerConfig<int>(
              loadItems: (_) async => [2, 4],
              idOf: (i) => i,
              labelOf: (i) => 'Item $i',
              searchTermsOf: (i) => ['Item $i'],
            ),
            initialSelectedIds: const [1, 2, 3],
            headerBuilder: (context, actions, _) {
              return [
                TextButton(
                  onPressed: actions.selectLoaded,
                  child: const Text('Select loaded'),
                ),
              ];
            },
            triggerBuilder: (_, open, __) =>
                ElevatedButton(onPressed: open, child: const Text('Open')),
            onClose: (result) {
              final added = result.added.toList();
              final removed = result.removed.toList();
              addedIds = added;
              finalIds
                ..addAll(added)
                ..removeAll(removed);
            },
          ),
        ),
      ),
    );

    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Select loaded'));
    await tester.pumpAndSettle();
    await tester.tap(find.byIcon(Icons.arrow_back));
    await tester.pumpAndSettle();

    expect(finalIds, {1, 2, 3, 4});
    expect(addedIds, [4]);
  });

  testWidgets('clearFiltered reports only filtered selected ids', (
    tester,
  ) async {
    final finalIds = <int>{1, 2, 3};
    var removedIds = <int>[];

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SearchAnchorPicker<int>(
            config: PickerConfig<int>(
              loadItems: (_) async => [1, 2, 3],
              idOf: (i) => i,
              labelOf: (i) => 'Item $i',
              searchTermsOf: (i) => ['Item $i'],
            ),
            initialSelectedIds: const [1, 2, 3],
            headerBuilder: (context, actions, _) {
              return [
                TextButton(
                  onPressed: actions.clearFiltered,
                  child: const Text('Clear filtered'),
                ),
              ];
            },
            triggerBuilder: (_, open, __) =>
                ElevatedButton(onPressed: open, child: const Text('Open')),
            onClose: (result) {
              final added = result.added.toList();
              final removed = result.removed.toList();
              removedIds = removed;
              finalIds
                ..addAll(added)
                ..removeAll(removed);
            },
          ),
        ),
      ),
    );

    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(SearchBar), 'Item 2');
    await tester.pumpAndSettle();
    await tester.tap(find.text('Clear filtered'));
    await tester.pumpAndSettle();
    await tester.tap(find.byIcon(Icons.arrow_back));
    await tester.pumpAndSettle();

    expect(finalIds, {1, 3});
    expect(removedIds, [2]);
  });

  testWidgets('selectFiltered reports only filtered unselected ids', (
    tester,
  ) async {
    final finalIds = <int>{1};
    var addedIds = <int>[];

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SearchAnchorPicker<int>(
            config: PickerConfig<int>(
              loadItems: (_) async => [1, 2, 3],
              idOf: (i) => i,
              labelOf: (i) => 'Item $i',
              searchTermsOf: (i) => ['Item $i'],
            ),
            initialSelectedIds: const [1],
            headerBuilder: (context, actions, _) {
              return [
                TextButton(
                  onPressed: actions.selectFiltered,
                  child: const Text('Select filtered'),
                ),
              ];
            },
            triggerBuilder: (_, open, __) =>
                ElevatedButton(onPressed: open, child: const Text('Open')),
            onClose: (result) {
              final added = result.added.toList();
              final removed = result.removed.toList();
              addedIds = added;
              finalIds
                ..addAll(added)
                ..removeAll(removed);
            },
          ),
        ),
      ),
    );

    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(SearchBar), 'Item 3');
    await tester.pumpAndSettle();
    await tester.tap(find.text('Select filtered'));
    await tester.pumpAndSettle();
    await tester.tap(find.byIcon(Icons.arrow_back));
    await tester.pumpAndSettle();

    expect(finalIds, {1, 3});
    expect(addedIds, [3]);
  });

  testWidgets('setSelected reports deltas while syncPending does not', (
    tester,
  ) async {
    var addedIds = <int>[];
    var removedIds = <int>[];

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SearchAnchorPicker<int>(
            config: PickerConfig<int>(
              loadItems: (_) async => [1, 2, 3],
              idOf: (i) => i,
              labelOf: (i) => 'Item $i',
              searchTermsOf: (i) => ['Item $i'],
            ),
            initialSelectedIds: const [1],
            headerBuilder: (context, actions, _) {
              return [
                TextButton(
                  onPressed: () => actions.syncPending(added: const [2]),
                  child: const Text('Sync pending'),
                ),
                TextButton(
                  onPressed: () => actions.setSelected(3, true),
                  child: const Text('Set selected'),
                ),
                TextButton(
                  onPressed: () => actions.setSelected(1, false),
                  child: const Text('Set unselected'),
                ),
                _pendingIds(actions),
              ];
            },
            triggerBuilder: (_, open, __) =>
                ElevatedButton(onPressed: open, child: const Text('Open')),
            onClose: (result) {
              final added = result.added.toList();
              final removed = result.removed.toList();
              addedIds = added;
              removedIds = removed;
            },
          ),
        ),
      ),
    );

    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Sync pending'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Set selected'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Set unselected'));
    await tester.pumpAndSettle();
    expect(find.text('Pending: 2,3'), findsOneWidget);
    await tester.tap(find.byIcon(Icons.arrow_back));
    await tester.pumpAndSettle();

    expect(addedIds, [3]);
    expect(removedIds, [1]);
  });
}
