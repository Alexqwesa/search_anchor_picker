import 'package:flutter/foundation.dart';
import 'package:search_anchor_picker/src/raw/picker_selection.dart';

export 'package:search_anchor_picker/src/raw/picker_selection.dart'
    show PickerSelectionResult;

/// Owns one open picker's selection snapshot and explicit user intent.
class PickerSelectionSession<K> {
  PickerSelectionSession(Iterable<K> initialIds)
    : pendingN = ValueNotifier<Set<K>>(initialIds.toSet());

  final ValueNotifier<Set<K>> pendingN;

  Set<K> _openedIds = <K>{};
  final Set<K> _explicitlyAdded = <K>{};
  final Set<K> _explicitlyRemoved = <K>{};
  Set<K>? _acceptedIds;

  Set<K> get openedIds => _openedIds;

  void open(Iterable<K> seed) {
    _openedIds = seed.toSet();
    _explicitlyAdded.clear();
    _explicitlyRemoved.clear();
    _acceptedIds = null;
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

  /// Advances the persistence baseline only for successfully applied toggles.
  void acceptToggle(Set<K> before, Set<K> after) {
    (_acceptedIds ??= {..._openedIds})
      ..addAll(after.difference(before))
      ..removeAll(before.difference(after));
  }

  PickerSelectionResult<K> result({bool remainingOnly = false}) {
    final finalIds = {...pendingN.value};
    final baseline = remainingOnly ? (_acceptedIds ?? _openedIds) : _openedIds;
    return PickerSelectionResult<K>(
      finalIds: finalIds,
      added: _explicitlyAdded.intersection(finalIds.difference(baseline)),
      removed: _explicitlyRemoved.intersection(baseline.difference(finalIds)),
    );
  }

  void dispose() => pendingN.dispose();
}
