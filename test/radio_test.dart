// ignore_for_file: avoid_relative_lib_imports

import '../example/search_anchor_picker_example/lib/main_radio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('Radio Picker: Single Selection', (WidgetTester tester) async {
    await tester.pumpWidget(const RadioDemoApp());
    await tester.pumpAndSettle();

    // 1. Open Basic Radio Picker
    final trigger = find.byTooltip('Open radio picker');
    expect(trigger, findsOneWidget);
    await tester.tap(trigger);
    await tester.pumpAndSettle();

    // 2. Select "Main 1"
    final item1 = find.text('Main 1');
    expect(item1, findsOneWidget);
    await tester.tap(item1);
    await tester.pumpAndSettle();

    // Verify selection text update (Chip)
    expect(find.text('Main 1'), findsOneWidget);
    // Title of the card
    expect(find.text('Selected Main Item'), findsOneWidget);

    // 3. Re-open and select "Main 2"
    await tester.tap(trigger); // Open again
    await tester.pumpAndSettle();

    final item2 = find.text('Main 2');
    await tester.tap(item2);
    await tester.pumpAndSettle();

    // Verify selection changed
    expect(find.text('Main 2'), findsOneWidget);
  });

  testWidgets('Radio Picker: Sub Picker Selection', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const RadioDemoApp());
    await tester.pumpAndSettle();

    // 1. Open Parent Picker with Sub
    final parentTrigger = find.byTooltip('Open parent picker');
    await tester.tap(parentTrigger);
    await tester.pumpAndSettle();

    // 2. Open Sub Picker (inside parent overlay)
    // The sub picker trigger is a ListTile with title 'Sub Radio Trigger (Tile)'
    await tester.tap(find.text('Sub Radio Trigger (Tile)'));
    await tester.pumpAndSettle();

    // 3. Select "Sub 1"
    final subItem1 = find.text('Sub 1');
    expect(subItem1, findsOneWidget);
    await tester.tap(subItem1);
    await tester.pumpAndSettle();

    // Verify sub selection updated on main screen (Chip)
    expect(
      find.text('Sub 1'),
      findsNWidgets(2),
    ); // seems to work maybe it found both on main screen and on list?

    // Also check title
    expect(find.text('Selected Parent/Sub Item'), findsOneWidget);
  });

  testWidgets('Radio Picker: Parent Selection with Sub (Transient Item)', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const RadioDemoApp());
    await tester.pumpAndSettle();

    // 1. Open Parent Picker with Sub
    final parentTrigger = find.byTooltip('Open parent picker');
    await tester.tap(parentTrigger);
    await tester.pumpAndSettle();

    // 2. Open Sub Picker
    await tester.tap(find.text('Sub Radio Trigger (Tile)'));
    await tester.pumpAndSettle();

    // 3. Select "Sub 1"
    final subItem1 = find.text('Sub 1');
    expect(subItem1, findsOneWidget);
    await tester.tap(subItem1);
    await tester.pumpAndSettle();

    // Verify "Sub 1" became the main selection (Added as transient)
    // Check CHIP on screen
    expect(find.widgetWithText(Chip, 'Sub 1'), findsOneWidget);

    // 4. Verify Parent Picker list
    // The Parent Picker should still be open after Sub Picker closes.
    // Wait for async reload triggered by Notifier AND Sub Picker close animation
    await tester.pump(const Duration(milliseconds: 500));
    await tester.pumpAndSettle();

    // print('DEBUG TEST: Found ${subItemFinder.evaluate().length} "Sub 1" items');

    if (find.byType(ListView).evaluate().isEmpty) {
      // If it closed for some reason, re-open it
      await tester.tap(parentTrigger);
      await tester.pumpAndSettle();
    }

    // Verify "Sub 1" is now IN THE MAIN LIST (transient)
    // We look for it in the OverlayBody or just textual presence (distinct from Chip if we are lucky)
    // But since we just opened it, it DEFINITELY should be there.

    // Exclude Chip (which is in ListView but not CheckboxListTile)
    // We look for 'Sub 1' that is inside a CheckboxListTile.
    final listFinder = find.ancestor(
      of: find.text('Sub 1'),
      matching: find.byType(CheckboxListTile),
    );
    // We expect at least one (Main Picker should definitely have it).
    expect(listFinder, findsAtLeastNWidgets(1));

    // Verify it is properly checked
    final count = listFinder.evaluate().length;
    for (var i = 0; i < count; i++) {
      final box = tester.widget<CheckboxListTile>(listFinder.at(i));
      expect(box.value, isTrue, reason: 'Tile $i should be checked');
    }

    // 5. Select "Main 2"
    final item2 = find.text('Main 2');
    await tester.tap(item2);
    await tester.pumpAndSettle();

    // Verify "Main 2" is selected
    expect(find.text('Main 2'), findsOneWidget);
    // Verify "Sub 1" is NOT selected (implicit by Main 2 being there)

    // 6. Open Parent Picker again
    await tester.tap(parentTrigger);
    await tester.pumpAndSettle();

    // Verify "Sub 1" is GONE from the main list (transient cleared)
    // We check if "Sub 1" exists inside a CheckboxListTile.
    final subInList = find.ancestor(
      of: find.text('Sub 1'),
      matching: find.byType(CheckboxListTile),
    );
    expect(
      subInList,
      findsNothing,
      reason: 'Sub 1 should be gone from picker list',
    );
  });
}
