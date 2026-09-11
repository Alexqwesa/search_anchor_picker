// ignore_for_file: unnecessary_underscores

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:search_anchor_picker/search_anchor_picker.dart';

Rect _searchAnchorStyleRect({
  required Rect anchorRect,
  required Size screenSize,
  required double minWidth,
  required double maxHeight,
  required TextDirection textDirection,
}) {
  final viewWidth = anchorRect.width.clamp(
    minWidth < screenSize.width ? minWidth : screenSize.width,
    screenSize.width,
  );
  final minHeight = maxHeight < 240 ? maxHeight : 240.0;
  final viewHeight = (screenSize.height * 2 / 3).clamp(minHeight, maxHeight);

  switch (textDirection) {
    case TextDirection.ltr:
      var topLeft = anchorRect.topLeft;
      if (screenSize.width - anchorRect.left < viewWidth) {
        topLeft = Offset(screenSize.width - viewWidth, topLeft.dy);
      }
      if (screenSize.height - anchorRect.top < viewHeight) {
        topLeft = Offset(topLeft.dx, screenSize.height - viewHeight);
      }
      return topLeft & Size(viewWidth, viewHeight);
    case TextDirection.rtl:
      var topLeft = Offset(
        (anchorRect.right - viewWidth).clamp(0.0, double.infinity),
        anchorRect.top,
      );
      if (anchorRect.right < viewWidth) {
        topLeft = Offset(0.0, topLeft.dy);
      }
      if (screenSize.height - anchorRect.top < viewHeight) {
        topLeft = Offset(topLeft.dx, screenSize.height - viewHeight);
      }
      return topLeft & Size(viewWidth, viewHeight);
  }
}

Offset _resolvedOffsetForTest({
  required Rect baseRect,
  required Size screenSize,
  required Offset requestedOffset,
}) {
  final dx =
      baseRect.left + requestedOffset.dx < 0 ||
          baseRect.right + requestedOffset.dx > screenSize.width
      ? 0.0
      : requestedOffset.dx;
  final dy =
      baseRect.top + requestedOffset.dy < 0 ||
          baseRect.bottom + requestedOffset.dy > screenSize.height
      ? 0.0
      : requestedOffset.dy;
  return Offset(dx, dy);
}

void main() {
  testWidgets('SubPickerTile syncs removals but not additions', (tester) async {
    final parentPending = ValueNotifier<Set<int>>({1, 2, 3});
    // Mock parent actions
    final parentActions = PickerActions<int>(
      pendingN: parentPending,
      idOf: (i) => i,
      close: ([_]) {},
      mode: PickerMode.multi,
      getKey: (_) => GlobalKey(),
      refresh: () {},
      loadedIds: () => const [1, 2, 3],
      filteredIds: () => const [1, 2, 3],
      recordDelta: (_, _) {},
    );

    int finishCallCount = 0;
    List<int> lastAdded = [];
    List<int> lastRemoved = [];

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SubPickerTile<int>(
            title: 'Sub Picker',
            config: PickerConfig(
              loadItems: (_) async => [1, 2, 3, 4, 5],
              idOf: (i) => i,
              labelOf: (i) => '$i',
              searchTermsOf: (_) => [],
            ),
            initialSelectedIds: const [
              1,
              2,
            ], // 1, 2 are selected in sub-picker (present in main)
            parentActions: parentActions,
            onFinish: ({required added, required removed}) async {
              finishCallCount++;
              lastAdded = added;
              lastRemoved = removed;
            },
          ),
        ),
      ),
    );

    // Open the sub-picker
    await tester.tap(find.text('Sub Picker'));
    await tester.pumpAndSettle();

    // Verify initial state in overlay: 1, 2 selected.
    // We want to ADD 4 and REMOVE 2.
    // 4 is NOT in parentPending.
    // 2 IS in parentPending.

    // Tap 4 (select it) -> added
    await tester.tap(find.text('4'));
    await tester.pump();

    // Tap 2 (deselect it) -> removed
    await tester.tap(find.text('2'));
    await tester.pump();

    // Close the picker (back button or close)
    // Finding the back button in SearchAnchor/SearchController view is tricky as it's built-in.
    // We can simulate close by finding the back button.
    await tester.tap(find.byIcon(Icons.arrow_back));
    await tester.pumpAndSettle();

    expect(finishCallCount, 1);
    expect(lastAdded, [4]);
    expect(lastRemoved, [2]);

    // CHECK PARENT ACTIONS BEHAVIOR
    // 1. Removed item (2) should be removed from parentPending.
    expect(
      parentPending.value.contains(2),
      false,
      reason: 'Removed item 2 should be removed from parent',
    );

    // 2. Added item (4) should NOT be added to parentPending (per "default they added as not selected").
    expect(
      parentPending.value.contains(4),
      false,
      reason: 'Added item 4 should NOT be auto-selected in parent',
    );

    // 3. Unchanged item (1) should remain in parentPending
    expect(parentPending.value.contains(1), true);
    expect(
      parentPending.value.contains(3),
      true,
    ); // 3 was not involved in sub-picker
  });

  testWidgets('SubPickerTile uses triggerBuilder', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SubPickerTile<int>(
            title: 'I am ignored',
            config: PickerConfig(
              loadItems: (_) async => [1],
              idOf: (i) => i,
              labelOf: (i) => '$i',
              searchTermsOf: (_) => [],
            ),
            initialSelectedIds: const [],
            triggerBuilder: (context, open, tick) {
              return ElevatedButton(
                onPressed: open,
                child: Text('Custom Trigger $tick'),
              );
            },
          ),
        ),
      ),
    );

    expect(find.text('I am ignored'), findsNothing);
    expect(find.text('Custom Trigger 0'), findsOneWidget);

    await tester.tap(find.text('Custom Trigger 0'));
    await tester.pumpAndSettle();

    expect(find.text('1'), findsOneWidget);
  });

  testWidgets('SubPickerTile uses itemBuilder', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SubPickerTile<int>(
            title: 'Sub Picker',
            config: PickerConfig(
              loadItems: (_) async => [1, 2],
              idOf: (i) => i,
              labelOf: (i) => '$i',
              searchTermsOf: (_) => [],
            ),
            initialSelectedIds: const [],
            itemBuilder: (context, item, isSelected, onToggle) {
              return ListTile(
                title: Text('Custom Item $item'),
                selected: isSelected,
                onTap: onToggle,
              );
            },
          ),
        ),
      ),
    );

    await tester.tap(find.text('Sub Picker'));
    await tester.pumpAndSettle();

    expect(find.text('Custom Item 1'), findsOneWidget);
    expect(find.text('Custom Item 2'), findsOneWidget);

    await tester.tap(find.text('Custom Item 1'));
    await tester.pump();
  });

  testWidgets('SubPickerTile applies animated menuOffset to submenu position', (
    tester,
  ) async {
    Future<void> pumpSubPicker(Offset menuOffset) {
      return tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Align(
              alignment: Alignment.topLeft,
              child: SizedBox(
                width: 160,
                child: SubPickerTile<int>(
                  title: 'Sub Picker',
                  isFullScreen: false,
                  menuOffset: menuOffset,
                  config: PickerConfig(
                    loadItems: (_) async => [1, 2],
                    idOf: (i) => i,
                    labelOf: (i) => '$i',
                    searchTermsOf: (_) => [],
                  ),
                  initialSelectedIds: const [],
                ),
              ),
            ),
          ),
        ),
      );
    }

    await pumpSubPicker(Offset.zero);
    await tester.tap(find.text('Sub Picker'));
    await tester.pumpAndSettle();

    final withoutOffsetPosition = tester.getTopLeft(find.text('1').last);

    await tester.tap(find.byIcon(Icons.arrow_back));
    await tester.pumpAndSettle();

    const menuOffset = Offset(32, 18);
    await pumpSubPicker(menuOffset);
    await tester.tap(find.text('Sub Picker'));
    await tester.pumpAndSettle();

    final withOffsetPosition = tester.getTopLeft(find.text('1').last);

    expect(
      withOffsetPosition.dx,
      moreOrLessEquals(withoutOffsetPosition.dx + menuOffset.dx, epsilon: 1),
    );
    expect(
      withOffsetPosition.dy,
      moreOrLessEquals(withoutOffsetPosition.dy + menuOffset.dy, epsilon: 1),
    );
  });

  testWidgets('SubPickerTile opens with offset without follower-layer errors', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SubPickerTile<int>(
            title: 'Sub Picker',
            isFullScreen: false,
            menuOffset: const Offset(40, 40),
            config: PickerConfig(
              loadItems: (_) async => [1, 2],
              idOf: (i) => i,
              labelOf: (i) => '$i',
              searchTermsOf: (i) => ['$i'],
            ),
            initialSelectedIds: const [],
          ),
        ),
      ),
    );

    await tester.tap(find.text('Sub Picker'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 150));

    expect(find.text('1'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('SubPickerTile search field is editable and filters items', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SubPickerTile<int>(
            title: 'Sub Picker',
            isFullScreen: false,
            menuOffset: const Offset(24, 12),
            config: PickerConfig(
              loadItems: (_) async => [1, 2],
              idOf: (i) => i,
              labelOf: (i) => 'Item $i',
              searchTermsOf: (i) => ['Item $i'],
            ),
            initialSelectedIds: const [],
          ),
        ),
      ),
    );

    await tester.tap(find.text('Sub Picker'));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField), 'Item 2');
    await tester.pumpAndSettle();

    expect(find.text('Item 1'), findsNothing);
    expect(
      find.ancestor(
        of: find.text('Item 2').last,
        matching: find.byType(CheckboxListTile),
      ),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('SubPickerTile clear action restores search focus', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData(platform: TargetPlatform.windows),
        home: Scaffold(
          body: SubPickerTile<int>(
            title: 'Sub Picker',
            isFullScreen: false,
            config: PickerConfig(
              loadItems: (_) async => [1, 2],
              idOf: (i) => i,
              labelOf: (i) => 'Item $i',
              searchTermsOf: (i) => ['Item $i'],
            ),
            initialSelectedIds: const [],
          ),
        ),
      ),
    );

    await tester.tap(find.text('Sub Picker'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(SearchBar), 'Item');
    await tester.pumpAndSettle();

    final searchBar = tester.widget<SearchBar>(find.byType(SearchBar));
    searchBar.focusNode!.unfocus();
    await tester.pump();
    tester
        .widget<IconButton>(
          find.ancestor(
            of: find.byIcon(Icons.close),
            matching: find.byType(IconButton),
          ),
        )
        .onPressed!();
    await tester.pump();

    expect(searchBar.focusNode!.hasFocus, isTrue);
    tester.testTextInput.enterText('Item 1');
    await tester.pump();
    expect(
      find.ancestor(
        of: find.text('Item 1').last,
        matching: find.byType(CheckboxListTile),
      ),
      findsOneWidget,
    );
    expect(
      find.ancestor(
        of: find.text('Item 2'),
        matching: find.byType(CheckboxListTile),
      ),
      findsNothing,
    );
  });

  testWidgets('Escape closes only the topmost open menu', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SearchAnchorPicker<int>(
            config: PickerConfig(
              loadItems: (_) async => [1, 2],
              idOf: (i) => i,
              labelOf: (i) => 'Parent $i',
              searchTermsOf: (i) => ['Parent $i'],
            ),
            initialSelectedIds: const [],
            triggerBuilder: (_, open, __) => ElevatedButton(
              onPressed: open,
              child: const Text('Open Parent'),
            ),
            headerBuilder: (context, actions, allItems) => [
              SubPickerTile<int>(
                title: 'Open Child',
                config: PickerConfig(
                  loadItems: (_) async => [10, 20],
                  idOf: (i) => i,
                  labelOf: (i) => 'Child $i',
                  searchTermsOf: (i) => ['Child $i'],
                ),
                initialSelectedIds: const [],
              ),
            ],
          ),
        ),
      ),
    );

    await tester.tap(find.text('Open Parent'));
    await tester.pumpAndSettle();
    expect(find.text('Parent 1'), findsOneWidget);

    await tester.tap(find.text('Open Child'));
    await tester.pumpAndSettle();
    expect(find.text('Child 10'), findsOneWidget);

    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pumpAndSettle();

    expect(find.text('Child 10'), findsNothing);
    expect(find.text('Parent 1'), findsOneWidget);

    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pumpAndSettle();

    expect(find.text('Parent 1'), findsNothing);
  });

  testWidgets('system back closes only the topmost open menu', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SearchAnchorPicker<int>(
            config: PickerConfig(
              loadItems: (_) async => [1],
              idOf: (item) => item,
              labelOf: (item) => 'Parent $item',
              searchTermsOf: (_) => const [],
            ),
            initialSelectedIds: const [],
            headerBuilder: (context, actions, items) => [
              SubPickerTile<int>(
                title: 'Open Child',
                config: PickerConfig(
                  loadItems: (_) async => [10],
                  idOf: (item) => item,
                  labelOf: (item) => 'Child $item',
                  searchTermsOf: (_) => const [],
                ),
                initialSelectedIds: const [],
              ),
            ],
          ),
        ),
      ),
    );

    await tester.tap(find.byIcon(Icons.search));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Open Child'));
    await tester.pumpAndSettle();

    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(find.text('Child 10'), findsNothing);
    expect(find.text('Parent 1'), findsOneWidget);

    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(find.text('Parent 1'), findsNothing);
    expect(find.byIcon(Icons.search), findsOneWidget);
  });

  testWidgets('popup opening animation stays stable before settle', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 56,
            height: 40,
            child: SearchAnchorPicker<int>(
              isFullScreen: false,
              minWidth: 320,
              config: PickerConfig(
                loadItems: (_) async => [1, 2],
                idOf: (i) => i,
                labelOf: (i) => 'Item $i',
                searchTermsOf: (i) => ['Item $i'],
              ),
              initialSelectedIds: const [],
              triggerBuilder: (_, open, __) =>
                  ElevatedButton(onPressed: open, child: const Text('Open')),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Open'));
    await tester.pump();
    expect(find.byType(SearchBar), findsOneWidget);
    expect(tester.takeException(), isNull);

    await tester.pumpAndSettle();
    expect(find.byType(SearchBar), findsOneWidget);
  });

  testWidgets(
    'SearchAnchorPicker matches SearchAnchor popup placement before offset',
    (tester) async {
      final triggerKey = GlobalKey();
      const screenSize = Size(800, 600);
      const minWidth = 320.0;
      const maxHeight = 420.0;
      const menuOffset = Offset(40, 12);

      tester.view.physicalSize = screenSize;
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Align(
              alignment: Alignment.bottomRight,
              child: SizedBox(
                key: triggerKey,
                width: 56,
                height: 40,
                child: SearchAnchorPicker<int>(
                  isFullScreen: false,
                  minWidth: minWidth,
                  maxHeight: maxHeight,
                  menuOffset: menuOffset,
                  config: PickerConfig(
                    loadItems: (_) async => [1, 2],
                    idOf: (i) => i,
                    labelOf: (i) => '$i',
                    searchTermsOf: (i) => ['$i'],
                  ),
                  initialSelectedIds: const [],
                  triggerBuilder: (_, open, __) => ElevatedButton(
                    onPressed: open,
                    child: const Text('Open'),
                  ),
                ),
              ),
            ),
          ),
        ),
      );

      final triggerRect = tester.getRect(find.byKey(triggerKey));

      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      final searchBarRect = tester.getRect(find.byType(SearchBar).last);
      final expectedBaseRect = _searchAnchorStyleRect(
        anchorRect: triggerRect,
        screenSize: screenSize,
        minWidth: minWidth,
        maxHeight: maxHeight,
        textDirection: TextDirection.ltr,
      );
      final expectedOffset = _resolvedOffsetForTest(
        baseRect: expectedBaseRect,
        screenSize: screenSize,
        requestedOffset: menuOffset,
      );

      expect(
        searchBarRect.left,
        moreOrLessEquals(expectedBaseRect.left + expectedOffset.dx, epsilon: 1),
      );
      expect(
        searchBarRect.top,
        moreOrLessEquals(expectedBaseRect.top + expectedOffset.dy, epsilon: 1),
      );
      expect(
        searchBarRect.width,
        moreOrLessEquals(expectedBaseRect.width, epsilon: 1),
      );
    },
  );

  testWidgets('menuOffset applies only on axes with enough available space', (
    tester,
  ) async {
    final triggerKey = GlobalKey();
    const screenSize = Size(800, 600);
    const minWidth = 320.0;
    const maxHeight = 420.0;
    const menuOffset = Offset(40, 12);

    tester.view.physicalSize = screenSize;
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Align(
            alignment: Alignment.topLeft,
            child: SizedBox(
              key: triggerKey,
              width: 56,
              height: 40,
              child: SearchAnchorPicker<int>(
                isFullScreen: false,
                minWidth: minWidth,
                maxHeight: maxHeight,
                menuOffset: menuOffset,
                config: PickerConfig(
                  loadItems: (_) async => [1, 2],
                  idOf: (i) => i,
                  labelOf: (i) => '$i',
                  searchTermsOf: (i) => ['$i'],
                ),
                initialSelectedIds: const [],
                triggerBuilder: (_, open, __) =>
                    ElevatedButton(onPressed: open, child: const Text('Open')),
              ),
            ),
          ),
        ),
      ),
    );

    final triggerRect = tester.getRect(find.byKey(triggerKey));

    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();

    final searchBarRect = tester.getRect(find.byType(SearchBar).last);
    final expectedBaseRect = _searchAnchorStyleRect(
      anchorRect: triggerRect,
      screenSize: screenSize,
      minWidth: minWidth,
      maxHeight: maxHeight,
      textDirection: TextDirection.ltr,
    );

    expect(
      searchBarRect.left,
      moreOrLessEquals(expectedBaseRect.left + menuOffset.dx, epsilon: 1),
    );
    expect(
      searchBarRect.top,
      moreOrLessEquals(expectedBaseRect.top + menuOffset.dy, epsilon: 1),
    );
  });
}
