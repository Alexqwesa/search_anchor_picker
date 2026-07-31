import 'package:flutter/widgets.dart';
import 'package:generic_search_selector/src/picker_builders.dart';

typedef LoadItems<T> = Future<List<T>> Function(BuildContext context);

/// Configuration for a [SearchAnchorPicker].
///
/// This object is intentionally "meta": the picker UI is generic, and you adapt
/// it to a domain model [T] by providing small functions:
/// - how to load items
/// - how to identify an item
/// - how to render / search an item
///
/// In-overlay selection lives in an internal [ValueNotifier] while the popup is open.
///
/// **External [initialSelectedIds]:**
/// - When the popup is **closed**, parent updates re-seed the next open.
/// - When the popup is **open**, [GenericSearchAnchorPicker] may still sync
///   `initialSelectedIds` into pending so nested sub-pickers can reflect
///   membership changes. External reseeds never create add/remove deltas.
class GenericPickerConfig<T, K> {
  GenericPickerConfig({
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
    this.unselectBehavior = UnselectBehavior.allow,
    this.isItemInUse,
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
  /// Requires the [PickerConfig] to be currently attached to a [SearchAnchorPicker] (or [SubPickerTile]).
  void open() {
    if (internalOnOpen != null) {
      internalOnOpen!();
    }
  }

  /// Programmatically close the picker.
  ///
  /// Requires the [PickerConfig] to be currently attached to a [SearchAnchorPicker] (or [SubPickerTile]).
  void close([String? reason]) {
    if (internalOnClose != null) {
      internalOnClose!(reason);
    }
  }

  /// Loads the current display/search result.
  ///
  /// Called when the picker overlay opens (and may be called again if you choose
  /// to refresh). Keep it fast; cache upstream if needed.
  final LoadItems<T> loadItems;

  /// Returns a stable identifier for [T].
  ///
  /// Used for:
  /// - selection state (`Set<K>`)
  /// - computing added diffs and explicit removals on close
  /// - equality / matching across reloads
  final K Function(T) idOf;

  /// Returns the primary label shown in the list for [T].
  ///
  /// The picker will render this label with ellipsis. If [tooltipOf] is null,
  /// the default behavior is to show a tooltip only when this label overflows.
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
  /// - If provided, the picker shows this tooltip (typically always).
  /// - If null, the picker falls back to a default behavior:
  ///   show a tooltip only when the [labelOf] text is ellipsized (overflow).
  final String Function(T)? tooltipOf;

  /// Optional leading icon builder for [T].
  ///
  /// If null, the picker uses a default icon.
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

  /// If provided, the overlay will rebuild when this notifies.
  /// Use this when your items source is a ChangeNotifier / ValueNotifier / etc.
  final Listenable? listenable;

  /// Strategy to handle deselection of items that might be "in use".
  final UnselectBehavior unselectBehavior;

  /// Predicate to check if an item is currently "in use" externally.
  /// If true, [unselectBehavior] will be triggered on deselection.
  final bool Function(T)? isItemInUse;

  /// Overrides the default warning content for [UnselectBehavior.showWarning].
  final GenericUnselectWarningBuilder<T>? unselectWarningBuilder;

  /// Owns confirmation UX for [UnselectBehavior.alert] when provided.
  final GenericUnselectConfirmationBuilder<T>? unselectConfirmationBuilder;

  GenericPickerConfig<T, K> copyWith({
    LoadItems<T>? loadItems,
    K Function(T)? idOf,
    String Function(T)? labelOf,
    Iterable<String> Function(T)? searchTermsOf,
    String Function(T)? tooltipOf,
    Widget Function(T)? iconOf,
    int Function(T a, T b)? comparator,
    String? title,
    bool? selectedFirst,
    Listenable? listenable,
    UnselectBehavior? unselectBehavior,
    bool Function(T)? isItemInUse,
    GenericUnselectWarningBuilder<T>? unselectWarningBuilder,
    GenericUnselectConfirmationBuilder<T>? unselectConfirmationBuilder,
  }) {
    return GenericPickerConfig<T, K>(
      loadItems: loadItems ?? this.loadItems,
      idOf: idOf ?? this.idOf,
      labelOf: labelOf ?? this.labelOf,
      searchTermsOf: searchTermsOf ?? this.searchTermsOf,
      tooltipOf: tooltipOf ?? this.tooltipOf,
      iconOf: iconOf ?? this.iconOf,
      comparator: comparator ?? this.comparator,
      title: title ?? this.title,
      selectedFirst: selectedFirst ?? this.selectedFirst,
      listenable: listenable ?? this.listenable,
      unselectBehavior: unselectBehavior ?? this.unselectBehavior,
      isItemInUse: isItemInUse ?? this.isItemInUse,
      unselectWarningBuilder:
          unselectWarningBuilder ?? this.unselectWarningBuilder,
      unselectConfirmationBuilder:
          unselectConfirmationBuilder ?? this.unselectConfirmationBuilder,
    );
  }
}

class PickerConfig<T> extends GenericPickerConfig<T, int> {
  PickerConfig({
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
    super.unselectBehavior = UnselectBehavior.allow,
    super.isItemInUse,
    super.unselectWarningBuilder,
    super.unselectConfirmationBuilder,
  });

  @override
  PickerConfig<T> copyWith({
    LoadItems<T>? loadItems,
    int Function(T)? idOf,
    String Function(T)? labelOf,
    Iterable<String> Function(T)? searchTermsOf,
    String Function(T)? tooltipOf,
    Widget Function(T)? iconOf,
    int Function(T a, T b)? comparator,
    String? title,
    bool? selectedFirst,
    Listenable? listenable,
    UnselectBehavior? unselectBehavior,
    bool Function(T)? isItemInUse,
    GenericUnselectWarningBuilder<T>? unselectWarningBuilder,
    GenericUnselectConfirmationBuilder<T>? unselectConfirmationBuilder,
  }) {
    return PickerConfig<T>(
      loadItems: loadItems ?? this.loadItems,
      idOf: idOf ?? this.idOf,
      labelOf: labelOf ?? this.labelOf,
      searchTermsOf: searchTermsOf ?? this.searchTermsOf,
      tooltipOf: tooltipOf ?? this.tooltipOf,
      iconOf: iconOf ?? this.iconOf,
      comparator: comparator ?? this.comparator,
      title: title ?? this.title,
      selectedFirst: selectedFirst ?? this.selectedFirst,
      listenable: listenable ?? this.listenable,
      unselectBehavior: unselectBehavior ?? this.unselectBehavior,
      isItemInUse: isItemInUse ?? this.isItemInUse,
      unselectWarningBuilder:
          unselectWarningBuilder ?? this.unselectWarningBuilder,
      unselectConfirmationBuilder:
          unselectConfirmationBuilder ?? this.unselectConfirmationBuilder,
    );
  }
}

typedef GenericOnFinish<K> =
    Future<void> Function({required List<K> added, required List<K> removed});

/// Called when the popup closes with the full final in-picker selection.
///
/// This is a replace-all persistence API. If the final selection is empty,
/// [GenericSearchAnchorPicker] requires explicit empty-save confirmation before
/// calling this callback.
@Deprecated(
  'Unsafe with server-side filtering or pagination. Use onFinish for explicit '
  'deltas or onToggle for per-item persistence.',
)
typedef GenericOnFinishReplaceAll<K> = Future<void> Function(List<K> finalIds);

typedef OnFinish = GenericOnFinish<int>;
@Deprecated(
  'Unsafe with server-side filtering or pagination. Use OnFinish or onToggle.',
)
typedef OnFinishReplaceAll = GenericOnFinishReplaceAll<int>;

enum PickerMode { multi, radio, radioToggle }

/// How [GenericSearchAnchorPicker.onToggle] interacts with checkbox updates.
enum OnToggleMode {
  /// Await [GenericSearchAnchorPicker.onToggle] before updating in-overlay selection.
  /// Return `false` from [GenericSearchAnchorPicker.onToggle] to reject the toggle.
  awaitGate,

  /// Update the checkbox immediately, then run [GenericSearchAnchorPicker.onToggle].
  /// If it returns `false`, the toggle is reverted. Use for async persistence without
  /// blocking the UI.
  optimistic,
}

enum UnselectBehavior {
  block,
  showWarning,
  alert,
  allow,
  // keepSelected,
}

/// Actions exposed to headerBuilder so callers never need InheritedWidget lookups.
///
/// This is intentionally thin:
/// - It operates on the in-overlay pending selection only.
/// - It never calls setState; it only updates [pendingN] and closes the picker.
class GenericPickerActions<T, K> {
  GenericPickerActions({
    required this.pendingN,
    required this.idOf,
    required void Function([String? reason]) close,
    required this.mode,
    required this.getKey,
    required VoidCallback refresh,
    required Iterable<K> Function() loadedIds,
    required Iterable<K> Function() filteredIds,
    required void Function(Set<K> before, Set<K> after) recordDelta,
  }) : _close = close,
       _refresh = refresh,
       _loadedIds = loadedIds,
       _filteredIds = filteredIds,
       _recordDelta = recordDelta;

  final ValueNotifier<Set<K>> pendingN;
  final K Function(T) idOf;
  final void Function([String? reason]) _close;
  final GlobalKey Function(Object id) getKey;
  final VoidCallback _refresh;
  final Iterable<K> Function() _loadedIds;
  final Iterable<K> Function() _filteredIds;
  final void Function(Set<K> before, Set<K> after) _recordDelta;
  final PickerMode mode;

  Set<K> get pending => pendingN.value;

  void setPending(Set<K> ids) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      pendingN.value = ids;
    });
  }

  void selectAll(Iterable<K> ids) => setPending(ids.toSet());

  void pendingSelectLoaded() => _addIds(_loadedIds());

  void pendingClearLoaded() => _removeIds(_loadedIds());

  void pendingSelectFiltered() => _addIds(_filteredIds());

  void pendingClearFiltered() => _removeIds(_filteredIds());

  void selectLoadedAsDelta() => _addIds(_loadedIds(), asDelta: true);

  void clearLoadedAsDelta() => _removeIds(_loadedIds(), asDelta: true);

  void selectFilteredAsDelta() => _addIds(_filteredIds(), asDelta: true);

  void clearFilteredAsDelta() => _removeIds(_filteredIds(), asDelta: true);

  void toggleId(K id, bool next) {
    final s = {...pending};
    next ? s.add(id) : s.remove(id);
    setPending(s);
  }

  void toggleIdAsDelta(K id, bool next) {
    final s = {...pending};
    next ? s.add(id) : s.remove(id);
    _setPending(s, asDelta: true);
  }

  void _addIds(Iterable<K> ids, {bool asDelta = false}) {
    _setPending({...pending, ...ids}, asDelta: asDelta);
  }

  void _removeIds(Iterable<K> ids, {bool asDelta = false}) {
    final remove = ids.toSet();
    _setPending({...pending}..removeAll(remove), asDelta: asDelta);
  }

  void _setPending(Set<K> ids, {required bool asDelta}) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (asDelta) _recordDelta(pendingN.value, ids);
      pendingN.value = ids;
    });
  }

  void refresh() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _refresh();
    });
  }

  void close([String? reason]) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _close(reason);
    });
  }
}

class PickerActions<T> extends GenericPickerActions<T, int> {
  PickerActions({
    required super.pendingN,
    required super.idOf,
    required super.close,
    required super.mode,
    required super.getKey,
    required super.refresh,
    required super.loadedIds,
    required super.filteredIds,
    required super.recordDelta,
  });
}

enum CloseQueryBehavior { keep, clear }
