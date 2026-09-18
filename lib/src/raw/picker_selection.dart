import 'package:flutter/foundation.dart';

/// Added and removed IDs for one selection mutation or a session result.
@immutable
class PickerDelta<K> {
  const PickerDelta({
    this.added = const {},
    this.removed = const {},
  });

  final Set<K> added;
  final Set<K> removed;

  bool get isEmpty => added.isEmpty && removed.isEmpty;
}

/// Net user result of one picker session.
@immutable
class PickerSelectionResult<K> {
  const PickerSelectionResult({
    required this.finalIds,
    required this.added,
    required this.removed,
  });

  final Set<K> finalIds;
  final Set<K> added;
  final Set<K> removed;

  PickerDelta<K> get delta => PickerDelta(added: added, removed: removed);
}

/// A proposed or accepted selection mutation, including loaded items when known.
@immutable
class PickerSelectionChange<T, K> {
  const PickerSelectionChange({
    required this.delta,
    required this.addedItems,
    required this.removedItems,
  });

  final PickerDelta<K> delta;
  final List<T> addedItems;
  final List<T> removedItems;
}
