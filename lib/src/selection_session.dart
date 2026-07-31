import 'package:flutter/foundation.dart';

class PickerSelectionResult<K> {
  const PickerSelectionResult({
    required this.finalIds,
    required this.added,
    required this.removed,
  });

  final Set<K> finalIds;
  final Set<K> added;
  final Set<K> removed;
}

/// Owns one open picker's selection snapshot and explicit user intent.
class PickerSelectionSession<K> {
  PickerSelectionSession(Iterable<K> initialIds)
    : pendingN = ValueNotifier<Set<K>>(initialIds.toSet());

  final ValueNotifier<Set<K>> pendingN;

  Set<K> _openedIds = <K>{};
  final Set<K> _explicitlyAdded = <K>{};
  final Set<K> _explicitlyRemoved = <K>{};

  Set<K> get openedIds => _openedIds;

  void open(Iterable<K> seed) {
    _openedIds = seed.toSet();
    _explicitlyAdded.clear();
    _explicitlyRemoved.clear();
    pendingN.value = {..._openedIds};
  }

  /// External state is authoritative for pending IDs but is never user intent.
  void reseed(Iterable<K> ids) {
    pendingN.value = ids.toSet();
  }

  void recordExplicitChange(Set<K> before, Set<K> after) {
    final added = after.difference(before);
    final removed = before.difference(after);
    _explicitlyAdded
      ..addAll(added)
      ..removeAll(removed);
    _explicitlyRemoved
      ..addAll(removed)
      ..removeAll(added);
  }

  PickerSelectionResult<K> result() {
    final finalIds = {...pendingN.value};
    return PickerSelectionResult<K>(
      finalIds: finalIds,
      added: _explicitlyAdded.intersection(finalIds.difference(_openedIds)),
      removed: _explicitlyRemoved.intersection(_openedIds.difference(finalIds)),
    );
  }

  void dispose() => pendingN.dispose();
}
