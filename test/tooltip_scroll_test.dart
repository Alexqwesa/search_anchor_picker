import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:generic_search_selector/generic_search_selector.dart';

class _DemoItem {
  const _DemoItem(this.id, this.label, this.tooltip);

  final int id;
  final String label;
  final String tooltip;
}

void main() {
  testWidgets('popup list keeps scrolling while item tooltip is visible', (
    tester,
  ) async {
    final items = List.generate(
      40,
      (index) => _DemoItem(
        index,
        'Item $index with a very long label to overflow the row and show a tooltip',
        'Tooltip for item $index',
      ),
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: SearchAnchorPicker<_DemoItem>(
              config: PickerConfig<_DemoItem>(
                loadItems: (_) async => items,
                idOf: (item) => item.id,
                labelOf: (item) => item.label,
                searchTermsOf: (item) => [item.label, item.tooltip],
                tooltipOf: (item) => item.tooltip,
                selectedFirst: false,
              ),
              initialSelectedIds: const [],
              triggerChild: const Padding(
                padding: EdgeInsets.all(16),
                child: Text('open picker'),
              ),
              maxHeight: 260,
              minWidth: 320,
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('open picker'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pump(const Duration(milliseconds: 300));

    final scrollable = tester.state<ScrollableState>(
      find.byType(Scrollable).last,
    );
    final before = scrollable.position.pixels;

    final itemFinder = find.text(
      'Item 1 with a very long label to overflow the row and show a tooltip',
    );
    final target = tester.getCenter(itemFinder);

    final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
    await mouse.addPointer();
    await mouse.moveTo(target);
    await tester.pump(const Duration(milliseconds: 700));

    final tooltipFinder = find.text('Tooltip for item 1');
    expect(tooltipFinder, findsOneWidget);

    final tooltipCenter = tester.getCenter(tooltipFinder);
    await mouse.moveTo(tooltipCenter);
    await tester.pump();

    await tester.sendEventToBinding(
      PointerScrollEvent(position: tooltipCenter, scrollDelta: Offset(0, -160)),
    );
    await tester.pump();

    if (scrollable.position.pixels == before) {
      await tester.sendEventToBinding(
        PointerScrollEvent(
          position: tooltipCenter,
          scrollDelta: Offset(0, 160),
        ),
      );
      await tester.pump();
    }

    expect(scrollable.position.pixels, isNot(before));
  });
}
