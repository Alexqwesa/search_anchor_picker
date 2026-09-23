import 'package:flutter/foundation.dart';
import 'package:search_anchor_picker/src/raw/picker_selection.dart';

export 'package:search_anchor_picker/src/raw/picker_selection.dart'
    show PickerDelta;

/// Selection bookkeeping for one open picker overlay.
///
/// The picker notifies (`onChange` / `onClose`); it does not persist. This
/// session exists so checkbox state, the open-time seed, and user intent stay
/// independent:
///
/// * [pendingN] is the live checkbox set while the overlay is open.
/// * [openedIds] is the seed captured at [open]. It is the baseline for
///   [result] and for selected-first ordering. Toggles do not change it.
/// * Explicit added/removed IDs are written only by [recordExplicitChange]
///   after an accepted row tap or bulk header command. [reseed] (and the
///   controller's `syncPending`) update [pendingN] without creating intent,
///   so parent `initialSelectedIds` changes and nested parent-sync never
///   appear in `onChange` / `onClose`.
///
/// The raw picker creates this lazily when the overlay opens and disposes it
/// on close so a closed picker stays lightweight. Reopening calls [open],
/// which resets snapshot and intent.
///
/// [result] is the `onClose` payload: net explicit add/remove versus
/// [openedIds] (the seed at open, not a later `initialSelectedIds`). Select
/// then unselect (or the reverse) any number of times nets to empty `added` /
/// `removed`. A later reseed updates checkboxes only; it does not create
/// intent and does not drop recorded intent. `onChange` does not consume this
/// intent, so close still reports the same net. Close deltas come only from
/// those explicit toggles, not from comparing pending IDs to `itemsLoader` or
/// to the current `initialSelectedIds`.
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

  PickerDelta<K> result({bool remainingOnly = false}) {
    final baseline = remainingOnly ? (_acceptedIds ?? _openedIds) : _openedIds;
    return PickerDelta<K>(
      added: _explicitlyAdded.difference(baseline),
      removed: _explicitlyRemoved.intersection(baseline),
    );
  }

  void dispose() => pendingN.dispose();
}
