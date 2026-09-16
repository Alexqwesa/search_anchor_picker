import 'package:flutter/material.dart';
import 'package:search_anchor_picker/src/picker_config.dart';
import 'package:search_anchor_picker/src/picker_status.dart';
import 'package:search_anchor_picker/src/raw/widgets/sub_picker_tile.dart';
import 'package:search_anchor_picker/src/related_list_item.dart';

/// Optional effect that a sub-picker result applies to parent pending selection.
///
/// Auxiliary-list membership and parent selection are independent by default.
/// These effects update only the currently open parent's pending checkboxes
/// after a successfully persisted child delta, or after close when the child
/// is local-only. They do not persist parent selection or create parent
/// persistence deltas.
enum SubPickerParentSelectionEffect {
  /// Do not modify the parent picker's pending selection.
  none,

  /// Check IDs added to the sub-list in the open parent picker.
  selectAdded,

  /// Uncheck removed IDs in the open parent picker.
  deselectRemoved,

  /// Mirror the child's membership delta into the open parent picker.
  ///
  /// This does not make the parent selection equal the child selection.
  mirror,
}

void _applyParentEffect<T, K>(
  GenericPickerController<T, K>? parentController,
  SubPickerParentSelectionEffect parentSelectionEffect,
  Set<K> added,
  Set<K> removed,
) {
  switch (parentSelectionEffect) {
    case SubPickerParentSelectionEffect.none:
      break;
    case SubPickerParentSelectionEffect.selectAdded:
      if (added.isNotEmpty) parentController!.syncPending(added: added);
    case SubPickerParentSelectionEffect.deselectRemoved:
      if (removed.isNotEmpty) parentController!.syncPending(removed: removed);
    case SubPickerParentSelectionEffect.mirror:
      parentController!.syncPending(added: added, removed: removed);
  }
}

/// Optional convenience tile for a picker nested in another picker's header.
class GenericSubPickerTile<T, K> extends GenericRawSubPickerTile<T, K> {
  // `selectionMode` and `itemBuilder` are captured to wrap related-list status.
  // ignore: use_super_parameters
  GenericSubPickerTile({
    required super.title,
    required GenericPickerConfig<T, K> config,
    required super.initialSelectedIds,
    super.key,
    this.parentController,
    this.parentSelectionEffect = SubPickerParentSelectionEffect.none,
    super.icon,
    super.canChangeSelection,
    super.persistence,
    super.onFinish,
    SelectionMode selectionMode = SelectionMode.multi,
    super.leading,
    super.subtitle,
    super.trailing,
    super.triggerBuilder,
    super.headerBuilder,
    Widget Function(
      BuildContext,
      T,
      bool,
      PickerRelatedListItemStatus,
      VoidCallback,
    )?
    itemBuilder,
    super.resultsBuilder,
    super.searchFieldBuilder,
    super.loadingBuilder,
    super.emptyBuilder,
    super.emptyText,
    super.noResultsText,
    super.errorBuilder,
    super.viewBuilder,
    super.viewSurfaceBuilder,
    super.menuOffset,
    super.menuOffsetAnimationDuration,
    super.isFullScreen,
    super.viewLeading,
    super.viewTrailing,
    super.viewHintText,
    super.viewBackgroundColor,
    super.viewElevation,
    super.viewSurfaceTintColor,
    super.viewSide,
    super.viewShape,
    super.viewBarPadding,
    super.headerHeight,
    super.headerTextStyle,
    super.headerHintStyle,
    super.dividerColor,
    super.viewConstraints,
    super.viewPadding,
    super.shrinkWrap,
  }) : assert(
         parentSelectionEffect == SubPickerParentSelectionEffect.none ||
             parentController != null,
         'parentController is required when parentSelectionEffect modifies selection.',
       ),
       super(
         config: config,
         selectionMode: selectionMode,
         itemBuilder: relatedListRowBuilder(config, selectionMode, itemBuilder),
         canUnselect: (context, item) {
           return relatedListCanUnselect(context, config, item);
         },
         onDeltaPersisted:
             parentSelectionEffect == SubPickerParentSelectionEffect.none
             ? null
             : (delta) {
                 _applyParentEffect(
                   parentController,
                   parentSelectionEffect,
                   delta.added,
                   delta.removed,
                 );
               },
       );

  /// Parent controller used only when [parentSelectionEffect] modifies selection.
  final GenericPickerController<T, K>? parentController;

  /// Explicit effect of sub-list changes on the parent pending selection.
  final SubPickerParentSelectionEffect parentSelectionEffect;
}

class SubPickerTile<T> extends GenericSubPickerTile<T, int> {
  SubPickerTile({
    required super.title,
    required super.config,
    required super.initialSelectedIds,
    super.key,
    super.icon,
    super.parentController,
    super.parentSelectionEffect,
    super.canChangeSelection,
    super.persistence,
    super.onFinish,
    super.selectionMode,
    super.leading,
    super.subtitle,
    super.trailing,
    super.triggerBuilder,
    super.headerBuilder,
    super.itemBuilder,
    super.resultsBuilder,
    super.searchFieldBuilder,
    super.loadingBuilder,
    super.emptyBuilder,
    super.emptyText,
    super.noResultsText,
    super.errorBuilder,
    super.viewBuilder,
    super.viewSurfaceBuilder,
    super.menuOffset,
    super.menuOffsetAnimationDuration,
    super.isFullScreen,
    super.viewLeading,
    super.viewTrailing,
    super.viewHintText,
    super.viewBackgroundColor,
    super.viewElevation,
    super.viewSurfaceTintColor,
    super.viewSide,
    super.viewShape,
    super.viewBarPadding,
    super.headerHeight,
    super.headerTextStyle,
    super.headerHintStyle,
    super.dividerColor,
    super.viewConstraints,
    super.viewPadding,
    super.shrinkWrap,
  });
}
