import 'package:flutter/material.dart';
import 'package:search_anchor_picker/src/picker_builders.dart';
import 'package:search_anchor_picker/src/picker_config.dart';
import 'package:search_anchor_picker/src/search_anchor_picker.dart';

/// Optional convenience tile for a picker nested in another picker's header.
class GenericSubPickerTile<T, K> extends StatelessWidget {
  const GenericSubPickerTile({
    super.key,
    required this.title,
    required this.config,
    required this.initialSelectedIds,
    this.icon,
    this.parentActions,
    this.onFinish,
    this.onFinishReplaceAll,
    this.showSaveEmptyButton = true,
    this.saveEmptyLabel,
    this.mode = PickerMode.multi,
    this.leading,
    this.subtitle,
    this.trailing,
    this.triggerBuilder,
    this.itemBuilder,
    this.resultsBuilder,
    this.searchFieldBuilder,
    this.loadingBuilder,
    this.emptyBuilder,
    this.errorBuilder,
    this.saveEmptyBuilder,
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
  }) : assert(title != null || triggerBuilder != null);

  final String? title;
  final GenericPickerConfig<T, K> config;
  final List<K> initialSelectedIds;
  final GenericPickerActions<T, K>? parentActions;
  final IconData? icon;
  final Widget? leading;
  final Widget? subtitle;
  final Widget? trailing;
  final PickerMode mode;
  final GenericOnFinish<K>? onFinish;

  @Deprecated(
    'Unsafe with server-side filtering or pagination. Use onFinish for deltas.',
  )
  final GenericOnFinishReplaceAll<K>? onFinishReplaceAll;

  final bool showSaveEmptyButton;
  final String? saveEmptyLabel;
  final Widget Function(BuildContext, VoidCallback, int)? triggerBuilder;
  final Widget Function(BuildContext, T, bool, VoidCallback)? itemBuilder;
  final PickerResultsBuilder? resultsBuilder;
  final PickerSearchFieldBuilder? searchFieldBuilder;
  final PickerLoadingBuilder? loadingBuilder;
  final PickerEmptyBuilder? emptyBuilder;
  final PickerErrorBuilder? errorBuilder;
  final PickerSaveEmptyBuilder? saveEmptyBuilder;
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

  @override
  Widget build(BuildContext context) {
    return GenericSearchAnchorPicker<T, K>(
      config: config,
      initialSelectedIds: initialSelectedIds,
      onFinish: ({required added, required removed}) async {
        if (parentActions != null) {
          parentActions!.syncPending(removed: removed);
        }
        await onFinish?.call(added: added, removed: removed);
      },
      // ignore: deprecated_member_use_from_same_package
      onFinishReplaceAll: onFinishReplaceAll,
      showSaveEmptyButton: showSaveEmptyButton,
      saveEmptyLabel: saveEmptyLabel,
      mode: mode,
      itemBuilder: itemBuilder,
      resultsBuilder: resultsBuilder,
      searchFieldBuilder: searchFieldBuilder,
      loadingBuilder: loadingBuilder,
      emptyBuilder: emptyBuilder,
      errorBuilder: errorBuilder,
      saveEmptyBuilder: saveEmptyBuilder,
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
      triggerBuilder: (context, open, tick) {
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
      },
    );
  }
}

class SubPickerTile<T> extends GenericSubPickerTile<T, int> {
  const SubPickerTile({
    super.key,
    required super.title,
    required super.config,
    required super.initialSelectedIds,
    super.icon,
    super.parentActions,
    super.onFinish,
    super.onFinishReplaceAll,
    super.showSaveEmptyButton,
    super.saveEmptyLabel,
    super.mode,
    super.leading,
    super.subtitle,
    super.trailing,
    super.triggerBuilder,
    super.itemBuilder,
    super.resultsBuilder,
    super.searchFieldBuilder,
    super.loadingBuilder,
    super.emptyBuilder,
    super.errorBuilder,
    super.saveEmptyBuilder,
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
