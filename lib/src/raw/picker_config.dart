import 'dart:async';

import 'package:flutter/foundation.dart' show ValueListenable;
import 'package:flutter/widgets.dart';
import 'package:search_anchor_picker/src/debouncer.dart';
import 'package:search_anchor_picker/src/raw/picker_builders.dart';
import 'package:search_anchor_picker/src/raw/search_anchor_picker.dart'
    show GenericRawSearchAnchorPicker, RawSearchAnchorPicker;
import 'package:search_anchor_picker/src/raw/widgets/sub_picker_tile.dart'
    show RawSubPickerTile;

export 'package:search_anchor_picker/src/raw/picker_selection.dart';

typedef ItemsLoader<T> =
    Future<List<T>> Function(BuildContext context, String query);

const _copyUnset = Object();

T? _copyOrKeep<T>(Object? value, T? current) {
  return identical(value, _copyUnset) ? current : value as T?;
}

/// How the default search field combines `itemsLoader` and local filtering.
enum PickerSearchMode {
  /// Load on open, refresh, `reloadKey`, and `listenable`. Typing filters
  /// the loaded snapshot with `searchTermsOf` (or `labelOf` if omitted).
  local,

  /// Reload `itemsLoader` with the search-field text and show that page as-is.
  /// `searchTermsOf` is unused.
  remote,

  /// Reload `itemsLoader` with the search-field text, then filter that page
  /// locally with `searchTermsOf`.
  hybrid
  ;

  /// Whether the default search field should call `itemsLoader` on text changes.
  bool get reloadsOnQuery => this != PickerSearchMode.local;

  /// Whether the overlay should hide loaded rows that miss `searchTermsOf`.
  bool get filtersLocally => this != PickerSearchMode.remote;
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
/// One picker widget may bind this instance. [open] / [close] / [isOpen] then
/// control that widget, like `SearchController` for a SearchAnchor.
/// [isAttached] is whether a picker is bound. Binding a second picker throws.
/// [copyWith] returns an unbound copy so two widgets can share loaders
/// without sharing the bind.
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
    required this.itemsLoader,
    required this.idOf,
    required this.labelOf,
    this.searchTermsOf,
    this.searchMode = PickerSearchMode.local,
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

  VoidCallback? _onOpen;
  void Function([String? reason])? _onClose;
  bool Function()? _isOpen;

  /// Binds [open] / [close] / [isOpen] to one picker.
  ///
  /// Called by [GenericRawSearchAnchorPicker]. A second bind from another
  /// picker throws; use [copyWith] for an unbound copy.
  void bindPicker({
    required VoidCallback onOpen,
    required void Function([String? reason]) onClose,
    required bool Function() isOpen,
  }) {
    if ((_onOpen != null && !identical(_onOpen, onOpen)) ||
        (_onClose != null && !identical(_onClose, onClose))) {
      throw StateError(
        'This PickerConfig is already bound to a picker. '
        'Use copyWith() for another widget; the copy is unbound.',
      );
    }
    _onOpen = onOpen;
    _onClose = onClose;
    _isOpen = isOpen;
  }

  /// Clears control callbacks if they belong to this picker.
  void unbindPicker({
    required VoidCallback onOpen,
    required void Function([String? reason]) onClose,
  }) {
    if (identical(_onOpen, onOpen)) {
      _onOpen = null;
      _isOpen = null;
    }
    if (identical(_onClose, onClose)) _onClose = null;
  }

  /// Whether a picker widget is currently bound to this config.
  bool get isAttached => _onOpen != null && _onClose != null;

  /// Whether the bound picker overlay is open.
  ///
  /// Requires [isAttached].
  bool get isOpen {
    assert(isAttached, 'PickerConfig.isOpen requires a bound picker.');
    return _isOpen!();
  }

  /// Programmatically open the bound picker.
  ///
  /// Requires [isAttached]. A config binds to at most one
  /// [RawSearchAnchorPicker] (or [RawSubPickerTile]).
  void open() {
    assert(isAttached, 'PickerConfig.open() requires a bound picker.');
    _onOpen!();
  }

  /// Programmatically close the bound picker.
  ///
  /// Requires [isAttached]. A config binds to at most one
  /// [RawSearchAnchorPicker] (or [RawSubPickerTile]).
  void close([String? reason]) {
    assert(isAttached, 'PickerConfig.close() requires a bound picker.');
    _onClose!(reason);
  }

  /// Search/display loader.
  ///
  /// Called on open (`query` is `''`), [GenericRawPickerController.refresh],
  /// and [reloadKey]/[listenable] changes. In [PickerSearchMode.remote] and
  /// [PickerSearchMode.hybrid], the default search field also reloads with
  /// the box text (including clear). [PickerSearchMode.local] loads once and
  /// filters the snapshot. A custom
  /// [GenericRawSearchAnchorPicker.searchFieldBuilder] only needs to use the
  /// given controller as query text; the picker watches that text while open.
  /// Open and close the overlay with [open] / [close].
  ///
  /// Remote search should debounce that callback (or the API behind it). The
  /// picker does not. Use [Debouncer] or an equivalent gate:
  ///
  /// ```dart
  /// final debounce = Debouncer();
  ///
  /// Future<List<Person>> searchPeople(String query) {
  ///   if (query.isEmpty) return api.searchPeople(query);
  ///   return debounce.run(() => api.searchPeople(query));
  /// }
  ///
  /// PickerConfig(
  ///   searchMode: PickerSearchMode.remote,
  ///   itemsLoader: (context, query) => searchPeople(query),
  /// )
  /// ```
  final ItemsLoader<T> itemsLoader;

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

  /// Local search strings for [T]. Unused in [PickerSearchMode.remote].
  ///
  /// [PickerSearchMode.local] and [PickerSearchMode.hybrid] keep a row when
  /// any term contains the lowercase query. When null, [labelOf] is used.
  final Iterable<String> Function(T)? searchTermsOf;

  /// Whether typing reloads [itemsLoader], filters the loaded page, or both.
  ///
  /// Defaults to [PickerSearchMode.local].
  final PickerSearchMode searchMode;

  /// Whether [item] should stay visible for the current lowercase [query].
  bool matchesQuery(T item, String query) {
    if (!searchMode.filtersLocally || query.isEmpty) return true;
    final terms = searchTermsOf?.call(item) ?? [labelOf(item)];
    return terms.any((term) => term.toLowerCase().contains(query));
  }

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
  /// reloads [itemsLoader]. A closed picker always loads with the latest
  /// configuration when it next opens.
  final Object? reloadKey;

  /// Rebuilds the open overlay without calling [itemsLoader].
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

  /// Copies this config. The copy is unbound.
  ///
  /// Omitted nullable fields are kept. Pass `null` to clear them, for example
  /// `copyWith(listenable: null)`. [open] and [close] stay on this instance.
  GenericRawPickerConfig<T, K> copyWith({
    ItemsLoader<T>? itemsLoader,
    K Function(T)? idOf,
    String Function(T)? labelOf,
    Object? searchTermsOf = _copyUnset,
    PickerSearchMode? searchMode,
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
      itemsLoader: itemsLoader ?? this.itemsLoader,
      idOf: idOf ?? this.idOf,
      labelOf: labelOf ?? this.labelOf,
      searchTermsOf: _copyOrKeep(searchTermsOf, this.searchTermsOf),
      searchMode: searchMode ?? this.searchMode,
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
    required super.itemsLoader,
    required super.idOf,
    required super.labelOf,
    super.searchTermsOf,
    super.searchMode,
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
    ItemsLoader<T>? itemsLoader,
    int Function(T)? idOf,
    String Function(T)? labelOf,
    Object? searchTermsOf = _copyUnset,
    PickerSearchMode? searchMode,
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
      itemsLoader: itemsLoader,
      idOf: idOf,
      labelOf: labelOf,
      searchTermsOf: searchTermsOf,
      searchMode: searchMode,
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
      itemsLoader: copied.itemsLoader,
      idOf: copied.idOf,
      labelOf: copied.labelOf,
      searchTermsOf: copied.searchTermsOf,
      searchMode: copied.searchMode,
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
