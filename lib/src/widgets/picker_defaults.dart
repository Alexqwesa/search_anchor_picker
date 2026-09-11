import 'dart:async';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:search_anchor_picker/src/picker_config.dart';
import 'package:search_anchor_picker/src/widgets/overflow_tooltip_text.dart';
import 'package:search_anchor_picker/src/widgets/passive_tooltip.dart';

/// Effective visual values used by the default picker view widgets.
class PickerViewStyle {
  const PickerViewStyle({
    required this.backgroundColor,
    required this.elevation,
    required this.surfaceTintColor,
    required this.shape,
    required this.dividerColor,
    required this.headerTextStyle,
    required this.headerHintStyle,
    required this.constraints,
    required this.viewPadding,
    required this.barPadding,
    required this.shrinkWrap,
  });

  factory PickerViewStyle.resolve(
    BuildContext context, {
    required bool isFullScreen,
    Color? backgroundColor,
    double? elevation,
    Color? surfaceTintColor,
    BorderSide? side,
    OutlinedBorder? shape,
    TextStyle? headerTextStyle,
    TextStyle? headerHintStyle,
    Color? dividerColor,
    BoxConstraints? constraints,
    EdgeInsetsGeometry? viewPadding,
    EdgeInsetsGeometry? barPadding,
    bool? shrinkWrap,
  }) {
    final colors = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final viewTheme = SearchViewTheme.of(context);
    var effectiveShape =
        shape ??
        viewTheme.shape ??
        (isFullScreen
            ? const RoundedRectangleBorder()
            : const RoundedRectangleBorder(
                borderRadius: BorderRadius.all(Radius.circular(28)),
              ));
    final effectiveSide = side ?? viewTheme.side;
    if (!isFullScreen && effectiveSide != null) {
      effectiveShape = effectiveShape.copyWith(side: effectiveSide);
    }

    final effectiveHeaderStyle =
        headerTextStyle ??
        viewTheme.headerTextStyle ??
        textTheme.bodyLarge?.copyWith(color: colors.onSurface);

    return PickerViewStyle(
      backgroundColor:
          backgroundColor ??
          viewTheme.backgroundColor ??
          colors.surfaceContainerHigh,
      elevation: elevation ?? viewTheme.elevation ?? 6,
      surfaceTintColor:
          surfaceTintColor ?? viewTheme.surfaceTintColor ?? Colors.transparent,
      shape: effectiveShape,
      dividerColor:
          dividerColor ??
          viewTheme.dividerColor ??
          DividerTheme.of(context).color ??
          colors.outline,
      headerTextStyle: effectiveHeaderStyle,
      headerHintStyle:
          headerHintStyle ??
          viewTheme.headerHintStyle ??
          effectiveHeaderStyle?.copyWith(color: colors.onSurfaceVariant),
      constraints:
          constraints ??
          viewTheme.constraints ??
          const BoxConstraints(minWidth: 360, minHeight: 240),
      viewPadding: isFullScreen
          ? EdgeInsets.zero
          : viewPadding ?? viewTheme.padding,
      barPadding:
          barPadding ??
          viewTheme.barPadding ??
          const EdgeInsets.symmetric(horizontal: 8),
      shrinkWrap:
          !isFullScreen && (shrinkWrap ?? viewTheme.shrinkWrap ?? false),
    );
  }

  final Color backgroundColor;
  final double elevation;
  final Color surfaceTintColor;
  final OutlinedBorder shape;
  final Color dividerColor;
  final TextStyle? headerTextStyle;
  final TextStyle? headerHintStyle;
  final BoxConstraints constraints;
  final EdgeInsetsGeometry? viewPadding;
  final EdgeInsetsGeometry barPadding;
  final bool shrinkWrap;
}

class DefaultPickerTrigger extends StatelessWidget {
  const DefaultPickerTrigger({
    required this.onPressed,
    super.key,
    this.icon,
    this.tooltip,
    this.iconSize,
    this.enabled = true,
  });

  final VoidCallback onPressed;
  final Widget? icon;
  final String? tooltip;
  final double? iconSize;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      iconSize: iconSize,
      tooltip: tooltip,
      icon: icon ?? const Icon(Icons.search),
      onPressed: enabled ? onPressed : null,
    );
  }
}

class DefaultPickerSearchField extends StatelessWidget {
  const DefaultPickerSearchField({
    required this.controller,
    required this.close,
    required this.style,
    required this.isFullScreen,
    super.key,
    this.focusNode,
    this.clearQuery,
    this.leading,
    this.trailing,
    this.hintText,
    this.headerHeight,
    this.textCapitalization,
    this.onChanged,
    this.onSubmitted,
    this.textInputAction,
    this.keyboardType,
    this.smartDashesType,
    this.smartQuotesType,
  });

  final SearchController controller;
  final FocusNode? focusNode;
  final VoidCallback? clearQuery;
  final VoidCallback close;
  final PickerViewStyle style;
  final bool isFullScreen;
  final Widget? leading;
  final Iterable<Widget>? trailing;
  final String? hintText;
  final double? headerHeight;
  final TextCapitalization? textCapitalization;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final TextInputAction? textInputAction;
  final TextInputType? keyboardType;
  final SmartDashesType? smartDashesType;
  final SmartQuotesType? smartQuotesType;

  @override
  Widget build(BuildContext context) {
    final localizations = MaterialLocalizations.of(context);
    final effectiveHeight =
        headerHeight ??
        SearchViewTheme.of(context).headerHeight ??
        (isFullScreen ? 72.0 : null);
    return SafeArea(
      top: isFullScreen,
      bottom: false,
      child: ListenableBuilder(
        listenable: controller,
        builder: (context, _) {
          final defaultTrailing = controller.text.isEmpty
              ? const <Widget>[]
              : <Widget>[
                  IconButton(
                    tooltip: localizations.clearButtonTooltip,
                    icon: const Icon(Icons.close),
                    onPressed: clearQuery ?? controller.clear,
                  ),
                ];
          return SearchBar(
            controller: controller,
            focusNode: focusNode,
            autoFocus: true,
            constraints: effectiveHeight == null
                ? null
                : BoxConstraints.tightFor(height: effectiveHeight),
            padding: WidgetStatePropertyAll(style.barPadding),
            hintText: hintText ?? localizations.searchFieldLabel,
            leading:
                leading ??
                IconButton(
                  tooltip: localizations.backButtonTooltip,
                  icon: const BackButtonIcon(),
                  onPressed: close,
                ),
            trailing: trailing ?? defaultTrailing,
            elevation: const WidgetStatePropertyAll(0),
            backgroundColor: const WidgetStatePropertyAll(Colors.transparent),
            overlayColor: const WidgetStatePropertyAll(Colors.transparent),
            textStyle: WidgetStatePropertyAll(style.headerTextStyle),
            hintStyle: WidgetStatePropertyAll(style.headerHintStyle),
            textCapitalization: textCapitalization ?? TextCapitalization.none,
            onChanged: onChanged,
            onSubmitted: onSubmitted,
            textInputAction: textInputAction,
            keyboardType: keyboardType,
            smartDashesType: smartDashesType,
            smartQuotesType: smartQuotesType,
          );
        },
      ),
    );
  }
}

class DefaultPickerItemTile extends StatelessWidget {
  const DefaultPickerItemTile({
    required this.selected,
    required this.onToggle,
    required this.label,
    required this.mode,
    super.key,
    this.leading,
    this.tooltip,
  });

  final bool selected;
  final ValueChanged<bool> onToggle;
  final String label;
  final Widget? leading;
  final PickerMode mode;
  final String? tooltip;

  @override
  Widget build(BuildContext context) {
    final labelWidget = tooltip == null
        ? OverflowTooltipText(label)
        : PassiveTooltip(
            message: tooltip!,
            child: Text(label, maxLines: 1, overflow: TextOverflow.ellipsis),
          );
    return CheckboxListTile(
      checkboxShape: mode == PickerMode.multi ? null : const CircleBorder(),
      value: selected,
      onChanged: (value) => onToggle(value ?? false),
      title: Row(
        children: [
          leading ?? const Icon(Icons.person),
          const SizedBox(width: 6),
          Expanded(child: labelWidget),
        ],
      ),
    );
  }
}

class DefaultPickerResultsList extends StatelessWidget {
  const DefaultPickerResultsList({
    required this.controller,
    required this.children,
    required this.shrinkWrap,
    super.key,
  });

  final ScrollController controller;
  final List<Widget> children;
  final bool shrinkWrap;

  @override
  Widget build(BuildContext context) {
    return ScrollConfiguration(
      behavior: const MaterialScrollBehavior().copyWith(
        dragDevices: const {
          PointerDeviceKind.mouse,
          PointerDeviceKind.touch,
          PointerDeviceKind.trackpad,
        },
      ),
      child: Scrollbar(
        controller: controller,
        thumbVisibility: true,
        interactive: true,
        child: ListView(
          controller: controller,
          padding: const EdgeInsets.symmetric(vertical: 8),
          shrinkWrap: shrinkWrap,
          children: children,
        ),
      ),
    );
  }
}

class DefaultPickerLoading extends StatelessWidget {
  const DefaultPickerLoading({super.key});

  @override
  Widget build(BuildContext context) => const Center(
    child: Padding(
      padding: EdgeInsets.all(32),
      child: CircularProgressIndicator(strokeWidth: 2),
    ),
  );
}

class DefaultPickerEmpty extends StatelessWidget {
  const DefaultPickerEmpty({required this.query, super.key});

  final String query;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Text(query.isEmpty ? 'No items' : 'No results'),
      ),
    );
  }
}

class DefaultPickerError extends StatelessWidget {
  const DefaultPickerError({required this.retry, super.key});

  final VoidCallback retry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: FilledButton.tonalIcon(
          onPressed: retry,
          icon: const Icon(Icons.refresh),
          label: const Text('Retry'),
        ),
      ),
    );
  }
}

class DefaultPickerView extends StatelessWidget {
  const DefaultPickerView({
    required this.searchField,
    required this.divider,
    required this.results,
    required this.shrinkWrap,
    super.key,
  });

  final Widget searchField;
  final Widget divider;
  final Widget results;
  final bool shrinkWrap;

  @override
  Widget build(BuildContext context) => Column(
    mainAxisSize: MainAxisSize.min,
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      searchField,
      divider,
      Flexible(fit: shrinkWrap ? FlexFit.loose : FlexFit.tight, child: results),
    ],
  );
}

class DefaultPickerViewSurface extends StatelessWidget {
  const DefaultPickerViewSurface({
    required this.style,
    required this.child,
    super.key,
  });

  final PickerViewStyle style;
  final Widget child;

  @override
  Widget build(BuildContext context) => Material(
    clipBehavior: Clip.antiAlias,
    shape: style.shape,
    color: style.backgroundColor,
    surfaceTintColor: style.surfaceTintColor,
    elevation: style.elevation,
    child: child,
  );
}

class DefaultPickerUnselectWarning extends StatelessWidget {
  const DefaultPickerUnselectWarning({required this.label, super.key});

  final String label;

  @override
  Widget build(BuildContext context) => Text('$label is currently in use.');
}

Future<bool> showDefaultPickerUnselectConfirmation(
  BuildContext context, {
  required String label,
}) async {
  final overlay = Overlay.of(context, rootOverlay: true);
  final completer = Completer<bool>();
  late final OverlayEntry entry;

  void close(bool result) {
    if (completer.isCompleted) return;
    entry.remove();
    completer.complete(result);
  }

  entry = OverlayEntry(
    builder: (context) {
      final localizations = MaterialLocalizations.of(context);
      return Material(
        color: Colors.black54,
        child: Center(
          child: AlertDialog(
            title: const Text('Remove item?'),
            content: Text(
              '$label is currently in use. Removing it might affect other data.',
            ),
            actions: [
              TextButton(
                onPressed: () => close(false),
                child: Text(localizations.cancelButtonLabel),
              ),
              TextButton(
                onPressed: () => close(true),
                child: const Text('Remove'),
              ),
            ],
          ),
        ),
      );
    },
  );
  overlay.insert(entry);
  return completer.future;
}
