import 'dart:async';

import 'package:flutter/foundation.dart' show ValueListenable;
import 'package:flutter/widgets.dart';
import 'package:search_anchor_picker/src/raw/picker_builders.dart';
import 'package:search_anchor_picker/src/raw/search_anchor_picker.dart'
    show GenericRawSearchAnchorPicker, RawSearchAnchorPicker;
import 'package:search_anchor_picker/src/raw/widgets/sub_picker_tile.dart'
    show RawSubPickerTile;

export 'package:search_anchor_picker/src/raw/picker_selection.dart';

typedef LoadItems<T> =
    Future<List<T>> Function(BuildContext context, String query);

const _copyUnset = Object();

T? _copyOrKeep<T>(Object? value, T? current) {
  return identical(value, _copyUnset) ? current : value as T?;
}

/// Policy applied when the user tries to unselect an item.
enum PickerUnselectPolicy {
  /// Allow the item to be unselected immediately.
  allow,

  /// Keep the item selected and show the localized in-use warning.
  blocked,

  /// Ask for confirmation before allowing the item to be unselected.
  confirm,
}

/// Configuration for a [RawSearchAnchorPicker].
///
/// This object is intentionally "meta": the picker UI is generic, and you adapt
/// it to a domain model [T] by providing small functions:
/// - how to load items
/// - how to identify an item
/// - how to render / search an item
///
/// In-overlay selection lives in an internal [ValueNotifier] while the popup is open.
///
/// **External `initialSelectedIds`:**
/// - When the popup is **closed**, parent updates re-seed the next open.
/// - When the popup is **open**, [GenericRawSearchAnchorPicker] may still sync
///   `initialSelectedIds` into pending so nested sub-pickers can reflect
///   membership changes. External reseeds never create add/remove deltas.
class GenericRawPickerConfig<T, K> {
  GenericRawPickerConfig({
    required this.loadItems,
    required this.idOf,
    required this.labelOf,
    required this.searchTermsOf,
    this.tooltipOf,
    this.iconOf,
    this.comparator,
    this.title,
    this.selectedFirst = true,
    this.listenable,
    this.reloadKey,
    this.rebuildListenable,
    this.unselectPolicy = PickerUnselectPolicy.allow,
    this.unselectWarningBuilder,
    this.unselectConfirmationBuilder,
  });

  /// internal callback to open the picker. (Set by SearchAnchorPicker).
  /// Do not set this manually.
  VoidCallback? internalOnOpen;

  /// Internal callback to close the picker. (Set by SearchAnchorPicker).
  /// Do not set this manually.
  void Function([String? reason])? internalOnClose;

  /// Programmatically open the picker.
  ///
  /// Requires the config to be currently attached to a [RawSearchAnchorPicker]
  /// (or [RawSubPickerTile]).
  void open() {
    internalOnOpen?.call();
  }

  /// Programmatically close the picker.
  ///
  /// Requires the config to be currently attached to a [RawSearchAnchorPicker]
  /// (or [RawSubPickerTile]).
  void close([String? reason]) {
    internalOnClose?.call(reason);
  }

  /// Search/display loader. This is the search callback.
  ///
  /// The picker calls this on open (`query` is `''`), on
  /// [GenericRawPickerController.refresh], when [reloadKey]/[listenable]
  /// changes, and when the default search field text changes or is cleared
  /// (`query` is that text). Ignore `query` to load a full catalog and let the
  /// overlay filter locally. A custom
  /// [GenericRawSearchAnchorPicker.searchFieldBuilder] must call
  /// [GenericRawPickerController.refresh] itself if typing should reload.
  final LoadItems<T> loadItems;

  /// Returns a stable identifier for [T].
  ///
  /// Used for:
  /// - selection state (`Set<K>`)
  /// - computing added diffs and explicit removals on close
  /// - equality / matching across reloads
  final K Function(T) idOf;

  /// Returns the primary label shown by the default item row for [T].
  ///
  /// The default row renders this label with ellipsis and, when [tooltipOf] is
  /// null, shows a tooltip only if it overflows. A custom
  /// [GenericRawSearchAnchorPicker.itemBuilder] renders its own row and is not
  /// given this label automatically. [labelOf] may still be called for default
  /// unselect warnings and confirmation dialogs.
  final String Function(T) labelOf;

  /// Returns a set of searchable strings for [T].
  ///
  /// The search box filters items by checking if any term contains the
  /// lowercase query substring.
  ///
  /// Tips:
  /// - include localized names
  /// - include email / code fields if users search by them
  final Iterable<String> Function(T) searchTermsOf;

  /// Optional tooltip text for [T].
  ///
  /// - If provided, the default item row shows this tooltip.
  /// - If null, the default row shows a tooltip only when [labelOf] overflows.
  /// - This callback is not called by the picker when a custom
  ///   [GenericRawSearchAnchorPicker.itemBuilder] replaces the default row.
  final String Function(T)? tooltipOf;

  /// Optional leading icon builder for [T].
  ///
  /// If null, the default item row uses a person icon. This callback is not
  /// called by the picker when a custom
  /// [GenericRawSearchAnchorPicker.itemBuilder] replaces the default row.
  final Widget Function(T)? iconOf;

  /// Optional comparator used to sort items.
  ///
  /// Sorting is applied when computing the stable in-overlay order:
  /// - if [selectedFirst] is true: selected-at-open items are sorted, and the
  ///   remaining items are sorted separately.
  /// - if [selectedFirst] is false: all items are sorted together.
  final int Function(T a, T b)? comparator;

  /// Optional title used for trigger tooltips, etc.
  final String? title;

  /// If true, the overlay list is ordered as:
  /// 1) items selected at popup-open
  /// 2) all remaining items
  ///
  /// This order is computed once per open (stable while the overlay is open).
  final bool selectedFirst;

  /// If provided, the open picker reloads items when this notifies.
  ///
  /// The listener is attached only while the picker is open.
  final Listenable? listenable;

  /// An explicit revision for declarative item reloads.
  ///
  /// Replacing [GenericRawPickerConfig] alone only rebinds its configuration and
  /// does not reload items. While the picker is open, changing this value
  /// reloads [loadItems]. A closed picker always loads with the latest
  /// configuration when it next opens.
  final Object? reloadKey;

  /// Rebuilds the open overlay without calling [loadItems].
  ///
  /// The listener is attached only while the picker is open. Use this for
  /// visual or policy state that is independent of the loaded item list.
  final Listenable? rebuildListenable;

  /// Policy used when [GenericRawSearchAnchorPicker.canUnselect] is omitted.
  final PickerUnselectPolicy unselectPolicy;

  /// Overrides the warning shown for [PickerUnselectPolicy.blocked].
  final GenericUnselectWarningBuilder<T>? unselectWarningBuilder;

  /// Owns confirmation UX for [PickerUnselectPolicy.confirm] when provided.
  final GenericUnselectConfirmationBuilder<T>? unselectConfirmationBuilder;

  /// Copies this config.
  ///
  /// Omitted nullable fields are kept. Pass `null` to clear them, for example
  /// `copyWith(listenable: null)`.
  GenericRawPickerConfig<T, K> copyWith({
    LoadItems<T>? loadItems,
    K Function(T)? idOf,
    String Function(T)? labelOf,
    Iterable<String> Function(T)? searchTermsOf,
    Object? tooltipOf = _copyUnset,
    Object? iconOf = _copyUnset,
    Object? comparator = _copyUnset,
    Object? title = _copyUnset,
    bool? selectedFirst,
    Object? listenable = _copyUnset,
    Object? reloadKey = _copyUnset,
    Object? rebuildListenable = _copyUnset,
    PickerUnselectPolicy? unselectPolicy,
    Object? unselectWarningBuilder = _copyUnset,
    Object? unselectConfirmationBuilder = _copyUnset,
  }) {
    return GenericRawPickerConfig<T, K>(
      loadItems: loadItems ?? this.loadItems,
      idOf: idOf ?? this.idOf,
      labelOf: labelOf ?? this.labelOf,
      searchTermsOf: searchTermsOf ?? this.searchTermsOf,
      tooltipOf: _copyOrKeep(tooltipOf, this.tooltipOf),
      iconOf: _copyOrKeep(iconOf, this.iconOf),
      comparator: _copyOrKeep(comparator, this.comparator),
      title: _copyOrKeep(title, this.title),
      selectedFirst: selectedFirst ?? this.selectedFirst,
      listenable: _copyOrKeep(listenable, this.listenable),
      reloadKey: _copyOrKeep(reloadKey, this.reloadKey),
      rebuildListenable: _copyOrKeep(rebuildListenable, this.rebuildListenable),
      unselectPolicy: unselectPolicy ?? this.unselectPolicy,
      unselectWarningBuilder: _copyOrKeep(
        unselectWarningBuilder,
        this.unselectWarningBuilder,
      ),
      unselectConfirmationBuilder: _copyOrKeep(
        unselectConfirmationBuilder,
        this.unselectConfirmationBuilder,
      ),
    );
  }
}

class RawPickerConfig<T> extends GenericRawPickerConfig<T, int> {
  RawPickerConfig({
    required super.loadItems,
    required super.idOf,
    required super.labelOf,
    required super.searchTermsOf,
    super.tooltipOf,
    super.iconOf,
    super.comparator,
    super.title,
    super.selectedFirst = true,
    super.listenable,
    super.reloadKey,
    super.rebuildListenable,
    super.unselectPolicy,
    super.unselectWarningBuilder,
    super.unselectConfirmationBuilder,
  });

  @override
  RawPickerConfig<T> copyWith({
    LoadItems<T>? loadItems,
    int Function(T)? idOf,
    String Function(T)? labelOf,
    Iterable<String> Function(T)? searchTermsOf,
    Object? tooltipOf = _copyUnset,
    Object? iconOf = _copyUnset,
    Object? comparator = _copyUnset,
    Object? title = _copyUnset,
    bool? selectedFirst,
    Object? listenable = _copyUnset,
    Object? reloadKey = _copyUnset,
    Object? rebuildListenable = _copyUnset,
    PickerUnselectPolicy? unselectPolicy,
    Object? unselectWarningBuilder = _copyUnset,
    Object? unselectConfirmationBuilder = _copyUnset,
  }) {
    final copied = super.copyWith(
      loadItems: loadItems,
      idOf: idOf,
      labelOf: labelOf,
      searchTermsOf: searchTermsOf,
      tooltipOf: tooltipOf,
      iconOf: iconOf,
      comparator: comparator,
      title: title,
      selectedFirst: selectedFirst,
      listenable: listenable,
      reloadKey: reloadKey,
      rebuildListenable: rebuildListenable,
      unselectPolicy: unselectPolicy,
      unselectWarningBuilder: unselectWarningBuilder,
      unselectConfirmationBuilder: unselectConfirmationBuilder,
    );
    return RawPickerConfig<T>(
      loadItems: copied.loadItems,
      idOf: copied.idOf,
      labelOf: copied.labelOf,
      searchTermsOf: copied.searchTermsOf,
      tooltipOf: copied.tooltipOf,
      iconOf: copied.iconOf,
      comparator: copied.comparator,
      title: copied.title,
      selectedFirst: copied.selectedFirst,
      listenable: copied.listenable,
      reloadKey: copied.reloadKey,
      rebuildListenable: copied.rebuildListenable,
      unselectPolicy: copied.unselectPolicy,
      unselectWarningBuilder: copied.unselectWarningBuilder,
      unselectConfirmationBuilder: copied.unselectConfirmationBuilder,
    );
  }
}

enum SelectionMode {
  /// Several IDs may be selected. The overlay stays open.
  multi,

  /// At most one ID. Tapping the selected row does not clear it.
  single,

  /// At most one ID. Tapping the selected row clears it.
  singleOptional,
}

/// Controller exposed to headerBuilder for selection state and commands.
///
/// Bulk and single-item selection methods record explicit user intent and take
/// the same path as a row toggle: one gate call, then one delta to the
/// picker's `onChange` and, at close, `onClose`. A bulk command is that delta
/// over many IDs, so save it as one write.
/// Use [syncPending] to copy an already-persisted external change into this
/// open picker's pending selection without producing another `added` or
/// `removed` delta.
class GenericRawPickerController<T, K> {
  GenericRawPickerController({
    required ValueNotifier<Set<K>> pendingN,
    required this.idOf,
    required void Function([String? reason]) close,
    required this.selectionMode,
    required this.getKey,
    required VoidCallback refresh,
    required Iterable<K> Function() loadedIds,
    required Iterable<K> Function() filteredIds,
    required Future<bool> Function(Set<K> added, Set<K> removed) applyDelta,
    bool Function()? isActive,
    ValueNotifier<int>? childSavingN,
  }) : _pendingN = pendingN,
       _close = close,
       _refresh = refresh,
       _loadedIds = loadedIds,
       _filteredIds = filteredIds,
       _applyDelta = applyDelta,
       _isActive = isActive,
       _childSavingN = childSavingN;

  final ValueNotifier<Set<K>> _pendingN;
  final K Function(T) idOf;
  final void Function([String? reason]) _close;
  final GlobalKey Function(Object id) getKey;
  final VoidCallback _refresh;
  final Iterable<K> Function() _loadedIds;
  final Iterable<K> Function() _filteredIds;
  final Future<bool> Function(Set<K> added, Set<K> removed) _applyDelta;
  final bool Function()? _isActive;
  final ValueNotifier<int>? _childSavingN;
  final SelectionMode selectionMode;

  /// Nested persist operations currently in flight for this open session.
  ValueListenable<int>? get childSavingListenable => _childSavingN;

  /// Starts parent search-field progress for a nested persist.
  ///
  /// Does not keep this picker open; close already waits for in-flight child
  /// `onChange` work.
  void beginChildSave() {
    if (_isActive?.call() == false) return;
    final notifier = _childSavingN;
    if (notifier == null) return;
    notifier.value++;
  }

  /// Ends parent search-field progress started by [beginChildSave].
  void endChildSave() {
    if (_isActive?.call() == false) return;
    final notifier = _childSavingN;
    if (notifier == null || notifier.value <= 0) return;
    notifier.value--;
  }

  /// Current in-popup selection. The returned set cannot be mutated.
  Set<K> get pendingIds => Set<K>.unmodifiable(_pendingN.value);

  /// Listen to in-popup selection changes from custom header UI.
  ValueListenable<Set<K>> get pendingIdsListenable => _pendingN;

  /// Applies an externally persisted delta to this open picker's pending IDs.
  ///
  /// This symmetrically adds [added] and removes [removed] from the temporary
  /// pending set. It does not mutate `initialSelectedIds` or caller state. It is
  /// intended for changes already persisted by a nested picker or another
  /// external owner, so it does not report the same intent through
  /// [GenericRawSearchAnchorPicker.onChange] or
  /// [GenericRawSearchAnchorPicker.onClose].
  /// If an ID appears in both collections, [removed] wins.
  /// Controllers supplied by a picker ignore deferred updates after that popup
  /// session closes; a late save cannot change a newly opened session.
  void syncPending({
    Iterable<K> added = const [],
    Iterable<K> removed = const [],
  }) {
    final additions = added.toSet();
    final removals = removed.toSet();
    _schedule(() {
      _pendingN.value = {..._pendingN.value, ...additions}..removeAll(removals);
    });
  }

  /// Selects every loaded ID as one delta.
  void selectLoaded() => _addIds(_loadedIds());

  /// Deselects every loaded ID as one delta.
  void clearLoaded() => _removeIds(_loadedIds());

  /// Selects the loaded IDs matching the current query as one delta.
  void selectFiltered() => _addIds(_filteredIds());

  /// Deselects the loaded IDs matching the current query as one delta.
  void clearFiltered() => _removeIds(_filteredIds());

  void setSelected(K id, bool selected) {
    final next = {...pendingIds};
    selected ? next.add(id) : next.remove(id);
    _setPendingAsDelta(next);
  }

  void _addIds(Iterable<K> ids) {
    _setPendingAsDelta({...pendingIds, ...ids});
  }

  void _removeIds(Iterable<K> ids) {
    final remove = ids.toSet();
    _setPendingAsDelta({...pendingIds}..removeAll(remove));
  }

  void _setPendingAsDelta(Set<K> ids) {
    _schedule(() {
      final before = _pendingN.value;
      unawaited(
        _applyDelta(ids.difference(before), before.difference(ids)),
      );
    });
  }

  void refresh() {
    _schedule(_refresh);
  }

  void close([String? reason]) {
    _schedule(() {
      _close(reason);
    });
  }

  void _schedule(VoidCallback callback) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_isActive?.call() != false) callback();
    });
    WidgetsBinding.instance.ensureVisualUpdate();
  }
}

class RawPickerController<T> extends GenericRawPickerController<T, int> {
  RawPickerController({
    required super.pendingN,
    required super.idOf,
    required super.close,
    required super.selectionMode,
    required super.getKey,
    required super.refresh,
    required super.loadedIds,
    required super.filteredIds,
    required super.applyDelta,
    super.isActive,
  });
}

/// Controls what happens to the search query when the picker closes.
enum CloseQueryBehavior {
  /// Preserve the query for the next time the picker opens.
  keep,

  /// Clear the query after closing the picker.
  clear,
}
