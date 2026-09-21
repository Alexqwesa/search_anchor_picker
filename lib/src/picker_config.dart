import 'package:flutter/widgets.dart';
import 'package:search_anchor_picker/src/picker_status.dart';
import 'package:search_anchor_picker/src/raw/picker_config.dart';

export 'package:search_anchor_picker/src/raw/picker_config.dart'
    show
        CloseQueryBehavior,
        GenericRawPickerController,
        LoadItems,
        PickerDelta,
        PickerUnselectPolicy,
        RawPickerController,
        SelectionMode;

const _copyUnset = Object();

T? _copyOrKeep<T>(Object? value, T? current) {
  return identical(value, _copyUnset) ? current : value as T?;
}

/// Configuration for SearchAnchorPicker.
///
/// Adds related-list membership and unselect policy on top of
/// [GenericRawPickerConfig]. Visual rebuilds from
/// [relatedListItemStatusListenable] do not reload [loadItems].
class GenericPickerConfig<T, K> extends GenericRawPickerConfig<T, K> {
  GenericPickerConfig({
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
    this.relatedListItemStatusOf,
    this.relatedListItemStatusListenable,
    super.unselectPolicy,
    super.unselectWarningBuilder,
    super.unselectConfirmationBuilder,
  }) : super(
         rebuildListenable: relatedListItemStatusListenable,
       );

  /// Returns an item's related-list membership and unselect policy.
  ///
  /// The related list can be a parent list or an auxiliary sub-list. Custom
  /// `itemBuilder` callbacks receive the complete [PickerRelatedListItemStatus].
  /// When null, items have no auxiliary-list membership and may be unselected.
  /// Loaded/search results remain display data; this state does not affect
  /// whether an item is present in the result list.
  final PickerRelatedListItemStatus Function(T)? relatedListItemStatusOf;

  /// Re-evaluates [relatedListItemStatusOf] when this notifies while open.
  ///
  /// Notify when related-list membership or usage changes. Unlike [listenable]
  /// and [reloadKey], this only repaints related-list status and
  /// does not call [loadItems]. The listener is attached only while open.
  final Listenable? relatedListItemStatusListenable;

  @override
  GenericPickerConfig<T, K> copyWith({
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
    Object? relatedListItemStatusOf = _copyUnset,
    Object? relatedListItemStatusListenable = _copyUnset,
  }) {
    return GenericPickerConfig<T, K>(
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
      relatedListItemStatusOf: _copyOrKeep(
        relatedListItemStatusOf,
        this.relatedListItemStatusOf,
      ),
      relatedListItemStatusListenable:
          identical(relatedListItemStatusListenable, _copyUnset)
          ? _copyOrKeep(
              rebuildListenable,
              this.relatedListItemStatusListenable,
            )
          : relatedListItemStatusListenable as Listenable?,
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
    super.reloadKey,
    super.relatedListItemStatusOf,
    super.relatedListItemStatusListenable,
    super.unselectPolicy,
    super.unselectWarningBuilder,
    super.unselectConfirmationBuilder,
  });

  @override
  PickerConfig<T> copyWith({
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
    Object? relatedListItemStatusOf = _copyUnset,
    Object? relatedListItemStatusListenable = _copyUnset,
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
      relatedListItemStatusOf: relatedListItemStatusOf,
      relatedListItemStatusListenable: relatedListItemStatusListenable,
    );
    return PickerConfig<T>(
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
      relatedListItemStatusOf: copied.relatedListItemStatusOf,
      relatedListItemStatusListenable: copied.relatedListItemStatusListenable,
      unselectPolicy: copied.unselectPolicy,
      unselectWarningBuilder: copied.unselectWarningBuilder,
      unselectConfirmationBuilder: copied.unselectConfirmationBuilder,
    );
  }
}

typedef GenericPickerController<T, K> = GenericRawPickerController<T, K>;
typedef PickerController<T> = RawPickerController<T>;
