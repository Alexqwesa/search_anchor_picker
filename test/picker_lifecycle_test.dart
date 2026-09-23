import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:search_anchor_picker/search_anchor_picker.dart';
import 'package:search_anchor_picker/src/raw/picker_resource_tracker.dart';

PickerConfig<int> _config(Future<List<int>> Function() load) {
  return PickerConfig<int>(
    itemsLoader: (_, _) => load(),
    idOf: (item) => item,
    labelOf: (item) => 'Item $item',
    searchTermsOf: (item) => ['Item $item'],
  );
}

class _TrackedListenable extends ChangeNotifier {
  bool get hasActiveListeners => hasListeners;

  void signal() => notifyListeners();
}

void main() {
  testWidgets('10000 closed pickers keep popup resources lazy', (
    tester,
  ) async {
    const pickerCount = 10000;
    var loadCalls = 0;
    var headerBuildCalls = 0;
    var triggerBuildCalls = 0;
    GlobalKey? openedHeaderKey;
    final source = _TrackedListenable();
    PickerResourceTracker.reset();
    addTearDown(source.dispose);
    addTearDown(PickerResourceTracker.reset);

    final configs = List.generate(
      pickerCount,
      (_) => PickerConfig<int>(
        itemsLoader: (_, _) async {
          loadCalls++;
          return const [1];
        },
        idOf: (item) => item,
        labelOf: (item) => 'Item $item',
        searchTermsOf: (item) => ['Item $item'],
        listenable: source,
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
                triggerBuilder: (context, open, version) {
                  triggerBuildCalls++;
                  return GestureDetector(
                    onTap: open,
                    child: const SizedBox.shrink(),
                  );
                },
                headerBuilder: (context, controller, items) {
                  headerBuildCalls++;
                  openedHeaderKey = controller.getKey('header');
                  return [SizedBox(key: openedHeaderKey)];
                },
              ),
          ],
        ),
      ),
    );

    expect(find.byType(SearchAnchorPicker<int>), findsNWidgets(pickerCount));
    expect(find.byType(AnimatedOpacity), findsNothing);
    expect(find.byType(DefaultPickerSearchField), findsNothing);
    expect(find.byType(SearchBar), findsNothing);
    expect(loadCalls, 0);
    expect(headerBuildCalls, 0);
    expect(triggerBuildCalls, pickerCount);
    expect(source.hasActiveListeners, isFalse);
    expect(PickerResourceTracker.createdByType, isEmpty);
    expect(PickerResourceTracker.liveByType, isEmpty);

    final stopwatch = Stopwatch()..start();
    configs[pickerCount ~/ 2].open();
    await tester.pump();
    stopwatch.stop();

    expect(loadCalls, 1);
    expect(headerBuildCalls, 1);
    expect(triggerBuildCalls, pickerCount + 1);
    expect(source.hasActiveListeners, isTrue);
    expect(PickerResourceTracker.createdByType, hasLength(10));
    expect(PickerResourceTracker.createdByType.values, everyElement(1));
    expect(
      PickerResourceTracker.liveByType,
      PickerResourceTracker.createdByType,
    );
    expect(openedHeaderKey, isNotNull);
    expect(
      find.byKey(openedHeaderKey!, skipOffstage: false),
      findsOneWidget,
    );

    // Wall-clock values vary across CI hosts; allocation and rebuild counts are
    // the stable performance contract. Keep the duration visible on failure.
    expect(
      stopwatch.elapsed,
      lessThan(const Duration(seconds: 5)),
      reason: 'Opening one of $pickerCount anchors took ${stopwatch.elapsed}.',
    );

    configs[pickerCount ~/ 2].close();
    await tester.pumpAndSettle();

    expect(source.hasActiveListeners, isFalse);
    expect(PickerResourceTracker.createdByType, hasLength(10));
    expect(PickerResourceTracker.createdByType.values, everyElement(1));
    expect(PickerResourceTracker.liveByType, isEmpty);
    expect(openedHeaderKey!.currentContext, isNull);
  });

  testWidgets('closed picker does not subscribe to its data listenable', (
    tester,
  ) async {
    final source = _TrackedListenable();
    addTearDown(source.dispose);
    final config = PickerConfig<int>(
      itemsLoader: (_, _) async => [1],
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

  testWidgets(
    'related-list status repaints without reloading or changing selection',
    (tester) async {
      final relatedListItemStatusChanges = _TrackedListenable();
      addTearDown(relatedListItemStatusChanges.dispose);
      var membership = PickerAuxiliaryMembership.member;
      var loadCalls = 0;
      final config = PickerConfig<int>(
        itemsLoader: (_, _) async {
          loadCalls++;
          return [1];
        },
        idOf: (item) => item,
        labelOf: (item) => 'Item $item',
        searchTermsOf: (item) => ['Item $item'],
        relatedListItemStatusOf: (_) =>
            PickerRelatedListItemStatus(auxiliaryMembership: membership),
        relatedListItemStatusListenable: relatedListItemStatusChanges,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: SearchAnchorPicker<int>(
            config: config,
            initialSelectedIds: const [1],
          ),
        ),
      );
      expect(relatedListItemStatusChanges.hasActiveListeners, isFalse);

      config.open();
      await tester.pumpAndSettle();
      expect(loadCalls, 1);
      expect(relatedListItemStatusChanges.hasActiveListeners, isTrue);
      expect(find.byIcon(Icons.person), findsOneWidget);

      membership = PickerAuxiliaryMembership.unknown;
      relatedListItemStatusChanges.signal();
      await tester.pumpAndSettle();
      expect(loadCalls, 1);
      expect(find.byIcon(Icons.person_search_outlined), findsOneWidget);

      membership = PickerAuxiliaryMembership.notMember;
      relatedListItemStatusChanges.signal();
      await tester.pumpAndSettle();
      expect(loadCalls, 1);
      expect(find.byIcon(Icons.person_outline), findsOneWidget);
      expect(
        tester.widget<CheckboxListTile>(find.byType(CheckboxListTile)).value,
        isTrue,
      );

      config.close();
      await tester.pumpAndSettle();
      expect(relatedListItemStatusChanges.hasActiveListeners, isFalse);
    },
  );

  testWidgets(
    'partial membership keeps absence unknown unless independently known',
    (
      tester,
    ) async {
      const loadedSublistIds = {1};
      const authoritativeMembership = {2: false};
      final config = PickerConfig<int>(
        itemsLoader: (_, _) async => [1, 2, 3],
        idOf: (item) => item,
        labelOf: (item) => 'Item $item',
        searchTermsOf: (item) => ['Item $item'],
        relatedListItemStatusOf: (item) => PickerRelatedListItemStatus(
          auxiliaryMembership: loadedSublistIds.contains(item)
              ? PickerAuxiliaryMembership.member
              : switch (authoritativeMembership[item]) {
                  true => PickerAuxiliaryMembership.member,
                  false => PickerAuxiliaryMembership.notMember,
                  null => PickerAuxiliaryMembership.unknown,
                },
        ),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: SearchAnchorPicker<int>(
            config: config,
            initialSelectedIds: const [2, 3],
          ),
        ),
      );

      config.open();
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.person), findsOneWidget);
      expect(find.byIcon(Icons.person_outline), findsOneWidget);
      expect(find.byIcon(Icons.person_search_outlined), findsOneWidget);
      expect(
        tester
            .widget<CheckboxListTile>(
              find.ancestor(
                of: find.text('Item 2'),
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
                of: find.text('Item 3'),
                matching: find.byType(CheckboxListTile),
              ),
            )
            .value,
        isTrue,
      );
    },
  );

  testWidgets('blocked related-list status keeps selection and shows warning', (
    tester,
  ) async {
    final config = PickerConfig<int>(
      itemsLoader: (_, _) async => [1],
      idOf: (item) => item,
      labelOf: (item) => 'Item $item',
      searchTermsOf: (item) => ['Item $item'],
      relatedListItemStatusOf: (_) => const PickerRelatedListItemStatus(
        unselectPolicy: PickerUnselectPolicy.blocked,
      ),
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SearchAnchorPicker<int>(
            config: config,
            initialSelectedIds: const [1],
          ),
        ),
      ),
    );

    config.open();
    await tester.pumpAndSettle();
    await tester.tap(find.text('Item 1'));
    await tester.pump();

    expect(find.text('Item 1 is currently in use.'), findsOneWidget);
    expect(
      tester.widget<CheckboxListTile>(find.byType(CheckboxListTile)).value,
      isTrue,
    );
  });

  testWidgets('confirm related-list status unselects only after confirmation', (
    tester,
  ) async {
    final config = PickerConfig<int>(
      itemsLoader: (_, _) async => [1],
      idOf: (item) => item,
      labelOf: (item) => 'Item $item',
      searchTermsOf: (item) => ['Item $item'],
      relatedListItemStatusOf: (_) => const PickerRelatedListItemStatus(
        unselectPolicy: PickerUnselectPolicy.confirm,
      ),
    );

    await tester.pumpWidget(
      MaterialApp(
        home: SearchAnchorPicker<int>(
          config: config,
          initialSelectedIds: const [1],
        ),
      ),
    );

    config.open();
    await tester.pumpAndSettle();
    await tester.tap(find.text('Item 1'));
    await tester.pumpAndSettle();

    expect(find.text('Remove item?'), findsOneWidget);
    expect(
      tester.widget<CheckboxListTile>(find.byType(CheckboxListTile)).value,
      isTrue,
    );

    await tester.tap(find.widgetWithText(TextButton, 'Remove'));
    await tester.pumpAndSettle();

    expect(
      tester.widget<CheckboxListTile>(find.byType(CheckboxListTile)).value,
      isFalse,
    );
  });

  testWidgets('inline config replacement does not reload an open picker', (
    tester,
  ) async {
    late StateSetter rebuild;
    var parentBuildValue = 0;
    var loadCalls = 0;

    await tester.pumpWidget(
      MaterialApp(
        home: StatefulBuilder(
          builder: (context, setState) {
            rebuild = setState;
            final buildValue = parentBuildValue;
            return SearchAnchorPicker<int>(
              config: PickerConfig<int>(
                itemsLoader: (_, _) async {
                  loadCalls++;
                  return [1];
                },
                idOf: (item) => item,
                labelOf: (item) => 'Build $buildValue item $item',
                searchTermsOf: (item) => ['Item $item'],
              ),
              initialSelectedIds: const [],
            );
          },
        ),
      ),
    );

    await tester.tap(find.byIcon(Icons.search));
    await tester.pumpAndSettle();
    expect(loadCalls, 1);
    expect(find.text('Build 0 item 1'), findsOneWidget);

    rebuild(() => parentBuildValue++);
    await tester.pumpAndSettle();
    expect(loadCalls, 1);
    expect(find.text('Build 0 item 1'), findsNothing);
    expect(find.text('Build 1 item 1'), findsOneWidget);
  });

  testWidgets('reloadKey change reloads once and same-frame changes coalesce', (
    tester,
  ) async {
    late StateSetter rebuild;
    var reloadKey = 0;
    var unrelatedValue = 0;
    var loadCalls = 0;

    await tester.pumpWidget(
      MaterialApp(
        home: StatefulBuilder(
          builder: (context, setState) {
            rebuild = setState;
            return SearchAnchorPicker<int>(
              config: PickerConfig<int>(
                reloadKey: reloadKey,
                title: 'Build $unrelatedValue',
                itemsLoader: (_, _) async {
                  loadCalls++;
                  return [1];
                },
                idOf: (item) => item,
                labelOf: (item) => 'Item $item',
                searchTermsOf: (item) => ['Item $item'],
              ),
              initialSelectedIds: const [],
            );
          },
        ),
      ),
    );

    await tester.tap(find.byIcon(Icons.search));
    await tester.pumpAndSettle();
    expect(loadCalls, 1);

    rebuild(() => unrelatedValue++);
    await tester.pumpAndSettle();
    expect(loadCalls, 1);

    rebuild(() => reloadKey = 1);
    await tester.pumpAndSettle();
    expect(loadCalls, 2);

    rebuild(() => reloadKey = 2);
    rebuild(() => reloadKey = 3);
    await tester.pumpAndSettle();
    expect(loadCalls, 3);
  });

  testWidgets('replacing config rebinds its open-only listenable', (
    tester,
  ) async {
    final firstSource = ChangeNotifier();
    final secondSource = ChangeNotifier();
    addTearDown(firstSource.dispose);
    addTearDown(secondSource.dispose);
    late StateSetter rebuild;
    Listenable source = firstSource;
    var loadCalls = 0;

    await tester.pumpWidget(
      MaterialApp(
        home: StatefulBuilder(
          builder: (context, setState) {
            rebuild = setState;
            return SearchAnchorPicker<int>(
              config: PickerConfig<int>(
                itemsLoader: (_, _) async {
                  loadCalls++;
                  return [1];
                },
                idOf: (item) => item,
                labelOf: (item) => 'Item $item',
                searchTermsOf: (item) => ['Item $item'],
                listenable: source,
              ),
              initialSelectedIds: const [],
            );
          },
        ),
      ),
    );

    await tester.tap(find.byIcon(Icons.search));
    await tester.pumpAndSettle();
    expect(loadCalls, 1);

    rebuild(() => source = secondSource);
    await tester.pumpAndSettle();
    expect(loadCalls, 1);

    firstSource.notifyListeners();
    await tester.pumpAndSettle();
    expect(loadCalls, 1);

    secondSource.notifyListeners();
    await tester.pumpAndSettle();
    expect(loadCalls, 2);
  });

  testWidgets('controller refresh explicitly reloads once', (tester) async {
    var loadCalls = 0;

    await tester.pumpWidget(
      MaterialApp(
        home: SearchAnchorPicker<int>(
          config: _config(() async {
            loadCalls++;
            return [1];
          }),
          initialSelectedIds: const [],
          headerBuilder: (context, value, items) {
            return [
              TextButton(
                onPressed: value.refresh,
                child: const Text('Refresh'),
              ),
            ];
          },
        ),
      ),
    );

    await tester.tap(find.byIcon(Icons.search));
    await tester.pumpAndSettle();
    expect(loadCalls, 1);

    await tester.tap(find.text('Refresh'));
    await tester.pumpAndSettle();
    expect(loadCalls, 2);
  });

  testWidgets('config replaced while closed is used on the next open', (
    tester,
  ) async {
    late StateSetter rebuild;
    var useSecondLoader = false;
    var firstLoadCalls = 0;
    var secondLoadCalls = 0;

    await tester.pumpWidget(
      MaterialApp(
        home: StatefulBuilder(
          builder: (context, setState) {
            rebuild = setState;
            final useSecond = useSecondLoader;
            return SearchAnchorPicker<int>(
              config: _config(() async {
                if (useSecond) {
                  secondLoadCalls++;
                  return [2];
                }
                firstLoadCalls++;
                return [1];
              }),
              initialSelectedIds: const [],
            );
          },
        ),
      ),
    );

    rebuild(() => useSecondLoader = true);
    await tester.pumpAndSettle();
    expect(firstLoadCalls, 0);
    expect(secondLoadCalls, 0);

    await tester.tap(find.byIcon(Icons.search));
    await tester.pumpAndSettle();
    expect(firstLoadCalls, 0);
    expect(secondLoadCalls, 1);
    expect(find.text('Item 2'), findsOneWidget);
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
          onClose: (_) {
            finishCount++;
          },
        ),
      ),
    );

    config.open();
    await tester.pumpAndSettle();
    config
      ..close()
      ..close();
    await tester.pumpAndSettle();
    expect(finishCount, 1);
  });

  testWidgets('newer reload wins over stale completion', (tester) async {
    final refresh = ValueNotifier<int>(0);
    final first = Completer<List<int>>();
    final second = Completer<List<int>>();
    var calls = 0;
    final config = PickerConfig<int>(
      itemsLoader: (_, _) => calls++ == 0 ? first.future : second.future,
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

  testWidgets('external query controller is never disposed by picker', (
    tester,
  ) async {
    final controller = TextEditingController();
    addTearDown(controller.dispose);
    await tester.pumpWidget(
      MaterialApp(
        home: SearchAnchorPicker<int>(
          config: _config(() async => [1]),
          initialSelectedIds: const [],
          queryController: controller,
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
          onClose: (_) {
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
    expect(find.text('Selection not saved'), findsOneWidget);
    await tester.tap(find.text('Close without saving'));
    await tester.pumpAndSettle();

    config.open();
    await tester.pumpAndSettle();
    expect(find.text('Item 1'), findsOneWidget);
  });

  testWidgets('onClose keeps the overlay open while saving', (tester) async {
    final save = Completer<void>();
    final config = _config(() async => [1]);
    await tester.pumpWidget(
      MaterialApp(
        home: SearchAnchorPicker<int>(
          config: config,
          initialSelectedIds: const [],
          onClose: (_) => save.future,
        ),
      ),
    );
    config.open();
    await tester.pumpAndSettle();
    config.close();
    await tester.pump();
    expect(find.text('Saving…'), findsOneWidget);
    expect(find.text('Item 1'), findsOneWidget);
    save.complete();
    await tester.pumpAndSettle();
    expect(find.text('Item 1'), findsNothing);
  });

  testWidgets('failed onClose can keep editing or close without saving', (
    tester,
  ) async {
    final errors = <FlutterErrorDetails>[];
    final previousOnError = FlutterError.onError;
    FlutterError.onError = errors.add;
    addTearDown(() => FlutterError.onError = previousOnError);
    var shouldFail = true;
    final config = _config(() async => [1, 2]);
    await tester.pumpWidget(
      MaterialApp(
        home: SearchAnchorPicker<int>(
          config: config,
          initialSelectedIds: const [],
          onClose: (_) {
            if (shouldFail) throw StateError('save failed');
          },
        ),
      ),
    );
    config.open();
    await tester.pumpAndSettle();
    await tester.tap(find.text('Item 1'));
    await tester.pump();
    config.close();
    await tester.pumpAndSettle();
    expect(find.text('Selection not saved'), findsOneWidget);
    expect(
      find.text('The popup could not be saved because of an error.'),
      findsOneWidget,
    );
    await tester.tap(find.text('Keep editing'));
    await tester.pumpAndSettle();
    expect(find.text('Item 1'), findsOneWidget);
    expect(find.text('Item 2'), findsOneWidget);
    shouldFail = false;
    config.close();
    await tester.pumpAndSettle();
    expect(find.text('Item 1'), findsNothing);
    expect(errors, hasLength(1));
  });

  testWidgets(
    'close-save builders replace the default saving wrap and prompt',
    (
      tester,
    ) async {
      final errors = <FlutterErrorDetails>[];
      final previousOnError = FlutterError.onError;
      FlutterError.onError = errors.add;
      addTearDown(() => FlutterError.onError = previousOnError);
      final save = Completer<void>();
      final config = _config(() async => [1]);
      await tester.pumpWidget(
        MaterialApp(
          home: SearchAnchorPicker<int>(
            config: config,
            initialSelectedIds: const [],
            onClose: (_) => save.future,
            closeSavingBuilder: (context, child) => Stack(
              children: [
                child,
                const Center(child: Text('Custom saving')),
              ],
            ),
            closeSaveFailedBuilder: (context, error, stackTrace) async {
              return CloseSaveFailedAction.closeWithoutSaving;
            },
          ),
        ),
      );
      config.open();
      await tester.pumpAndSettle();
      config.close();
      await tester.pump();
      expect(find.text('Custom saving'), findsOneWidget);
      expect(find.text('Saving…'), findsNothing);
      save.completeError(StateError('save failed'), StackTrace.current);
      await tester.pumpAndSettle();
      expect(find.text('Selection not saved'), findsNothing);
      expect(find.text('Item 1'), findsNothing);
      expect(errors, hasLength(1));
    },
  );

  testWidgets('empty onClose delta still runs the callback', (tester) async {
    var closes = 0;
    final config = _config(() async => [1]);
    await tester.pumpWidget(
      MaterialApp(
        home: SearchAnchorPicker<int>(
          config: config,
          initialSelectedIds: const [],
          onClose: (_) {
            closes++;
          },
        ),
      ),
    );
    config.open();
    await tester.pumpAndSettle();
    config.close();
    await tester.pumpAndSettle();
    expect(closes, 1);
    expect(find.text('Item 1'), findsNothing);
  });
}
