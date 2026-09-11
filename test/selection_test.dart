// ignore_for_file: avoid_relative_lib_imports

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../example/search_anchor_picker_example/lib/main.dart';

void main() {
  testWidgets('Icon #1 (Main List A) Selection', (tester) async {
    await tester.pumpWidget(const DemoApp());
    await tester.pumpAndSettle();

    // Verify initial state
    expect(find.text('No selection'), findsWidgets);

    // 1. Open Picker A
    await tester.tap(find.byTooltip('Open picker A'));
    await tester.pumpAndSettle();

    // 2. Select "Alice"
    final itemAlice = find.text('A: Alice (internal)').last;
    await tester.tap(itemAlice);
    await tester.pumpAndSettle();

    // 3. Verify selection on screen (chip appears)
    expect(find.widgetWithText(Chip, 'A: Alice (internal)'), findsOneWidget);

    // 4. Deselect "Alice"
    await tester.tap(itemAlice);
    await tester.pumpAndSettle();

    // 5. Verify chip gone
    expect(find.widgetWithText(Chip, 'A: Alice (internal)'), findsNothing);
  });

  testWidgets('Icon #1 (Sub Picker A1) Selection', (tester) async {
    await tester.pumpWidget(const DemoApp());
    await tester.pumpAndSettle();

    // Open Picker A
    await tester.tap(find.byTooltip('Open picker A'));
    await tester.pumpAndSettle();

    // Open Sub Picker A1
    // Tile title: 'Add/remove from Sub A1'
    final subA1Tile = find.text('Add/remove from Sub A1');
    expect(subA1Tile, findsOneWidget);
    await tester.tap(subA1Tile);
    await tester.pumpAndSettle();

    // Select "A1: Charlie (external)"
    final itemCharlie = find.text('A1: Charlie (external)').last;
    expect(itemCharlie, findsOneWidget);
    await tester.tap(itemCharlie);
    await tester.pumpAndSettle();

    final checkBtn = find.byIcon(Icons.check);
    if (checkBtn.evaluate().isNotEmpty) {
      await tester.tap(checkBtn.last);
    } else {
      await tester.tap(find.byTooltip('Back').last);
    }
    await tester.pumpAndSettle();

    // Let's verify Charlie is now in List A.
    expect(find.text('A1: Charlie (external)'), findsOneWidget);

    // Select it in List A
    await tester.tap(find.text('A1: Charlie (external)'));
    await tester.pumpAndSettle();

    // Verify chip
    expect(find.widgetWithText(Chip, 'A1: Charlie (external)'), findsOneWidget);
  });

  testWidgets('Icon #2 (Main List B) Selection', (tester) async {
    await tester.pumpWidget(const DemoApp());
    await tester.pumpAndSettle();

    // Scroll to Icon #2 if needed
    final triggerB = find.byTooltip('Open picker B');
    await tester.scrollUntilVisible(triggerB, 500);
    await tester.pumpAndSettle();

    // Open Picker B
    await tester.tap(triggerB);
    await tester.pumpAndSettle();

    // Select "B: Igor (internal)"
    final itemIgor = find.text('B: Igor (internal)').last;
    await tester.tap(itemIgor);
    await tester.pumpAndSettle();

    // Verify chip
    expect(find.widgetWithText(Chip, 'B: Igor (internal)'), findsOneWidget);
  });

  testWidgets('Icon #2 (Sub Picker B1) Selection', (tester) async {
    await tester.pumpWidget(const DemoApp());
    await tester.pumpAndSettle();

    // Scroll to Icon #2
    final triggerB = find.byTooltip('Open picker B');
    await tester.scrollUntilVisible(triggerB, 500);
    await tester.pumpAndSettle();

    // Open Picker B
    await tester.tap(triggerB);
    await tester.pumpAndSettle();

    // Open Sub Picker B1
    final subB1Tile = find.text('Select from Sub B1 (to screen)');
    await tester.tap(subB1Tile);
    await tester.pumpAndSettle();

    // Select "B1: Ken (external)"
    final itemKen = find.text('B1: Ken (external)').last;
    await tester.tap(itemKen);
    await tester.pumpAndSettle();

    // Go back
    final checkBtn = find.byIcon(Icons.check);
    if (checkBtn.evaluate().isNotEmpty) {
      await tester.tap(checkBtn.last);
    } else {
      await tester.tap(find.byTooltip('Back').last);
    }
    await tester.pumpAndSettle();

    // Verify chip is present
    expect(find.widgetWithText(Chip, 'B1: Ken (external)'), findsOneWidget);
  });

  testWidgets('Icon #1 (Sub Picker A1) Alert Strategy', (
    tester,
  ) async {
    await tester.pumpWidget(const DemoApp());
    await tester.pumpAndSettle();

    // Verify Alert Strategy: trying to uncheck an "in-use" item in SubA1 shows an alert.
    await tester.tap(find.byTooltip('Open picker A'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Add/remove from Sub A1'));
    await tester.pumpAndSettle();

    // Select Charlie in Sub A1
    final itemCharlie = find.text('A1: Charlie (external)').last;
    await tester.tap(itemCharlie);
    await tester.pumpAndSettle();

    // Close Sub A1
    final checkBtn = find.byIcon(Icons.check);
    if (checkBtn.evaluate().isNotEmpty) {
      await tester.tap(checkBtn.last);
    } else {
      await tester.tap(find.byTooltip('Back').last);
    }
    await tester.pumpAndSettle();

    // Select Charlie in Main A (making it "in use")
    final itemCharlieMain = find.text('A1: Charlie (external)').last;
    await tester.tap(itemCharlieMain);
    await tester.pumpAndSettle();
    expect(find.widgetWithText(Chip, 'A1: Charlie (external)'), findsOneWidget);

    // Re-open Sub A1
    await tester.tap(find.text('Add/remove from Sub A1'));
    await tester.pumpAndSettle();

    // Try to deselect Charlie -> Expect Alert
    await tester.tap(find.text('A1: Charlie (external)').last);
    await tester.pumpAndSettle();

    expect(find.text('Remove item?'), findsOneWidget);
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
    expect(find.text('Remove item?'), findsNothing);
  });
}
