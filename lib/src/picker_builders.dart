import 'package:flutter/material.dart';

typedef PickerSearchFieldBuilder =
    Widget Function(
      BuildContext context,
      SearchController controller,
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

typedef PickerSaveEmptyBuilder =
    Widget Function(BuildContext context, VoidCallback save);

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
    required this.saveEmptyAction,
    required this.results,
  });

  final Widget searchField;
  final Widget divider;
  final Widget saveEmptyAction;
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
