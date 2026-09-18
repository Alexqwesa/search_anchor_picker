import 'dart:async';

import 'package:flutter/material.dart';
import 'package:search_anchor_picker/src/raw/picker_builders.dart';
import 'package:search_anchor_picker/src/raw/picker_config.dart';
import 'package:search_anchor_picker/src/raw/search_anchor_picker.dart';

/// Optional convenience tile for a picker nested in another picker's header.
///
/// This raw tile does not synchronize with a parent picker. Parent and child
/// selection effects are owned by the main package.
class GenericRawSubPickerTile<T, K> extends StatelessWidget {
  const GenericRawSubPickerTile({
    required this.title,
    required this.config,
    required this.initialSelectedIds,
    super.key,
    this.icon,
    this.isSelectable,
    this.onChange,
    this.onClose,
    this.closeSavingBuilder,
    this.closeSaveFailedBuilder,
    this.selectionMode = SelectionMode.multi,
    this.leading,
    this.subtitle,
    this.trailing,
    this.triggerBuilder,
    this.headerBuilder,
    this.itemBuilder,
    this.canUnselect,
    this.resultsBuilder,
    this.searchFieldBuilder,
    this.loadingBuilder,
    this.emptyBuilder,
    this.emptyText,
    this.noResultsText,
    this.errorBuilder,
    this.viewBuilder,
    this.viewSurfaceBuilder,
    this.menuOffset = const Offset(30, 30),
    this.menuOffsetAnimationDuration = const Duration(milliseconds: 120),
    this.isFullScreen,
    this.viewLeading,
    this.viewTrailing,
    this.viewHintText,
    this.viewBackgroundColor,
    this.viewElevation,
    this.viewSurfaceTintColor,
    this.viewSide,
    this.viewShape,
    this.viewBarPadding,
    this.headerHeight,
    this.headerTextStyle,
    this.headerHintStyle,
    this.dividerColor,
    this.viewConstraints,
    this.viewPadding,
    this.shrinkWrap,
  }) : assert(
         title != null || triggerBuilder != null,
         'Provide either title or triggerBuilder.',
       );

  final String? title;
  final GenericRawPickerConfig<T, K> config;
  final List<K> initialSelectedIds;
  final IconData? icon;
  final Widget? leading;
  final Widget? subtitle;
  final Widget? trailing;
  final SelectionMode selectionMode;
  final bool Function(T item)? isSelectable;
  final FutureOr<void> Function(PickerDelta<K> delta)? onChange;
  final FutureOr<void> Function(PickerSelectionResult<K> result)? onClose;
  final PickerCloseSavingBuilder? closeSavingBuilder;
  final PickerCloseSaveFailedBuilder? closeSaveFailedBuilder;
  final Widget Function(BuildContext, VoidCallback, int)? triggerBuilder;
  final List<Widget> Function(
    BuildContext,
    GenericRawPickerController<T, K>,
    List<T>,
  )?
  headerBuilder;
  final Widget Function(BuildContext, T, bool, VoidCallback)? itemBuilder;
  final Future<bool> Function(BuildContext context, T item)? canUnselect;
  final PickerResultsBuilder? resultsBuilder;
  final PickerSearchFieldBuilder? searchFieldBuilder;
  final PickerLoadingBuilder? loadingBuilder;
  final PickerEmptyBuilder? emptyBuilder;
  final String? emptyText;
  final String? noResultsText;
  final PickerErrorBuilder? errorBuilder;
  final PickerViewBuilder? viewBuilder;
  final PickerViewSurfaceBuilder? viewSurfaceBuilder;
  final Offset menuOffset;
  final Duration menuOffsetAnimationDuration;
  final bool? isFullScreen;
  final Widget? viewLeading;
  final Iterable<Widget>? viewTrailing;
  final String? viewHintText;
  final Color? viewBackgroundColor;
  final double? viewElevation;
  final Color? viewSurfaceTintColor;
  final BorderSide? viewSide;
  final OutlinedBorder? viewShape;
  final EdgeInsetsGeometry? viewBarPadding;
  final double? headerHeight;
  final TextStyle? headerTextStyle;
  final TextStyle? headerHintStyle;
  final Color? dividerColor;
  final BoxConstraints? viewConstraints;
  final EdgeInsetsGeometry? viewPadding;
  final bool? shrinkWrap;

  /// Nested picker. Public tiles pass related-list and parent-sync hooks into
  /// the constructor instead of replacing this method.
  @protected
  Widget createPicker() {
    return GenericRawSearchAnchorPicker<T, K>(
      config: config,
      initialSelectedIds: initialSelectedIds,
      isSelectable: isSelectable,
      onChange: onChange,
      onClose: onClose,
      closeSavingBuilder: closeSavingBuilder,
      closeSaveFailedBuilder: closeSaveFailedBuilder,
      headerBuilder: headerBuilder,
      selectionMode: selectionMode,
      itemBuilder: itemBuilder,
      canUnselect: canUnselect,
      resultsBuilder: resultsBuilder,
      searchFieldBuilder: searchFieldBuilder,
      loadingBuilder: loadingBuilder,
      emptyBuilder: emptyBuilder,
      emptyText: emptyText,
      noResultsText: noResultsText,
      errorBuilder: errorBuilder,
      viewBuilder: viewBuilder,
      viewSurfaceBuilder: viewSurfaceBuilder,
      menuOffset: menuOffset,
      menuOffsetAnimationDuration: menuOffsetAnimationDuration,
      isFullScreen: isFullScreen,
      viewLeading: viewLeading,
      viewTrailing: viewTrailing,
      viewHintText: viewHintText,
      viewBackgroundColor: viewBackgroundColor,
      viewElevation: viewElevation,
      viewSurfaceTintColor: viewSurfaceTintColor,
      viewSide: viewSide,
      viewShape: viewShape,
      viewBarPadding: viewBarPadding,
      headerHeight: headerHeight,
      headerTextStyle: headerTextStyle,
      headerHintStyle: headerHintStyle,
      dividerColor: dividerColor,
      viewConstraints: viewConstraints,
      viewPadding: viewPadding,
      shrinkWrap: shrinkWrap,
      triggerBuilder: buildTrigger,
    );
  }

  /// Default nested-row trigger used when [triggerBuilder] is omitted.
  @protected
  Widget buildTrigger(BuildContext context, VoidCallback open, int tick) {
    if (triggerBuilder != null) {
      return triggerBuilder!(context, open, tick);
    }
    return ListTile(
      leading: leading ?? (icon != null ? Icon(icon) : null),
      onTap: open,
      title: Text(title!),
      subtitle: subtitle,
      trailing: trailing,
      dense: true,
    );
  }

  @override
  Widget build(BuildContext context) => createPicker();
}

class RawSubPickerTile<T> extends GenericRawSubPickerTile<T, int> {
  const RawSubPickerTile({
    required super.title,
    required super.config,
    required super.initialSelectedIds,
    super.key,
    super.icon,
    super.onClose,
    super.closeSavingBuilder,
    super.closeSaveFailedBuilder,
    super.isSelectable,
    super.onChange,
    super.selectionMode,
    super.leading,
    super.subtitle,
    super.trailing,
    super.triggerBuilder,
    super.headerBuilder,
    super.itemBuilder,
    super.canUnselect,
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
