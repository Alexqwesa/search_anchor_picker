import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:search_anchor_picker/search_anchor_picker.dart';
import 'package:search_anchor_picker_example/card_gallery/nested_card.dart';
import 'package:search_anchor_picker_example/card_gallery/people.dart';

Widget _unknownCard() {
  return const MaterialApp(
    home: Scaffold(
      body: SingleChildScrollView(
        child: NestedCard(
          title: 'Related-list + unknown',
          persistLabel: 'child onClose, parent onClose',
          difference: '',
          source: '',
          relatedOnParent: true,
          relatedUnknown: true,
          addChildSelectionToParent: true,
          childPersist: Persist.close,
          directorySeed: pagedDirectoryIds,
          sublists: 1,
        ),
      ),
    ),
  );
}

void main() {
  test('empty child close does not persist existing sublist members', () {
    final selected = {1, 4};
    persistExplicitChildAdds(selected, const PickerDelta<int>());
    expect(selected, {1, 4});
  });

  test('only explicit child adds are copied onto the parent field', () {
    final selected = {1, 4};
    final synced = <int>{};
    persistExplicitChildAdds(
      selected,
      const PickerDelta<int>(added: {2}, removed: {5}),
      syncParent: synced.addAll,
    );
    expect(selected, {1, 2, 4});
    expect(synced, {2});
  });

  testWidgets(
    'empty Directory close does not select directory-only or restore unselects',
    (tester) async {
      await tester.pumpWidget(_unknownCard());

      await tester.tap(find.text('Add'));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(CheckboxListTile, 'Ada Lovelace'));
      await tester.pumpAndSettle();
      expect(_checked(tester, 'Ada Lovelace'), isFalse);
      expect(_checked(tester, 'Katherine Johnson'), isTrue);
      expect(_checked(tester, 'Margaret Hamilton'), isFalse);

      await tester.tap(find.text('Directory'));
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('Back').last);
      await tester.pumpAndSettle();

      expect(_checked(tester, 'Ada Lovelace'), isFalse);
      expect(_checked(tester, 'Katherine Johnson'), isTrue);
      expect(_checked(tester, 'Margaret Hamilton'), isFalse);
    },
  );

  testWidgets('explicit Directory add is written onto the parent', (
    tester,
  ) async {
    await tester.pumpWidget(_unknownCard());

    await tester.tap(find.text('Add'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Directory'));
    await tester.pumpAndSettle();
    await tester.tap(
      find.widgetWithText(CheckboxListTile, 'Alan Turing').last,
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Back').last);
    await tester.pumpAndSettle();

    expect(_checked(tester, 'Alan Turing'), isTrue);
    expect(_checked(tester, 'Katherine Johnson'), isTrue);
  });
}

bool _checked(WidgetTester tester, String label) {
  return tester
      .widget<CheckboxListTile>(
        find.widgetWithText(CheckboxListTile, label).first,
      )
      .value!;
}
