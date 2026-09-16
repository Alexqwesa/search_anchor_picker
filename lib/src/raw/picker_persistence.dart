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

/// A proposed selection mutation, including loaded items when known.
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

/// When immediate persistence updates in-overlay selection.
enum PickerApplyMode {
  /// Persist first, then update checkboxes.
  pessimistic,

  /// Update checkboxes first, then persist and revert on failure.
  optimistic,
}

/// How accepted selection deltas are saved.
sealed class PickerPersistence<K> {
  const PickerPersistence();

  /// Persist the net session delta when the picker closes.
  const factory PickerPersistence.onClose({
    required Future<void> Function(PickerDelta<K> delta) persist,
  }) = PickerPersistOnClose<K>;

  /// Persist each accepted delta as it happens.
  factory PickerPersistence.immediate({
    required Future<void> Function(PickerDelta<K> delta) persist,
    PickerApplyMode applyMode = PickerApplyMode.pessimistic,
  }) => PickerPersistImmediately<K>(persist: persist, applyMode: applyMode);
}

final class PickerPersistOnClose<K> extends PickerPersistence<K> {
  const PickerPersistOnClose({required this.persist});

  final Future<void> Function(PickerDelta<K> delta) persist;
}

final class PickerPersistImmediately<K> extends PickerPersistence<K> {
  const PickerPersistImmediately({
    required this.persist,
    this.applyMode = PickerApplyMode.pessimistic,
  });

  final Future<void> Function(PickerDelta<K> delta) persist;
  final PickerApplyMode applyMode;
}
