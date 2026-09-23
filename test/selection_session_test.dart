import 'package:flutter_test/flutter_test.dart';
import 'package:search_anchor_picker/src/raw/selection_session.dart';

void main() {
  test('select then restore to the open seed nets empty', () {
    final session = PickerSelectionSession<int>([1, 9])..open([1, 9]);
    addTearDown(session.dispose);
    session
      ..recordExplicitChange({1, 9}, {2, 9})
      ..pendingN.value = {2, 9};
    expect(session.result().added, {2});
    expect(session.result().removed, {1});

    session
      ..recordExplicitChange({2, 9}, {1, 9})
      ..pendingN.value = {1, 9};
    expect(session.result().added, isEmpty);
    expect(session.result().removed, isEmpty);
  });

  test('reseed does not drop explicit intent or invent removals', () {
    final session = PickerSelectionSession<int>([1])..open([1]);
    addTearDown(session.dispose);
    session
      ..recordExplicitChange({1}, {1, 2})
      ..pendingN.value = {1, 2}
      ..reseed([]);
    expect(session.result().added, {2});
    expect(session.result().removed, isEmpty);
  });

  test('restore to the open seed nets empty even after a reseed', () {
    final session = PickerSelectionSession<int>([1])..open([1]);
    addTearDown(session.dispose);
    session
      ..recordExplicitChange({1}, <int>{})
      ..pendingN.value = <int>{}
      ..recordExplicitChange(<int>{}, {1})
      ..pendingN.value = {1}
      ..reseed([]);
    expect(session.result().added, isEmpty);
    expect(session.result().removed, isEmpty);
  });

  test('external reseeds change pending without creating deltas', () {
    final session = PickerSelectionSession<int>([1, 2, 3]);
    addTearDown(session.dispose);

    session
      ..open([1, 2, 3])
      ..reseed([1]);

    final result = session.result();
    expect(session.pendingN.value, {1});
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
    expect(session.pendingN.value, {1, 2, 3});
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
    expect(session.pendingN.value, {2});
    expect(result.added, isEmpty);
    expect(result.removed, isEmpty);
  });
}
