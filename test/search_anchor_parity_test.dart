import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:search_anchor_picker/search_anchor_picker.dart';

PickerConfig<int> _config({List<int> items = const [1, 2]}) {
  return PickerConfig<int>(
    itemsLoader: (_, _) async => items,
    idOf: (item) => item,
    labelOf: (item) => 'Item $item',
    searchTermsOf: (item) => ['Item $item'],
  );
}

PickerConfig<int> _configFrom(Future<List<int>> Function() load) {
  return PickerConfig<int>(
    itemsLoader: (_, _) => load(),
    idOf: (item) => item,
    labelOf: (item) => 'Item $item',
    searchTermsOf: (item) => ['Item $item'],
  );
}

void main() {
  testWidgets('default clear action restores search focus', (tester) async {
    final controller = TextEditingController();
    addTearDown(controller.dispose);

    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData(platform: TargetPlatform.windows),
        home: SearchAnchorPicker<int>(
          config: _config(),
          initialSelectedIds: const [],
          queryController: controller,
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
          itemBuilder:
              (context, item, selected, relatedListItemStatus, source, toggle) =>
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
          emptyText: 'Ignored default text',
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
    expect(find.text('Ignored default text'), findsNothing);
    expect(find.byKey(const Key('custom-surface')), findsOneWidget);
    expect(find.byType(DefaultPickerViewSurface), findsNothing);
    expect(find.byType(SearchBar), findsOneWidget);
  });

  testWidgets('default empty view uses built-in locale messages', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => Localizations.override(
            context: context,
            locale: const Locale('es'),
            child: const Column(
              children: [
                DefaultPickerEmpty(query: ''),
                DefaultPickerEmpty(query: 'missing'),
              ],
            ),
          ),
        ),
      ),
    );

    expect(find.text('No hay elementos'), findsOneWidget);
    expect(find.text('No hay resultados'), findsOneWidget);
  });

  testWidgets('default retry and unselect feedback use locale messages', (
    tester,
  ) async {
    var retryCalls = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => Localizations.override(
            context: context,
            locale: const Locale('es'),
            child: Builder(
              builder: (localizedContext) => Column(
                children: [
                  DefaultPickerError(retry: () => retryCalls++),
                  const DefaultPickerUnselectWarning(label: 'Cuenta'),
                  TextButton(
                    onPressed: () {
                      unawaited(
                        showDefaultPickerUnselectConfirmation(
                          localizedContext,
                          label: 'Cuenta',
                        ),
                      );
                    },
                    child: const Text('Open confirmation'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );

    expect(find.text('Reintentar'), findsOneWidget);
    expect(find.text('Cuenta está actualmente en uso.'), findsOneWidget);
    await tester.tap(find.text('Reintentar'));
    expect(retryCalls, 1);

    await tester.tap(find.text('Open confirmation'));
    await tester.pump();
    expect(find.text('¿Quitar elemento?'), findsOneWidget);
    expect(
      find.text(
        'Cuenta está actualmente en uso. '
        'Quitar este elemento puede afectar a otros datos.',
      ),
      findsOneWidget,
    );
    expect(find.text('Quitar'), findsOneWidget);

    await tester.tap(find.text('Quitar'));
    await tester.pumpAndSettle();
  });

  testWidgets('empty text overrides flow through the picker', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: SearchAnchorPicker<int>(
          config: _config(items: const []),
          initialSelectedIds: const [],
          emptyText: 'Nothing loaded',
          noResultsText: 'Nothing matched',
        ),
      ),
    );

    await tester.tap(find.byIcon(Icons.search));
    await tester.pumpAndSettle();
    expect(find.text('Nothing loaded'), findsOneWidget);

    await tester.enterText(find.byType(SearchBar), 'missing');
    await tester.pumpAndSettle();
    expect(find.text('Nothing loaded'), findsNothing);
    expect(find.text('Nothing matched'), findsOneWidget);
  });

  testWidgets('default search field reloads itemsLoader with query', (
    tester,
  ) async {
    final queries = <String>[];
    await tester.pumpWidget(
      MaterialApp(
        home: SearchAnchorPicker<int>(
          config: PickerConfig<int>(
            searchMode: PickerSearchMode.remote,
            itemsLoader: (_, query) async {
              queries.add(query);
              if (query.isEmpty) return [1, 2];
              return [
                for (final id in [1, 2])
                  if ('Item $id'.toLowerCase().contains(query.toLowerCase()))
                    id,
              ];
            },
            idOf: (item) => item,
            labelOf: (item) => 'Item $item',
          ),
          initialSelectedIds: const [],
        ),
      ),
    );
    await tester.tap(find.byIcon(Icons.search));
    await tester.pumpAndSettle();
    expect(queries, ['']);
    expect(find.text('Item 1'), findsOneWidget);

    await tester.enterText(find.byType(SearchBar), '2');
    await tester.pumpAndSettle();
    expect(queries, ['', '2']);
    expect(find.text('Item 1'), findsNothing);
    expect(find.text('Item 2'), findsOneWidget);

    await tester.tap(find.byIcon(Icons.close));
    await tester.pumpAndSettle();
    expect(queries, ['', '2', '']);
    expect(find.text('Item 1'), findsOneWidget);
    expect(find.text('Item 2'), findsOneWidget);
    expect(find.byType(SearchBar), findsOneWidget);
  });

  testWidgets('custom search field reloads from query controller text', (
    tester,
  ) async {
    final queries = <String>[];
    final changed = <String>[];
    await tester.pumpWidget(
      MaterialApp(
        home: SearchAnchorPicker<int>(
          config: PickerConfig<int>(
            searchMode: PickerSearchMode.remote,
            itemsLoader: (_, query) async {
              queries.add(query);
              return query.isEmpty ? [1] : [2];
            },
            idOf: (item) => item,
            labelOf: (item) => 'Item $item',
          ),
          initialSelectedIds: const [],
          onQueryChanged: changed.add,
          searchFieldBuilder: (context, controller, close) {
            return Material(
              child: TextField(controller: controller),
            );
          },
        ),
      ),
    );
    await tester.tap(find.byIcon(Icons.search));
    await tester.pumpAndSettle();
    expect(queries, ['']);

    await tester.enterText(find.byType(TextField), '2');
    await tester.pumpAndSettle();
    expect(changed, ['2']);
    expect(queries, ['', '2']);
    expect(find.text('Item 2'), findsOneWidget);
  });

  testWidgets(
    'programmatic query text reloads; selection does not',
    (tester) async {
      final queries = <String>[];
      final changed = <String>[];
      final controller = TextEditingController();
      addTearDown(controller.dispose);

      await tester.pumpWidget(
        MaterialApp(
          home: SearchAnchorPicker<int>(
            queryController: controller,
            config: PickerConfig<int>(
              searchMode: PickerSearchMode.remote,
              itemsLoader: (_, query) async {
                queries.add(query);
                return query.isEmpty ? [1] : [2];
              },
              idOf: (item) => item,
              labelOf: (item) => 'Item $item',
            ),
            initialSelectedIds: const [],
            onQueryChanged: changed.add,
          ),
        ),
      );
      await tester.tap(find.byIcon(Icons.search));
      await tester.pumpAndSettle();
      expect(queries, ['']);

      controller.selection = const TextSelection.collapsed(offset: 0);
      await tester.pump();
      expect(queries, ['']);
      expect(changed, isEmpty);

      controller.text = '2';
      await tester.pumpAndSettle();
      expect(changed, ['2']);
      expect(queries, ['', '2']);
      expect(find.text('Item 2'), findsOneWidget);

      await tester.tap(find.byTooltip('Back'));
      await tester.pumpAndSettle();
      final afterClose = queries.length;
      controller.text = 'zzz';
      await tester.pump();
      expect(queries, hasLength(afterClose));
    },
  );

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
    var closeCalls = 0;
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
            viewOnClose: () => closeCalls++,
          ),
        ),
      ),
    );

    await tester.tap(find.byIcon(Icons.search));
    await tester.pumpAndSettle();
    expect(
      tester.getRect(find.byType(DefaultPickerViewSurface)),
      Offset.zero & const Size(800, 600),
    );

    final searchFieldContext = tester.element(
      find.byType(DefaultPickerSearchField),
    );
    final backTooltip = MaterialLocalizations.of(
      searchFieldContext,
    ).backButtonTooltip;
    expect(find.byTooltip(backTooltip), findsOneWidget);

    await tester.tap(find.byTooltip(backTooltip));
    await tester.pumpAndSettle();
    expect(find.byType(DefaultPickerViewSurface), findsNothing);
    expect(closeCalls, 1);
  });

  testWidgets('desktop defaults to anchored 360 wide popup', (tester) async {
    var closeCalls = 0;
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
            viewOnClose: () => closeCalls++,
          ),
        ),
      ),
    );
    await tester.tap(find.byIcon(Icons.search));
    await tester.pumpAndSettle();
    final rect = tester.getRect(find.byType(DefaultPickerViewSurface));
    expect(rect.width, 360);
    expect(rect.height, 400);
    expect(rect, isNot(Offset.zero & const Size(800, 600)));

    await tester.tapAt(const Offset(790, 590));
    await tester.pumpAndSettle();
    expect(find.byType(DefaultPickerViewSurface), findsNothing);
    expect(closeCalls, 1);
  });
}
