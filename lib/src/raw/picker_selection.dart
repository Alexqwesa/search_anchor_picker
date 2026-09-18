import 'package:flutter/foundation.dart';

/// Added and removed IDs for one accepted mutation, or the net of one session.
///
/// `onChange` receives this after the checkboxes moved: one row toggle, one
/// `setSelected`, or one bulk command. Persist [added] and [removed] together;
/// a bulk command arrives as a single delta over many IDs, not one delta per
/// row.
///
/// `onClose` receives the same type: the net of the session versus
/// `initialSelectedIds`. A row selected and deselected again appears in
/// neither. An empty delta means the user changed nothing; do not write.
/// Apply it to the seed you already hold. There is no final snapshot.
///
/// Both sets can hold IDs that are not in the current `loadItems` result, so
/// persist by ID rather than by loaded item. `loadItems` is search and display
/// data; a failed load, empty page, or filter is not "the list is empty".
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
