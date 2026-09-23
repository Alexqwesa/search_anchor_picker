import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:search_anchor_picker/search_anchor_picker.dart';

void main() {
  testWidgets('PickerConfig.open/close controls SearchAnchorPicker', (
    tester,
  ) async {
    final config = PickerConfig<int>(
      itemsLoader: (_, _) async => [1, 2, 3],
      idOf: (i) => i,
      labelOf: (i) => '$i',
      searchTermsOf: (_) => [],
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SearchAnchorPicker<int>(
            config: config,
            initialSelectedIds: const [],
          ),
        ),
      ),
    );

    // Initial state: picker closed
    expect(find.text('1'), findsNothing);

    // Open via config
    config.open();
    await tester.pumpAndSettle();

    // Picker should be open
    expect(find.text('1'), findsOneWidget);

    // Close via config
    config.close();
    await tester.pumpAndSettle();

    // Picker should be closed
    expect(find.text('1'), findsNothing);
  });

  testWidgets('Radio sub-picker closes main picker on selection', (
    tester,
  ) async {
    // MAIN PICKER
    final mainConfig = PickerConfig<int>(
      itemsLoader: (_, _) async => [1],
      idOf: (i) => i,
      labelOf: (i) => 'Main $i',
      searchTermsOf: (_) => [],
    );

    // SUB PICKER
    final subConfig = PickerConfig<int>(
      itemsLoader: (_, _) async => [100],
      idOf: (i) => i,
      labelOf: (i) => 'Sub $i',
      searchTermsOf: (_) => [],
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SearchAnchorPicker<int>(
            config: mainConfig,
            initialSelectedIds: const [],
            headerBuilder: (context, actions, items) {
              return [
                SubPickerTile<int>(
                  title: 'Open Sub',
                  config: subConfig,
                  initialSelectedIds: const [],
                  selectionMode:
                      SelectionMode.single, // Closes itself on select
                  onClose: (result) {
                    if (result.added.isNotEmpty) {
                      // If selection made in sub-picker, CLOSE MAIN PICKER too.
                      mainConfig.close();
                    }
                  },
                ),
              ];
            },
          ),
        ),
      ),
    );

    // 1. Open Main
    await tester.tap(find.byIcon(Icons.search));
    await tester.pumpAndSettle();
    expect(find.text('Open Sub'), findsOneWidget);

    // 2. Open Sub
    await tester.tap(find.text('Open Sub'));
    await tester.pumpAndSettle();
    expect(find.text('Sub 100'), findsOneWidget);

    // 3. Select Item in Sub (Radio mode)
    await tester.tap(find.text('Sub 100'));
    // Radio mode closes, then our onClose closes Main.
    await tester.pumpAndSettle();

    // 4. Verify BOTH are closed
    expect(find.text('Sub 100'), findsNothing); // Sub closed
    expect(find.text('Open Sub'), findsNothing); // Main closed
    // Back to home
    expect(find.byIcon(Icons.search), findsOneWidget);
  });

  test('PickerConfig binds to one picker', () {
    final config = PickerConfig<int>(
      itemsLoader: (_, _) async => [1],
      idOf: (i) => i,
      labelOf: (i) => '$i',
    );
    config.bindPicker(onOpen: () {}, onClose: ([_]) {}, isOpen: () => false);
    expect(
      () => config.bindPicker(
        onOpen: () {},
        onClose: ([_]) {},
        isOpen: () => false,
      ),
      throwsA(isA<StateError>()),
    );
  });

  test('copyWith of a bound PickerConfig is unbound', () {
    final config = PickerConfig<int>(
      itemsLoader: (_, _) async => [1],
      idOf: (i) => i,
      labelOf: (i) => '$i',
    );
    var opened = 0;
    config.bindPicker(
      onOpen: () => opened++,
      onClose: ([_]) {},
      isOpen: () => false,
    );
    final copy = config.copyWith();
    copy.bindPicker(onOpen: () {}, onClose: ([_]) {}, isOpen: () => false);
    config.open();
    expect(opened, 1);
    expect(config.isAttached, isTrue);
    expect(copy.isAttached, isTrue);
    expect(config.copyWith().isAttached, isFalse);
  });

  testWidgets('PickerConfig isAttached and isOpen follow the bound picker', (
    tester,
  ) async {
    final config = PickerConfig<int>(
      itemsLoader: (_, _) async => [1],
      idOf: (i) => i,
      labelOf: (i) => '$i',
    );
    expect(config.isAttached, isFalse);

    await tester.pumpWidget(
      MaterialApp(
        home: SearchAnchorPicker<int>(
          config: config,
          initialSelectedIds: const [],
        ),
      ),
    );
    expect(config.isAttached, isTrue);
    expect(config.isOpen, isFalse);

    config.open();
    await tester.pumpAndSettle();
    expect(config.isOpen, isTrue);

    config.close();
    await tester.pumpAndSettle();
    expect(config.isAttached, isTrue);
    expect(config.isOpen, isFalse);
  });

  testWidgets('mounted PickerConfig rejects a second bind', (tester) async {
    final config = PickerConfig<int>(
      itemsLoader: (_, _) async => [1],
      idOf: (i) => i,
      labelOf: (i) => '$i',
    );

    await tester.pumpWidget(
      MaterialApp(
        home: SearchAnchorPicker<int>(
          config: config,
          initialSelectedIds: const [],
        ),
      ),
    );

    expect(
      () => config.bindPicker(
        onOpen: () {},
        onClose: ([_]) {},
        isOpen: () => false,
      ),
      throwsA(isA<StateError>()),
    );
  });

  testWidgets('copyWith lets a second picker bind', (tester) async {
    final config = PickerConfig<int>(
      itemsLoader: (_, _) async => [1],
      idOf: (i) => i,
      labelOf: (i) => '$i',
    );
    final copy = config.copyWith();

    await tester.pumpWidget(
      MaterialApp(
        home: Column(
          children: [
            SearchAnchorPicker<int>(
              config: config,
              initialSelectedIds: const [],
            ),
            SearchAnchorPicker<int>(
              config: copy,
              initialSelectedIds: const [],
            ),
          ],
        ),
      ),
    );

    expect(tester.takeException(), isNull);
    config.open();
    await tester.pumpAndSettle();
    expect(find.text('1'), findsOneWidget);
    copy.open();
    await tester.pumpAndSettle();
    expect(find.text('1'), findsNWidgets(2));
  });

  testWidgets('disposing a picker unbinds its PickerConfig', (tester) async {
    final config = PickerConfig<int>(
      itemsLoader: (_, _) async => [1],
      idOf: (i) => i,
      labelOf: (i) => '$i',
    );

    await tester.pumpWidget(
      MaterialApp(
        home: SearchAnchorPicker<int>(
          config: config,
          initialSelectedIds: const [],
        ),
      ),
    );
    expect(config.isAttached, isTrue);
    await tester.pumpWidget(
      MaterialApp(
        home: SearchAnchorPicker<int>(
          config: config,
          initialSelectedIds: const [],
        ),
      ),
    );

    expect(tester.takeException(), isNull);
    config.open();
    await tester.pumpAndSettle();
    expect(find.text('1'), findsOneWidget);
  });

  test('copyWith keeps omitted nullable configuration', () {
    final listenable = ChangeNotifier();
    final statusListenable = ChangeNotifier();
    String tooltipOf(int item) => '$item';
    Widget iconOf(int item) => const SizedBox();
    int comparator(int a, int b) => a.compareTo(b);
    PickerRelatedListItemStatus statusOf(int item) {
      return const PickerRelatedListItemStatus();
    }

    Widget warningBuilder(BuildContext context, int item) => const SizedBox();
    Future<bool> confirmBuilder(BuildContext context, int item) async => true;

    final config = PickerConfig<int>(
      itemsLoader: (_, _) async => [1],
      idOf: (item) => item,
      labelOf: (item) => '$item',
      searchTermsOf: (item) => ['$item'],
      title: 'People',
      tooltipOf: tooltipOf,
      iconOf: iconOf,
      comparator: comparator,
      listenable: listenable,
      reloadKey: 1,
      relatedListItemStatusOf: statusOf,
      relatedListItemStatusListenable: statusListenable,
      unselectWarningBuilder: warningBuilder,
      unselectConfirmationBuilder: confirmBuilder,
    );

    final kept = config.copyWith(selectedFirst: false);
    expect(kept.selectedFirst, isFalse);
    expect(kept.title, 'People');
    expect(kept.tooltipOf, same(tooltipOf));
    expect(kept.iconOf, same(iconOf));
    expect(kept.comparator, same(comparator));
    expect(kept.listenable, same(listenable));
    expect(kept.reloadKey, 1);
    expect(kept.relatedListItemStatusOf, same(statusOf));
    expect(kept.relatedListItemStatusListenable, same(statusListenable));
    expect(kept.rebuildListenable, same(statusListenable));
    expect(kept.unselectWarningBuilder, same(warningBuilder));
    expect(kept.unselectConfirmationBuilder, same(confirmBuilder));
  });

  test('copyWith can clear nullable configuration', () {
    final config = PickerConfig<int>(
      itemsLoader: (_, _) async => [1],
      idOf: (item) => item,
      labelOf: (item) => '$item',
      searchTermsOf: (item) => ['$item'],
      title: 'People',
      tooltipOf: (item) => '$item',
      iconOf: (item) => const SizedBox(),
      comparator: (a, b) => a.compareTo(b),
      listenable: ChangeNotifier(),
      reloadKey: 1,
      relatedListItemStatusOf: (_) => const PickerRelatedListItemStatus(),
      relatedListItemStatusListenable: ChangeNotifier(),
      unselectWarningBuilder: (context, item) => const SizedBox(),
      unselectConfirmationBuilder: (context, item) async => true,
    );

    final cleared = config.copyWith(
      title: null,
      tooltipOf: null,
      iconOf: null,
      comparator: null,
      listenable: null,
      reloadKey: null,
      relatedListItemStatusOf: null,
      relatedListItemStatusListenable: null,
      unselectWarningBuilder: null,
      unselectConfirmationBuilder: null,
    );

    expect(cleared.title, isNull);
    expect(cleared.tooltipOf, isNull);
    expect(cleared.iconOf, isNull);
    expect(cleared.comparator, isNull);
    expect(cleared.listenable, isNull);
    expect(cleared.reloadKey, isNull);
    expect(cleared.relatedListItemStatusOf, isNull);
    expect(cleared.relatedListItemStatusListenable, isNull);
    expect(cleared.rebuildListenable, isNull);
    expect(cleared.unselectWarningBuilder, isNull);
    expect(cleared.unselectConfirmationBuilder, isNull);
  });

  test(
    'copyWith(rebuildListenable: null) clears related-list status listenable',
    () {
      final config = PickerConfig<int>(
        itemsLoader: (_, _) async => [1],
        idOf: (item) => item,
        labelOf: (item) => '$item',
        searchTermsOf: (item) => ['$item'],
        relatedListItemStatusListenable: ChangeNotifier(),
      );

      final cleared = config.copyWith(rebuildListenable: null);
      expect(cleared.relatedListItemStatusListenable, isNull);
      expect(cleared.rebuildListenable, isNull);
    },
  );
}
