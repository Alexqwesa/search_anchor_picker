import 'package:flutter/material.dart';
import 'package:search_anchor_picker/src/raw/picker_selection.dart';

/// Builds one picker row.
typedef PickerItemBuilder<T> =
    Widget Function(
      BuildContext context,
      T item,
      bool isSelected,
      PickerItemSource source,
      VoidCallback toggle,
    );

/// Builds the open search field.
///
/// [controller] is query text. Use [close] to dismiss the overlay
/// (`PickerConfig.close()` from outside).
typedef PickerSearchFieldBuilder =
    Widget Function(
      BuildContext context,
      TextEditingController controller,
      VoidCallback close,
    );

typedef PickerLoadingBuilder = Widget Function(BuildContext context);

typedef PickerEmptyBuilder =
    Widget Function(BuildContext context, String query);

typedef PickerErrorBuilder =
    Widget Function(
      BuildContext context,
      Object error,
      StackTrace stackTrace,
      VoidCallback retry,
    );

typedef PickerResultsBuilder =
    Widget Function(
      BuildContext context,
      ScrollController controller,
      List<Widget> children,
    );

class PickerViewParts {
  const PickerViewParts({
    required this.searchField,
    required this.divider,
    required this.results,
  });

  final Widget searchField;
  final Widget divider;
  final Widget results;
}

typedef PickerViewBuilder =
    Widget Function(BuildContext context, PickerViewParts parts);

typedef PickerViewSurfaceBuilder =
    Widget Function(BuildContext context, Widget child, bool isFullScreen);

typedef GenericUnselectWarningBuilder<T> =
    Widget Function(BuildContext context, T item);

typedef GenericUnselectConfirmationBuilder<T> =
    Future<bool> Function(BuildContext context, T item);

/// What to do when `onClose` throws.
enum CloseSaveFailedAction {
  /// Keep the popup open so the user can change selection and try again.
  updateSelection,

  /// Close the popup without persisting the session.
  closeWithoutSaving,
}

/// Wraps the open picker view while `onClose` is running.
typedef PickerCloseSavingBuilder =
    Widget Function(BuildContext context, Widget child);

/// Asks whether to keep editing or close after `onClose` throws.
typedef PickerCloseSaveFailedBuilder =
    Future<CloseSaveFailedAction> Function(
      BuildContext context,
      Object error,
      StackTrace stackTrace,
    );
