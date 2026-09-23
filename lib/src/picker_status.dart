import 'package:flutter/widgets.dart';
import 'package:search_anchor_picker/src/raw/picker_config.dart';
import 'package:search_anchor_picker/src/raw/widgets/picker_defaults.dart';

export 'package:search_anchor_picker/src/raw/picker_config.dart'
    show PickerUnselectPolicy;

/// Membership of an item in an auxiliary list managed alongside this picker.
///
/// This is independent of whether the item is selected in the current picker.
/// A partial list can establish [member] for IDs it contains, but absence from
/// that list is [unknown], not [notMember]. An authoritative per-item flag may
/// establish either [member] or [notMember] without loading the entire list.
enum PickerAuxiliaryMembership {
  /// The item belongs to the auxiliary list.
  member,

  /// The item does not belong to the auxiliary list.
  notMember,

  /// Membership cannot be determined from the available data.
  unknown,
}

/// An item's membership and selection rules involving a related list.
///
/// The related list may be a parent list or an auxiliary sub-list.
/// [auxiliaryMembership] describes membership in that auxiliary list.
/// [selectable] makes the row inert. [unselectPolicy] controls unselect
/// attempts on a selectable row, for example when the item is still used by a
/// parent list.
/// None of these fields change the picker's pending selection by itself.
class PickerRelatedListItemStatus {
  /// Creates related-list status with optional auxiliary-list membership.
  const PickerRelatedListItemStatus({
    this.auxiliaryMembership,
    this.selectable = true,
    this.unselectPolicy = PickerUnselectPolicy.allow,
  });

  /// Membership in an auxiliary list, or null when none applies.
  ///
  /// Use [PickerAuxiliaryMembership.unknown] when a partial result cannot prove
  /// whether the item is absent from the full auxiliary list. This is display
  /// only; `onChange` / `onClose` do not receive it.
  final PickerAuxiliaryMembership? auxiliaryMembership;

  /// Whether the user may change this item's checkbox at all.
  ///
  /// `false` renders the default row disabled, ignores taps on it, and leaves
  /// the item out of bulk commands in both directions, so a rule the user
  /// cannot satisfy reads as an inactive row instead of a checkbox that moves
  /// and springs back. An item absent from the current `itemsLoader` result has
  /// no status and is not filtered.
  ///
  /// Use [unselectPolicy] instead when the row stays usable and only removal
  /// needs a warning or a confirmation.
  final bool selectable;

  /// Policy used when this item is currently selected and is being unselected.
  final PickerUnselectPolicy unselectPolicy;
}

Future<bool> applyRelatedListUnselectPolicy<T, K>(
  BuildContext context,
  GenericRawPickerConfig<T, K> config,
  T item,
  PickerUnselectPolicy policy,
) {
  return applyUnselectPolicy(context, config, item, policy);
}
