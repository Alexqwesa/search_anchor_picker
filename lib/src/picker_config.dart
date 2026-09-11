import 'package:flutter/foundation.dart' show ValueListenable;
import 'package:flutter/widgets.dart';
import 'package:search_anchor_picker/search_anchor_picker.dart'
    show GenericSearchAnchorPicker, SearchAnchorPicker, SubPickerTile;
import 'package:search_anchor_picker/src/picker_builders.dart';

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
/// **External `initialSelectedIds`:**
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
    internalOnOpen?.call();
  }

  /// Programmatically close the picker.
  ///
  /// Requires the [PickerConfig] to be currently attached to a [SearchAnchorPicker] (or [SubPickerTile]).
  void close([String? reason]) {
    internalOnClose?.call(reason);
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

typedef OnFinish = GenericOnFinish<int>;

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

/// Controller exposed to headerBuilder for selection state and commands.
///
/// Bulk and single-item selection methods record explicit user intent for
/// [GenericSearchAnchorPicker.onFinish]. Use [syncPending] only when external code
/// already owns persistence and the popup must mirror those changes without
/// producing another `added` or `removed` delta.
class GenericPickerController<T, K> {
  GenericPickerController({
    required ValueNotifier<Set<K>> pendingN,
    required this.idOf,
    required void Function([String? reason]) close,
    required this.mode,
    required this.getKey,
    required VoidCallback refresh,
    required Iterable<K> Function() loadedIds,
    required Iterable<K> Function() filteredIds,
    required void Function(Set<K> before, Set<K> after) recordDelta,
  }) : _pendingN = pendingN,
       _close = close,
       _refresh = refresh,
       _loadedIds = loadedIds,
       _filteredIds = filteredIds,
       _recordDelta = recordDelta;

  final ValueNotifier<Set<K>> _pendingN;
  final K Function(T) idOf;
  final void Function([String? reason]) _close;
  final GlobalKey Function(Object id) getKey;
  final VoidCallback _refresh;
  final Iterable<K> Function() _loadedIds;
  final Iterable<K> Function() _filteredIds;
  final void Function(Set<K> before, Set<K> after) _recordDelta;
  final PickerMode mode;

  /// Current in-popup selection. The returned set cannot be mutated.
  Set<K> get pendingIds => Set<K>.unmodifiable(_pendingN.value);

  /// Listen to in-popup selection changes from custom header UI.
  ValueListenable<Set<K>> get pendingIdsListenable => _pendingN;

  /// Applies externally-owned changes without recording persistence intent.
  ///
  /// This is intended for synchronization after external state was already
  /// changed, such as reflecting a nested picker's result in its parent popup.
  /// IDs present in both collections end unselected.
  void syncPending({
    Iterable<K> added = const [],
    Iterable<K> removed = const [],
  }) {
    final additions = added.toSet();
    final removals = removed.toSet();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _pendingN.value = {..._pendingN.value, ...additions}..removeAll(removals);
    });
  }

  void selectLoaded() => _addIds(_loadedIds());

  void clearLoaded() => _removeIds(_loadedIds());

  void selectFiltered() => _addIds(_filteredIds());

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
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _recordDelta(_pendingN.value, ids);
      _pendingN.value = ids;
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

class PickerController<T> extends GenericPickerController<T, int> {
  PickerController({
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
