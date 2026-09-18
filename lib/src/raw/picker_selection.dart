import 'package:flutter/foundation.dart';

/// Added and removed IDs.
///
/// `onChange` gets one mutation (a row, `setSelected`, or one bulk command)
/// each time it is accepted. Toggling the same ID on and off is two calls.
/// `onClose` gets the net of the session versus `initialSelectedIds`: an ID
/// selected and deselected again is omitted. Empty means do not write.
///
/// Persist both sets together, by ID. An ID can stay selected while missing
/// from the current `loadItems` page. A load error or empty search is not a
/// deletion.
///
/// Both callbacks may be set. `onChange` does not consume session intent, so
/// `onClose` still reports the same net. Persist in only one of them.
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
