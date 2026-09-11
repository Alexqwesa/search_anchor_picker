import 'package:flutter_test/flutter_test.dart';
import 'package:search_anchor_picker/src/selection_session.dart';

void main() {
  test('external reseeds change pending without creating deltas', () {
    final session = PickerSelectionSession<int>([1, 2, 3]);
    addTearDown(session.dispose);

    session
      ..open([1, 2, 3])
      ..reseed([1]);

    final result = session.result();
    expect(result.finalIds, {1});
    expect(result.added, isEmpty);
    expect(result.removed, isEmpty);
  });

  test('only net explicit changes are reported', () {
    final session = PickerSelectionSession<int>([1, 2]);
    addTearDown(session.dispose);

    session
      ..open([1, 2])
      ..recordExplicitChange({1, 2}, {1, 2, 3})
      ..pendingN.value = {1, 2, 3}
      ..recordExplicitChange({1, 2, 3}, {1, 3})
      ..pendingN.value = {1, 3}
      ..recordExplicitChange({1, 3}, {1, 2, 3})
      ..pendingN.value = {1, 2, 3};

    final result = session.result();
    expect(result.finalIds, {1, 2, 3});
    expect(result.added, {3});
    expect(result.removed, isEmpty);
  });

  test('reopening resets snapshot and explicit intent', () {
    final session = PickerSelectionSession<int>([1]);
    addTearDown(session.dispose);

    session
      ..open([1])
      ..recordExplicitChange({1}, <int>{})
      ..pendingN.value = <int>{}
      ..open([2]);
    final result = session.result();
    expect(result.finalIds, {2});
    expect(result.added, isEmpty);
    expect(result.removed, isEmpty);
  });
}
