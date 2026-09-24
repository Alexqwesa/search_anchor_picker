import 'package:flutter/foundation.dart';

/// Where a displayed row's object came from.
enum PickerItemSource {
  /// Present in the current `itemsLoader` result.
  loaded,

  /// Taken from `initialSelectedItemCache` because the ID is selected and
  /// missing from the loaded page.
  initialSelectedItemCache,
}

/// Added and removed IDs.
///
/// `onChange` gets one mutation (a row, `setSelected`, or one bulk command)
/// each time it is accepted. Toggling the same ID on and off is two calls.
/// `onClose` gets the net of those explicit adds and removes versus the seed
/// captured at open. An ID selected and deselected again is omitted. Empty
/// means do not write.
///
/// Persist both sets together, by ID. An ID can stay selected while missing
/// from the current `itemsLoader` page. A load error or empty search is not a
/// deletion.
///
/// A later `initialSelectedIds` update reseeds checkboxes; it does not change
/// the close baseline and does not create intent. Both callbacks may be set.
/// `onChange` does not consume session intent, so `onClose` still reports the
/// same net. Persist in only one of them.
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
