import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:generic_search_selector/generic_search_selector.dart';

PickerConfig<int> _config(Future<List<int>> Function() load) {
  return PickerConfig<int>(
    loadItems: (_) => load(),
    idOf: (item) => item,
    labelOf: (item) => 'Item $item',
    searchTermsOf: (item) => ['Item $item'],
  );
}

class _TrackedListenable extends ChangeNotifier {
  bool get hasActiveListeners => hasListeners;
}

void main() {
  testWidgets('1000 closed pickers allocate no popup animation or load state', (
    tester,
  ) async {
    var loadCalls = 0;
    final configs = List.generate(
      1000,
      (_) => PickerConfig<int>(
        loadItems: (_) async {
          loadCalls++;
          return const [1];
        },
        idOf: (item) => item,
        labelOf: (item) => 'Item $item',
        searchTermsOf: (item) => ['Item $item'],
      ),
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Stack(
          children: [
            for (final config in configs)
              SearchAnchorPicker<int>(
                config: config,
                initialSelectedIds: const [],
                triggerChild: const SizedBox.shrink(),
              ),
          ],
        ),
      ),
    );

    expect(find.byType(SearchAnchorPicker<int>), findsNWidgets(1000));
    expect(find.byType(AnimatedOpacity), findsNothing);
    expect(find.byType(DefaultPickerSearchField), findsNothing);
    expect(find.byType(SearchBar), findsNothing);
    expect(loadCalls, 0);
  });

  testWidgets('closed picker does not subscribe to its data listenable', (
    tester,
  ) async {
    final source = _TrackedListenable();
    addTearDown(source.dispose);
    final config = PickerConfig<int>(
      loadItems: (_) async => [1],
      idOf: (item) => item,
      labelOf: (item) => 'Item $item',
      searchTermsOf: (_) => const [],
      listenable: source,
    );
    await tester.pumpWidget(
      MaterialApp(
        home: SearchAnchorPicker<int>(
          config: config,
          initialSelectedIds: const [],
        ),
      ),
    );
    expect(source.hasActiveListeners, isFalse);

    config.open();
    await tester.pumpAndSettle();
    expect(source.hasActiveListeners, isTrue);

    config.close();
    await tester.pumpAndSettle();
    expect(source.hasActiveListeners, isFalse);
  });

  testWidgets('parent seed changed while closed is used on next open', (
    tester,
  ) async {
    final selected = ValueNotifier<List<int>>(const [1]);
    await tester.pumpWidget(
      MaterialApp(
        home: ValueListenableBuilder<List<int>>(
          valueListenable: selected,
          builder: (context, ids, _) => SearchAnchorPicker<int>(
            config: _config(() async => [1, 2]),
            initialSelectedIds: ids,
          ),
        ),
      ),
    );

    selected.value = const [2];
    await tester.pumpAndSettle();
    await tester.tap(find.byIcon(Icons.search));
    await tester.pumpAndSettle();
    final item1 = tester.widget<CheckboxListTile>(
      find.ancestor(
        of: find.text('Item 1'),
        matching: find.byType(CheckboxListTile),
      ),
    );
    final item2 = tester.widget<CheckboxListTile>(
      find.ancestor(
        of: find.text('Item 2'),
        matching: find.byType(CheckboxListTile),
      ),
    );
    expect(item1.value, false);
    expect(item2.value, true);
  });

  testWidgets('duplicate close requests finish exactly once', (tester) async {
    var finishCount = 0;
    final config = _config(() async => [1]);

    await tester.pumpWidget(
      MaterialApp(
        home: SearchAnchorPicker<int>(
          config: config,
          initialSelectedIds: const [],
          onFinish: ({required added, required removed}) async {
            finishCount++;
          },
        ),
      ),
    );

    config.open();
    await tester.pumpAndSettle();
    config.close();
    config.close();
    await tester.pumpAndSettle();
    expect(finishCount, 1);
  });

  testWidgets('newer reload wins over stale completion', (tester) async {
    final refresh = ValueNotifier<int>(0);
    final first = Completer<List<int>>();
    final second = Completer<List<int>>();
    var calls = 0;
    final config = PickerConfig<int>(
      loadItems: (_) => calls++ == 0 ? first.future : second.future,
      idOf: (item) => item,
      labelOf: (item) => 'Item $item',
      searchTermsOf: (item) => ['Item $item'],
      listenable: refresh,
    );

    await tester.pumpWidget(
      MaterialApp(
        home: SearchAnchorPicker<int>(
          config: config,
          initialSelectedIds: const [],
        ),
      ),
    );
    await tester.tap(find.byIcon(Icons.search));
    await tester.pump();
    refresh.value++;
    await tester.pump();

    second.complete([2]);
    await tester.pumpAndSettle();
    expect(find.text('Item 2'), findsOneWidget);

    first.complete([1]);
    await tester.pumpAndSettle();
    expect(find.text('Item 2'), findsOneWidget);
    expect(find.text('Item 1'), findsNothing);
  });

  testWidgets('load error uses custom builder and retry', (tester) async {
    var calls = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: SearchAnchorPicker<int>(
          config: _config(() async {
            if (calls++ == 0) throw StateError('offline');
            return [7];
          }),
          initialSelectedIds: const [],
          errorBuilder: (context, error, stack, retry) =>
              TextButton(onPressed: retry, child: Text('Retry $error')),
        ),
      ),
    );

    await tester.tap(find.byIcon(Icons.search));
    await tester.pumpAndSettle();
    expect(find.textContaining('Retry Bad state: offline'), findsOneWidget);
    await tester.tap(find.textContaining('Retry Bad state: offline'));
    await tester.pumpAndSettle();
    expect(find.text('Item 7'), findsOneWidget);
  });

  testWidgets('disposing during load does not update dead overlay', (
    tester,
  ) async {
    final load = Completer<List<int>>();
    await tester.pumpWidget(
      MaterialApp(
        home: SearchAnchorPicker<int>(
          config: _config(() => load.future),
          initialSelectedIds: const [],
        ),
      ),
    );
    await tester.tap(find.byIcon(Icons.search));
    await tester.pump();
    await tester.pumpWidget(const MaterialApp(home: SizedBox()));
    load.complete([1]);
    await tester.pumpAndSettle();
  });

  testWidgets('external SearchController is never disposed by picker', (
    tester,
  ) async {
    final controller = SearchController();
    addTearDown(controller.dispose);
    await tester.pumpWidget(
      MaterialApp(
        home: SearchAnchorPicker<int>(
          config: _config(() async => [1]),
          initialSelectedIds: const [],
          searchController: controller,
        ),
      ),
    );
    await tester.pumpWidget(const MaterialApp(home: SizedBox()));
    controller.text = 'still alive';
    expect(controller.text, 'still alive');
  });

  testWidgets('internally owned controller preserves query across reopen', (
    tester,
  ) async {
    final config = _config(() async => [1, 2]);
    await tester.pumpWidget(
      MaterialApp(
        home: SearchAnchorPicker<int>(
          config: config,
          initialSelectedIds: const [],
        ),
      ),
    );

    config.open();
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(SearchBar), 'Item 2');
    await tester.pumpAndSettle();
    config.close();
    await tester.pumpAndSettle();

    config.open();
    await tester.pumpAndSettle();
    expect(
      tester.widget<SearchBar>(find.byType(SearchBar)).controller!.text,
      'Item 2',
    );
    expect(find.text('Item 1'), findsNothing);
    expect(find.text('Item 2'), findsWidgets);
  });

  testWidgets('callback failure is reported but picker remains reusable', (
    tester,
  ) async {
    final errors = <FlutterErrorDetails>[];
    final previousOnError = FlutterError.onError;
    FlutterError.onError = errors.add;
    addTearDown(() => FlutterError.onError = previousOnError);
    final config = _config(() async => [1]);

    await tester.pumpWidget(
      MaterialApp(
        home: SearchAnchorPicker<int>(
          config: config,
          initialSelectedIds: const [],
          onFinish: ({required added, required removed}) async {
            throw StateError('save failed');
          },
        ),
      ),
    );
    config.open();
    await tester.pumpAndSettle();
    config.close();
    await tester.pumpAndSettle();
    expect(errors.single.exception, isA<StateError>());

    config.open();
    await tester.pumpAndSettle();
    expect(find.text('Item 1'), findsOneWidget);
  });
}
