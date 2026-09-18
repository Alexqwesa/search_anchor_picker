import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:search_anchor_picker/search_anchor_picker.dart';

void main() {
  testWidgets('PickerConfig.open/close controls SearchAnchorPicker', (
    tester,
  ) async {
    final config = PickerConfig<int>(
      loadItems: (_) async => [1, 2, 3],
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
      loadItems: (_) async => [1],
      idOf: (i) => i,
      labelOf: (i) => 'Main $i',
      searchTermsOf: (_) => [],
    );

    // SUB PICKER
    final subConfig = PickerConfig<int>(
      loadItems: (_) async => [100],
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
}
