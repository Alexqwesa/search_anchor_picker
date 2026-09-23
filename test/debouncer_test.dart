import 'package:flutter_test/flutter_test.dart';
import 'package:search_anchor_picker/search_anchor_picker.dart';

void main() {
  test('later run cancels the earlier wait', () async {
    final debounce = Debouncer(duration: const Duration(milliseconds: 20));
    final first = debounce.run(() => 1);
    await Future<void>.delayed(const Duration(milliseconds: 5));
    final second = debounce.run(() => 2);
    await expectLater(first, throwsA(isA<DebouncerCancelled>()));
    expect(await second, 2);
  });

  test('cancel fails a pending run', () async {
    final debounce = Debouncer(duration: const Duration(milliseconds: 50));
    final pending = debounce.run(() => 1);
    debounce.cancel();
    await expectLater(pending, throwsA(isA<DebouncerCancelled>()));
  });
}
