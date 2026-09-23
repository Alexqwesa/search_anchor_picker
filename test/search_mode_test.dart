import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:search_anchor_picker/search_anchor_picker.dart';

void main() {
  testWidgets('local loads once and filters the snapshot', (tester) async {
    final queries = <String>[];
    await tester.pumpWidget(
      MaterialApp(
        home: SearchAnchorPicker<int>(
          config: PickerConfig<int>(
            loadItems: (_, query) async {
              queries.add(query);
              return [1, 2];
            },
            idOf: (item) => item,
            labelOf: (item) => 'Item $item',
            searchTermsOf: (item) => ['Item $item'],
          ),
          initialSelectedIds: const [],
        ),
      ),
    );

    await tester.tap(find.byIcon(Icons.search));
    await tester.pumpAndSettle();
    expect(queries, ['']);
    expect(find.text('Item 1'), findsOneWidget);
    expect(find.text('Item 2'), findsOneWidget);

    await tester.enterText(find.byType(SearchBar), '2');
    await tester.pumpAndSettle();
    expect(queries, ['']);
    expect(find.text('Item 1'), findsNothing);
    expect(find.text('Item 2'), findsOneWidget);

    await tester.tap(find.byIcon(Icons.close));
    await tester.pumpAndSettle();
    expect(queries, ['']);
    expect(find.text('Item 1'), findsOneWidget);
    expect(find.text('Item 2'), findsOneWidget);
  });

  testWidgets('remote reloads and keeps server rows searchTermsOf would hide', (
    tester,
  ) async {
    final queries = <String>[];
    await tester.pumpWidget(
      MaterialApp(
        home: SearchAnchorPicker<int>(
          config: PickerConfig<int>(
            searchMode: PickerSearchMode.remote,
            loadItems: (_, query) async {
              queries.add(query);
              if (query.isEmpty) return [1];
              return [8];
            },
            idOf: (item) => item,
            labelOf: (item) => 'Item $item',
            searchTermsOf: (_) => const ['Ada'],
          ),
          initialSelectedIds: const [],
        ),
      ),
    );

    await tester.tap(find.byIcon(Icons.search));
    await tester.pumpAndSettle();
    expect(queries, ['']);
    expect(find.text('Item 1'), findsOneWidget);

    await tester.enterText(find.byType(SearchBar), 'lin');
    await tester.pumpAndSettle();
    expect(queries, ['', 'lin']);
    expect(find.text('Item 1'), findsNothing);
    expect(find.text('Item 8'), findsOneWidget);
  });

  testWidgets('hybrid reloads then hides rows that miss searchTermsOf', (
    tester,
  ) async {
    final queries = <String>[];
    await tester.pumpWidget(
      MaterialApp(
        home: SearchAnchorPicker<int>(
          config: PickerConfig<int>(
            searchMode: PickerSearchMode.hybrid,
            loadItems: (_, query) async {
              queries.add(query);
              if (query.isEmpty) return [1];
              return [8];
            },
            idOf: (item) => item,
            labelOf: (item) => 'Item $item',
            searchTermsOf: (_) => const ['Ada'],
          ),
          initialSelectedIds: const [],
          noResultsText: 'Nothing matched',
        ),
      ),
    );

    await tester.tap(find.byIcon(Icons.search));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(SearchBar), 'lin');
    await tester.pumpAndSettle();

    expect(queries, ['', 'lin']);
    expect(find.text('Item 8'), findsNothing);
    expect(find.text('Nothing matched'), findsOneWidget);
  });

  testWidgets('remote does not require searchTermsOf', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: SearchAnchorPicker<int>(
          config: PickerConfig<int>(
            searchMode: PickerSearchMode.remote,
            loadItems: (_, query) async => query.isEmpty ? [1] : [99],
            idOf: (item) => item,
            labelOf: (item) => 'Item $item',
          ),
          initialSelectedIds: const [],
        ),
      ),
    );

    await tester.tap(find.byIcon(Icons.search));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(SearchBar), 'q');
    await tester.pumpAndSettle();
    expect(find.text('Item 99'), findsOneWidget);
  });

  test('copyWith can change searchMode and clear searchTermsOf', () {
    Iterable<String> terms(int item) => ['$item'];
    final config = PickerConfig<int>(
      loadItems: (_, _) async => [1],
      idOf: (item) => item,
      labelOf: (item) => '$item',
      searchTermsOf: terms,
    );
    expect(config.searchMode, PickerSearchMode.local);

    final kept = config.copyWith(title: 'x');
    expect(kept.searchMode, PickerSearchMode.local);
    expect(kept.searchTermsOf, same(terms));

    final changed = config.copyWith(
      searchMode: PickerSearchMode.remote,
      searchTermsOf: null,
    );
    expect(changed.searchMode, PickerSearchMode.remote);
    expect(changed.searchTermsOf, isNull);
  });
}
