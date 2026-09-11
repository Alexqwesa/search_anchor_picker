import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:search_anchor_picker/search_anchor_picker.dart';

PickerConfig<int> _config({List<int> items = const [1, 2]}) {
  return PickerConfig<int>(
    loadItems: (_) async => items,
    idOf: (item) => item,
    labelOf: (item) => 'Item $item',
    searchTermsOf: (item) => ['Item $item'],
  );
}

PickerConfig<int> _configFrom(Future<List<int>> Function() load) {
  return PickerConfig<int>(
    loadItems: (_) => load(),
    idOf: (item) => item,
    labelOf: (item) => 'Item $item',
    searchTermsOf: (item) => ['Item $item'],
  );
}

void main() {
  testWidgets('default clear action restores search focus', (tester) async {
    final controller = SearchController();
    addTearDown(controller.dispose);

    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData(platform: TargetPlatform.windows),
        home: SearchAnchorPicker<int>(
          config: _config(),
          initialSelectedIds: const [],
          searchController: controller,
        ),
      ),
    );

    await tester.tap(find.byIcon(Icons.search));
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

    expect(controller.text, isEmpty);
    expect(searchBar.focusNode!.hasFocus, isTrue);

    tester.testTextInput.enterText('Item 2');
    await tester.pump();
    expect(controller.text, 'Item 2');
  });

  testWidgets('popup builders stay lazy and replace only their regions', (
    tester,
  ) async {
    var searchBuilds = 0;
    var loadingBuilds = 0;
    final load = Completer<List<int>>();

    await tester.pumpWidget(
      MaterialApp(
        home: SearchAnchorPicker<int>(
          config: _configFrom(() => load.future),
          initialSelectedIds: const [],
          searchFieldBuilder: (context, controller, close) {
            searchBuilds++;
            return TextButton(
              onPressed: close,
              child: const Text('Custom search'),
            );
          },
          loadingBuilder: (context) {
            loadingBuilds++;
            return const Text('Custom loading');
          },
          itemBuilder: (context, item, selected, toggle) =>
              ListTile(onTap: toggle, title: Text('Custom item $item')),
          resultsBuilder: (context, controller, children) =>
              ListView(controller: controller, children: children),
        ),
      ),
    );

    expect(searchBuilds, 0);
    expect(loadingBuilds, 0);
    expect(find.byType(DefaultPickerViewSurface), findsNothing);

    await tester.tap(find.byIcon(Icons.search));
    await tester.pump();
    expect(searchBuilds, greaterThan(0));
    expect(loadingBuilds, greaterThan(0));
    expect(find.text('Custom search'), findsOneWidget);
    expect(find.byType(SearchBar), findsNothing);

    load.complete([1, 2]);
    await tester.pumpAndSettle();
    expect(find.text('Custom item 1'), findsOneWidget);
    expect(find.byType(CheckboxListTile), findsNothing);
  });

  testWidgets('SearchViewTheme values style the default popup', (tester) async {
    const shape = RoundedRectangleBorder(
      borderRadius: BorderRadius.all(Radius.circular(9)),
    );
    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData(
          platform: TargetPlatform.windows,
          searchViewTheme: const SearchViewThemeData(
            backgroundColor: Colors.red,
            elevation: 11,
            shape: shape,
            dividerColor: Colors.green,
            constraints: BoxConstraints(minWidth: 420, minHeight: 300),
            barPadding: EdgeInsets.symmetric(horizontal: 17),
          ),
        ),
        home: Align(
          alignment: Alignment.topLeft,
          child: SearchAnchorPicker<int>(
            config: _config(),
            initialSelectedIds: const [],
          ),
        ),
      ),
    );

    await tester.tap(find.byIcon(Icons.search));
    await tester.pumpAndSettle();
    final surface = tester.widget<DefaultPickerViewSurface>(
      find.byType(DefaultPickerViewSurface),
    );
    expect(surface.style.backgroundColor, Colors.red);
    expect(surface.style.elevation, 11);
    expect(surface.style.shape, shape);
    expect(surface.style.dividerColor, Colors.green);
    expect(
      surface.style.barPadding,
      const EdgeInsets.symmetric(horizontal: 17),
    );
    expect(tester.getSize(find.byType(DefaultPickerViewSurface)).width, 420);
  });

  testWidgets('empty, composed-view, and surface builders stay scoped', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: SearchAnchorPicker<int>(
          config: _config(items: const []),
          initialSelectedIds: const [],
          emptyBuilder: (context, query) => const Text('Custom empty'),
          viewBuilder: (context, parts) => Column(
            children: [
              parts.searchField,
              Expanded(child: parts.results),
            ],
          ),
          viewSurfaceBuilder: (context, child, fullScreen) => ColoredBox(
            key: const Key('custom-surface'),
            color: Colors.orange,
            child: child,
          ),
        ),
      ),
    );

    await tester.tap(find.byIcon(Icons.search));
    await tester.pumpAndSettle();
    expect(find.text('Custom empty'), findsOneWidget);
    expect(find.byKey(const Key('custom-surface')), findsOneWidget);
    expect(find.byType(DefaultPickerViewSurface), findsNothing);
    expect(find.byType(SearchBar), findsOneWidget);
  });

  testWidgets('explicit view properties override SearchViewTheme', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData(
          platform: TargetPlatform.windows,
          searchViewTheme: const SearchViewThemeData(
            backgroundColor: Colors.red,
            elevation: 11,
            constraints: BoxConstraints(minWidth: 420),
          ),
        ),
        home: Align(
          alignment: Alignment.topLeft,
          child: SearchAnchorPicker<int>(
            config: _config(),
            initialSelectedIds: const [],
            viewBackgroundColor: Colors.blue,
            viewElevation: 3,
            viewConstraints: const BoxConstraints(
              minWidth: 380,
              minHeight: 260,
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.byIcon(Icons.search));
    await tester.pumpAndSettle();
    final surface = tester.widget<DefaultPickerViewSurface>(
      find.byType(DefaultPickerViewSurface),
    );
    expect(surface.style.backgroundColor, Colors.blue);
    expect(surface.style.elevation, 3);
    expect(tester.getSize(find.byType(DefaultPickerViewSurface)).width, 380);
  });

  testWidgets('mobile defaults full screen and ignores menuOffset', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(800, 600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData(platform: TargetPlatform.android),
        home: Align(
          alignment: Alignment.bottomRight,
          child: SearchAnchorPicker<int>(
            config: _config(),
            initialSelectedIds: const [],
            menuOffset: const Offset(100, 100),
          ),
        ),
      ),
    );

    await tester.tap(find.byIcon(Icons.search));
    await tester.pumpAndSettle();
    expect(
      tester.getRect(find.byType(DefaultPickerViewSurface)),
      const Offset(0, 0) & const Size(800, 600),
    );
  });

  testWidgets('desktop defaults to anchored 360 wide popup', (tester) async {
    tester.view.physicalSize = const Size(800, 600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData(platform: TargetPlatform.windows),
        home: Align(
          alignment: Alignment.topLeft,
          child: SearchAnchorPicker<int>(
            config: _config(),
            initialSelectedIds: const [],
          ),
        ),
      ),
    );
    await tester.tap(find.byIcon(Icons.search));
    await tester.pumpAndSettle();
    final rect = tester.getRect(find.byType(DefaultPickerViewSurface));
    expect(rect.width, 360);
    expect(rect.height, 400);
    expect(rect, isNot(const Offset(0, 0) & const Size(800, 600)));
  });
}
