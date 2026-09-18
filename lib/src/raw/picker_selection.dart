import 'package:flutter/foundation.dart';

/// The IDs of one accepted selection mutation.
///
/// This is what `onChange` receives after the checkboxes moved: one row
/// toggle, one `setSelected`, or one bulk command. Persist [added] and
/// [removed] together; a bulk command arrives as a single delta over many IDs,
/// not one delta per row. Both sets can hold IDs that are not in the current
/// `loadItems` result, so persist by ID rather than by loaded item.
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

/// What one picker session changed, from open to close.
///
/// This is what `onClose` receives. [finalIds] is the selection the user ended
/// with; [added] and [removed] are its net difference from
/// `initialSelectedIds`, so a row selected and deselected again in the same
/// session appears in neither. Send [finalIds] to an API that replaces a whole
/// list, or [delta] to one that takes changes.
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
