// ignore_for_file: avoid_relative_lib_imports

import '../example/example_of_generic_search_selector/lib/main_async.dart'
    as app_async;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('Async Demo: Load, Refresh, Invalidate', (
    WidgetTester tester,
  ) async {
    // 1. Pump async app
    await tester.pumpWidget(const ProviderScope(child: app_async.DemoApp()));
    // Initial load has delay defined in ItemsNotifier (500ms)
    await tester.pump(const Duration(milliseconds: 100));
    expect(
      find.byType(CircularProgressIndicator),
      findsWidgets,
    ); // Should be loading inside trigger?

    await tester.pump(const Duration(milliseconds: 600));
    await tester.pumpAndSettle();

    // 2. Open Picker A
    await tester.tap(find.byTooltip('Open picker A'));
    await tester.pumpAndSettle();

    // Verify "Alice" is present
    expect(find.text('A: Alice (internal)'), findsOneWidget);

    // 3. Trigger Refresh (using UI buttons on main screen - need to close picker first)
    // Or we can tap outside.
    await tester.tap(find.byTooltip('Back'));
    await tester.pumpAndSettle();

    // Top buttons: Refresh List A
    await tester.tap(find.byTooltip('Refresh List A'));
    await tester.pump();

    // Expect loading indicator on trigger
    expect(find.byType(CircularProgressIndicator), findsOneWidget);

    // Wait for refresh delay (800ms) + Initial load (500ms) = 1300ms
    await tester.pump(const Duration(milliseconds: 1500));
    await tester.pumpAndSettle();
    expect(find.byType(CircularProgressIndicator), findsNothing);

    // 4. Invalidate SubA1
    // Open Picker A -> Open Sub A1 -> Check content
    await tester.tap(find.byTooltip('Open picker A'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Sub A1 (Async)')); // Title used in main_async
    await tester.pumpAndSettle();

    // Wait for data to load
    await tester.pump(const Duration(milliseconds: 1000));
    await tester.pumpAndSettle();

    expect(find.text('A1: Charlie (external)'), findsOneWidget);

    // Close back to main screen
    await tester.tap(find.byTooltip('Back').last); // SubA1 close
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Back').first); // MainA close
    await tester.pumpAndSettle();

    // Tap Invalidate SubA1
    await tester.tap(find.byTooltip('Invalidate SubA1'));
    await tester.pump();

    // Verify it re-fetches when we open it next time?
    // Riverpod invalidation resets state to uninitialized.
    // So next read triggers build().

    await tester.tap(find.byTooltip('Open picker A'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Sub A1 (Async)'));
    await tester.pump(); // It should be loading now

    // Since SubA1 is opened, it attempts to load.
    // Provider delay is 500ms.
    // Check for loading indicator in the sub picker
    // expect(find.byType(CircularProgressIndicator), findsWidgets);

    await tester.pump(const Duration(milliseconds: 600));
    await tester.pumpAndSettle();

    expect(find.text('A1: Charlie (external)'), findsOneWidget);
  });
}
