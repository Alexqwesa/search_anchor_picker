import 'package:flutter/widgets.dart';
import 'package:search_anchor_picker/src/picker_status.dart';
import 'package:search_anchor_picker/src/raw/picker_builders.dart';
import 'package:search_anchor_picker/src/raw/picker_config.dart';

export 'package:search_anchor_picker/src/raw/picker_config.dart'
    show
        CloseQueryBehavior,
        GenericRawPickerController,
        LoadItems,
        PickerDelta,
        PickerSelectionResult,
        PickerUnselectPolicy,
        RawPickerController,
        SelectionMode;

const _reloadKeyNotProvided = Object();

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
    String Function(T)? tooltipOf,
    Widget Function(T)? iconOf,
    int Function(T a, T b)? comparator,
    String? title,
    bool? selectedFirst,
    Listenable? listenable,
    Object? reloadKey = _reloadKeyNotProvided,
    Listenable? rebuildListenable,
    PickerUnselectPolicy? unselectPolicy,
    GenericUnselectWarningBuilder<T>? unselectWarningBuilder,
    GenericUnselectConfirmationBuilder<T>? unselectConfirmationBuilder,
    PickerRelatedListItemStatus Function(T)? relatedListItemStatusOf,
    Listenable? relatedListItemStatusListenable,
  }) {
    final nextStatusListenable =
        relatedListItemStatusListenable ??
        rebuildListenable ??
        this.relatedListItemStatusListenable;
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
      reloadKey: identical(reloadKey, _reloadKeyNotProvided)
          ? this.reloadKey
          : reloadKey,
      relatedListItemStatusOf:
          relatedListItemStatusOf ?? this.relatedListItemStatusOf,
      relatedListItemStatusListenable: nextStatusListenable,
      unselectPolicy: unselectPolicy ?? this.unselectPolicy,
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
    String Function(T)? tooltipOf,
    Widget Function(T)? iconOf,
    int Function(T a, T b)? comparator,
    String? title,
    bool? selectedFirst,
    Listenable? listenable,
    Object? reloadKey = _reloadKeyNotProvided,
    Listenable? rebuildListenable,
    PickerUnselectPolicy? unselectPolicy,
    GenericUnselectWarningBuilder<T>? unselectWarningBuilder,
    GenericUnselectConfirmationBuilder<T>? unselectConfirmationBuilder,
    PickerRelatedListItemStatus Function(T)? relatedListItemStatusOf,
    Listenable? relatedListItemStatusListenable,
  }) {
    final nextStatusListenable =
        relatedListItemStatusListenable ??
        rebuildListenable ??
        this.relatedListItemStatusListenable;
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
      reloadKey: identical(reloadKey, _reloadKeyNotProvided)
          ? this.reloadKey
          : reloadKey,
      relatedListItemStatusOf:
          relatedListItemStatusOf ?? this.relatedListItemStatusOf,
      relatedListItemStatusListenable: nextStatusListenable,
      unselectPolicy: unselectPolicy ?? this.unselectPolicy,
      unselectWarningBuilder:
          unselectWarningBuilder ?? this.unselectWarningBuilder,
      unselectConfirmationBuilder:
          unselectConfirmationBuilder ?? this.unselectConfirmationBuilder,
    );
  }
}

typedef GenericPickerController<T, K> = GenericRawPickerController<T, K>;
typedef PickerController<T> = RawPickerController<T>;
