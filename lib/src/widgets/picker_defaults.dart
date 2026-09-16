import 'package:flutter/material.dart';
import 'package:search_anchor_picker/src/picker_status.dart';
import 'package:search_anchor_picker/src/raw/picker_config.dart';
import 'package:search_anchor_picker/src/raw/widgets/picker_defaults.dart';

/// Higher-level picker item tile with picker-specific semantics.
///
/// Wraps [RawDefaultPickerItemTile] and maps [auxiliaryMembership] to the
/// default leading icon when [leading] is omitted.
class DefaultPickerItemTile extends StatelessWidget {
  const DefaultPickerItemTile({
    required this.selected,
    required this.onToggle,
    required this.label,
    required this.selectionMode,
    super.key,
    this.leading,
    this.auxiliaryMembership,
    this.tooltip,
  });

  final bool selected;
  final ValueChanged<bool> onToggle;
  final String label;
  final Widget? leading;

  /// Auxiliary-list membership represented by the default leading icon.
  ///
  /// A custom [leading] takes precedence. Null means that no auxiliary-list
  /// concept applies to this item.
  final PickerAuxiliaryMembership? auxiliaryMembership;

  final SelectionMode selectionMode;
  final String? tooltip;

  @override
  Widget build(BuildContext context) {
    return RawDefaultPickerItemTile(
      selected: selected,
      onToggle: onToggle,
      label: label,
      selectionMode: selectionMode,
      tooltip: tooltip,
      leading:
          leading ??
          Icon(
            switch (auxiliaryMembership) {
              PickerAuxiliaryMembership.notMember => Icons.person_outline,
              PickerAuxiliaryMembership.unknown => Icons.person_search_outlined,
              PickerAuxiliaryMembership.member || null => Icons.person,
            },
          ),
    );
  }
}
