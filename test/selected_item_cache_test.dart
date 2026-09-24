import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:search_anchor_picker/search_anchor_picker.dart';

class _Person {
  const _Person(this.id, this.name);
  final int id;
  final String name;
}

const _ada = _Person(1, 'Ada');
const _alan = _Person(2, 'Alan');
const _carlos = _Person(9, 'Carlos');

PickerConfig<_Person> _config(List<_Person> loaded) {
  return PickerConfig<_Person>(
    itemsLoader: (_, _) async => loaded,
    idOf: (p) => p.id,
    labelOf: (p) => p.name,
    searchTermsOf: (p) => [p.name],
  );
}

void main() {
  testWidgets('without cache, missing selected IDs have no row', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: SearchAnchorPicker<_Person>(
          config: _config([_ada, _alan]),
          initialSelectedIds: const [1, 9],
        ),
      ),
    );
    await tester.tap(find.byIcon(Icons.search));
    await tester.pumpAndSettle();
    expect(find.text('Selected'), findsNothing);
    expect(find.text('Carlos'), findsNothing);
    expect(find.text('Ada'), findsOneWidget);
  });

  testWidgets('cache shows selected IDs missing from the loader', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: SearchAnchorPicker<_Person>(
          config: _config([_ada, _alan]),
          initialSelectedIds: const [1, 9],
          initialSelectedItemCache: const [_ada, _carlos],
        ),
      ),
    );
    await tester.tap(find.byIcon(Icons.search));
    await tester.pumpAndSettle();
    expect(find.text('Selected'), findsOneWidget);
    expect(find.text('Results'), findsOneWidget);
    expect(find.text('Carlos'), findsOneWidget);
    expect(find.text('Ada'), findsOneWidget);
  });

  testWidgets('search filters Results only', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData(platform: TargetPlatform.windows),
        home: SearchAnchorPicker<_Person>(
          config: _config([_ada, _alan]),
          initialSelectedIds: const [9],
          initialSelectedItemCache: const [_carlos],
        ),
      ),
    );
    await tester.tap(find.byIcon(Icons.search));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(SearchBar), 'Ada');
    await tester.pumpAndSettle();
    expect(find.text('Carlos'), findsOneWidget);
    expect(find.widgetWithText(CheckboxListTile, 'Ada'), findsOneWidget);
    expect(find.widgetWithText(CheckboxListTile, 'Alan'), findsNothing);
  });

  testWidgets('unchecked cached row stays until close', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: SearchAnchorPicker<_Person>(
          config: _config([_ada]),
          initialSelectedIds: const [9],
          initialSelectedItemCache: const [_carlos],
        ),
      ),
    );
    await tester.tap(find.byIcon(Icons.search));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Carlos'));
    await tester.pumpAndSettle();
    expect(find.text('Carlos'), findsOneWidget);
    expect(find.text('Selected'), findsOneWidget);
  });

  testWidgets('loaded object wins over cache for the same ID', (tester) async {
    const cachedAda = _Person(1, 'Ada (cache)');
    await tester.pumpWidget(
      MaterialApp(
        home: SearchAnchorPicker<_Person>(
          config: _config([_ada]),
          initialSelectedIds: const [1],
          initialSelectedItemCache: const [cachedAda],
        ),
      ),
    );
    await tester.tap(find.byIcon(Icons.search));
    await tester.pumpAndSettle();
    expect(find.text('Ada'), findsOneWidget);
    expect(find.text('Ada (cache)'), findsNothing);
    expect(find.text('Selected'), findsNothing);
  });

  testWidgets('cache close still reports only the session delta', (
    tester,
  ) async {
    PickerDelta<int>? closed;
    await tester.pumpWidget(
      MaterialApp(
        home: SearchAnchorPicker<_Person>(
          config: _config([_ada]),
          initialSelectedIds: const [1, 9],
          initialSelectedItemCache: const [_carlos],
          onClose: (result) => closed = result,
        ),
      ),
    );
    await tester.tap(find.byIcon(Icons.search));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Carlos'));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Back'));
    await tester.pumpAndSettle();
    expect(closed!.added, isEmpty);
    expect(closed!.removed, {9});
  });

  testWidgets('itemBuilder receives cache source for missing rows', (
    tester,
  ) async {
    final sources = <int, PickerItemSource>{};
    await tester.pumpWidget(
      MaterialApp(
        home: SearchAnchorPicker<_Person>(
          config: _config([_ada]),
          initialSelectedIds: const [1, 9],
          initialSelectedItemCache: const [_carlos],
          itemBuilder: (context, item, selected, status, source, toggle) {
            sources[item.id] = source;
            return DefaultPickerItemTile(
              selected: selected,
              relatedListItemStatus: status,
              onToggle: (_) => toggle(),
              title: Text(item.name),
              subtitle: Text('id ${item.id}'),
              selectionMode: SelectionMode.multi,
            );
          },
        ),
      ),
    );
    await tester.tap(find.byIcon(Icons.search));
    await tester.pumpAndSettle();
    expect(sources[9], PickerItemSource.initialSelectedItemCache);
    expect(sources[1], PickerItemSource.loaded);
    expect(find.text('id 9'), findsOneWidget);
  });

  testWidgets('load error keeps cached selected rows under the error', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: SearchAnchorPicker<_Person>(
          config: PickerConfig<_Person>(
            itemsLoader: (_, _) async => throw StateError('offline'),
            idOf: (p) => p.id,
            labelOf: (p) => p.name,
            searchTermsOf: (p) => [p.name],
          ),
          initialSelectedIds: const [1, 9],
          initialSelectedItemCache: const [_ada, _carlos],
          errorBuilder: (context, error, stack, retry) =>
              TextButton(onPressed: retry, child: Text('Retry $error')),
        ),
      ),
    );
    await tester.tap(find.byIcon(Icons.search));
    await tester.pumpAndSettle();
    expect(find.textContaining('Retry Bad state: offline'), findsOneWidget);
    expect(find.text('Selected'), findsOneWidget);
    expect(find.text('Results'), findsNothing);
    expect(find.text('Ada'), findsOneWidget);
    expect(find.text('Carlos'), findsOneWidget);
  });

  testWidgets('load error without cache stays error-only', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: SearchAnchorPicker<_Person>(
          config: PickerConfig<_Person>(
            itemsLoader: (_, _) async => throw StateError('offline'),
            idOf: (p) => p.id,
            labelOf: (p) => p.name,
          ),
          initialSelectedIds: const [9],
          errorBuilder: (context, error, stack, retry) =>
              TextButton(onPressed: retry, child: Text('Retry $error')),
        ),
      ),
    );
    await tester.tap(find.byIcon(Icons.search));
    await tester.pumpAndSettle();
    expect(find.textContaining('Retry Bad state: offline'), findsOneWidget);
    expect(find.text('Selected'), findsNothing);
    expect(find.text('Carlos'), findsNothing);
  });
}
