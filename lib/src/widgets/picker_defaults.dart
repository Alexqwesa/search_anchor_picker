import 'package:flutter/material.dart';
import 'package:search_anchor_picker/src/picker_status.dart';
import 'package:search_anchor_picker/src/raw/picker_config.dart';
import 'package:search_anchor_picker/src/raw/widgets/picker_defaults.dart';

/// Default picker row shell: checkbox, membership icon, title, subtitle.
///
/// Use from `itemBuilder` when you want custom title/subtitle without
/// replacing the whole row.
class DefaultPickerItemTile extends StatelessWidget {
  /// Creates a default row with related-list membership icon support.
  const DefaultPickerItemTile({
    required this.selected,
    required this.onToggle,
    required this.selectionMode,
    super.key,
    this.label,
    this.title,
    this.subtitle,
    this.leading,
    this.auxiliaryMembership,
    this.relatedListItemStatus,
    this.tooltip,
    this.enabled,
  }) : assert(
         label != null || title != null,
         'Provide label or title.',
       );

  final bool selected;
  final ValueChanged<bool> onToggle;
  final String? label;
  final Widget? title;
  final Widget? subtitle;
  final Widget? leading;

  /// Auxiliary-list membership represented by the default leading icon.
  ///
  /// A custom [leading] takes precedence. Ignored when
  /// [relatedListItemStatus] is set. Null means that no auxiliary-list
  /// concept applies to this item.
  final PickerAuxiliaryMembership? auxiliaryMembership;

  /// Preferred source for membership icon and default [enabled].
  final PickerRelatedListItemStatus? relatedListItemStatus;

  final SelectionMode selectionMode;
  final String? tooltip;

  /// Whether the row accepts taps.
  ///
  /// When null, [PickerRelatedListItemStatus.selectable] is used, or true.
  final bool? enabled;

  @override
  Widget build(BuildContext context) {
    final status = relatedListItemStatus;
    final membership =
        status?.auxiliaryMembership ?? auxiliaryMembership;
    return RawDefaultPickerItemTile(
      selected: selected,
      onToggle: onToggle,
      label: label,
      title: title,
      subtitle: subtitle,
      selectionMode: selectionMode,
      tooltip: tooltip,
      enabled: enabled ?? status?.selectable ?? true,
      leading:
          leading ??
          Icon(
            switch (membership) {
              PickerAuxiliaryMembership.notMember => Icons.person_outline,
              PickerAuxiliaryMembership.unknown => Icons.person_search_outlined,
              PickerAuxiliaryMembership.member || null => Icons.person,
            },
          ),
    );
  }
}
