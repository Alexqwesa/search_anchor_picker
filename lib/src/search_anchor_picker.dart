import 'dart:async';
import 'dart:math' as math;
import 'dart:ui' show clampDouble, lerpDouble;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:generic_search_selector/src/overlay_body.dart';
import 'package:generic_search_selector/src/picker_builders.dart';
import 'package:generic_search_selector/src/picker_config.dart';
import 'package:generic_search_selector/src/picker_debug.dart';
import 'package:generic_search_selector/src/selection_session.dart';
import 'package:generic_search_selector/src/widgets/picker_defaults.dart';

/// SearchAnchor-like picker with stable selection and nested popup support.
class GenericSearchAnchorPicker<T, K> extends StatefulWidget {
  const GenericSearchAnchorPicker({
    super.key,
    required this.config,
    required this.initialSelectedIds,
    this.mode = PickerMode.multi,
    this.onToggle,
    this.onToggleMode = OnToggleMode.awaitGate,
    this.onFinish,
    this.onFinishReplaceAll,
    this.showSaveEmptyButton = true,
    this.saveEmptyLabel,
    this.searchController,
    this.triggerBuilder,
    this.triggerChild,
    this.iconWhenEmpty,
    this.iconWhenSelected,
    this.iconSize,
    this.maxHeight,
    this.minWidth,
    this.headerBuilder,
    this.headerTiles,
    this.selectedFirst,
    this.closeQueryBehavior = CloseQueryBehavior.keep,
    this.itemBuilder,
    this.resultsBuilder,
    this.searchFieldBuilder,
    this.loadingBuilder,
    this.emptyBuilder,
    this.errorBuilder,
    this.saveEmptyBuilder,
    this.viewBuilder,
    this.viewSurfaceBuilder,
    this.menuOffset = Offset.zero,
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
    this.textCapitalization,
    this.viewOnChanged,
    this.viewOnSubmitted,
    this.viewOnClose,
    this.viewOnOpen,
    this.textInputAction,
    this.keyboardType,
    this.enabled = true,
    this.smartDashesType,
    this.smartQuotesType,
  });

  final GenericPickerConfig<T, K> config;
  final List<K> initialSelectedIds;
  final PickerMode mode;
  final Future<bool> Function(T item, bool nextSelected)? onToggle;
  final OnToggleMode onToggleMode;
  final GenericOnFinish<K>? onFinish;

  @Deprecated(
    'Unsafe with server-side filtering or pagination. Use onFinish for explicit '
    'deltas or onToggle for per-item persistence.',
  )
  final GenericOnFinishReplaceAll<K>? onFinishReplaceAll;

  final bool showSaveEmptyButton;
  final String? saveEmptyLabel;
  final SearchController? searchController;
  final Widget Function(BuildContext, VoidCallback, int)? triggerBuilder;
  final Widget? triggerChild;
  final Widget? iconWhenEmpty;
  final Widget? iconWhenSelected;
  final double? iconSize;

  @Deprecated('Use viewConstraints instead.')
  final double? maxHeight;

  @Deprecated('Use viewConstraints instead.')
  final double? minWidth;

  final List<Widget> Function(
    BuildContext context,
    GenericPickerActions<T, K> actions,
    List<T> allItems,
  )?
  headerBuilder;
  final List<Widget>? headerTiles;
  final bool? selectedFirst;
  final CloseQueryBehavior closeQueryBehavior;
  final Widget Function(
    BuildContext context,
    T item,
    bool isSelected,
    VoidCallback toggle,
  )?
  itemBuilder;
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
  final TextCapitalization? textCapitalization;
  final ValueChanged<String>? viewOnChanged;
  final ValueChanged<String>? viewOnSubmitted;
  final VoidCallback? viewOnClose;
  final VoidCallback? viewOnOpen;
  final TextInputAction? textInputAction;
  final TextInputType? keyboardType;
  final bool enabled;
  final SmartDashesType? smartDashesType;
  final SmartQuotesType? smartQuotesType;

  @override
  State<GenericSearchAnchorPicker<T, K>> createState() =>
      _GenericSearchAnchorPickerState<T, K>();
}

class SearchAnchorPicker<T> extends GenericSearchAnchorPicker<T, int> {
  const SearchAnchorPicker({
    super.key,
    required super.config,
    required super.initialSelectedIds,
    super.mode,
    super.onToggle,
    super.onToggleMode,
    super.onFinish,
    super.onFinishReplaceAll,
    super.showSaveEmptyButton,
    super.saveEmptyLabel,
    super.searchController,
    super.triggerBuilder,
    super.triggerChild,
    super.iconWhenEmpty,
    super.iconWhenSelected,
    super.iconSize,
    super.maxHeight,
    super.minWidth,
    super.headerBuilder,
    super.headerTiles,
    super.selectedFirst,
    super.closeQueryBehavior,
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
    super.textCapitalization,
    super.viewOnChanged,
    super.viewOnSubmitted,
    super.viewOnClose,
    super.viewOnOpen,
    super.textInputAction,
    super.keyboardType,
    super.enabled,
    super.smartDashesType,
    super.smartQuotesType,
  });
}

const Duration _openViewDuration = Duration(milliseconds: 600);
const Curve _openViewCurve = Curves.easeInOutCubicEmphasized;
const Curve _viewFadeCurve = Interval(0, 0.5);

abstract interface class _PickerBackTarget {
  void handleSystemBack();
}

final List<_PickerBackTarget> _openPickerStack = <_PickerBackTarget>[];

class _GenericSearchAnchorPickerState<T, K>
    extends State<GenericSearchAnchorPicker<T, K>>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver
    implements _PickerBackTarget {
  SearchController? _ownedController;
  FocusNode? _searchFocusNode;
  AnimationController? _openController;
  PickerSelectionSession<K>? _selectionSession;

  SearchController get _controller =>
      widget.searchController ?? (_ownedController ??= SearchController());
  FocusNode get _effectiveSearchFocusNode =>
      _searchFocusNode ??= FocusNode(debugLabel: 'Picker search');
  AnimationController get _animationController =>
      _openController ??= AnimationController(
        vsync: this,
        duration: _openViewDuration,
      )..addListener(() => _overlayEntry?.markNeedsBuild());
  PickerSelectionSession<K> get _selection => _selectionSession ??=
      PickerSelectionSession<K>(widget.initialSelectedIds);
  ValueNotifier<Set<K>> get _pendingN => _selection.pendingN;

  OverlayEntry? _overlayEntry;
  OverlayState? _overlayState;
  BuildContext? _triggerContext;
  Rect _openedAnchorRect = Rect.zero;
  bool _open = false;
  bool _allowReplaceAllEmpty = false;
  int _tick = 0;
  ValueNotifier<int>? _viewTickNotifier;
  ValueNotifier<int> get _viewTickN =>
      _viewTickNotifier ??= ValueNotifier<int>(0);
  Map<Object, GlobalKey>? _headerKeys;
  List<K> _stableIds = <K>[];
  List<T>? _itemsSnapshot;
  Object? _loadError;
  StackTrace? _loadStackTrace;
  bool _loading = false;
  int _loadGeneration = 0;
  VoidCallback? _listenableCallback;

  @override
  void initState() {
    super.initState();
    _bindConfigControl();
  }

  void _bindConfigControl() {
    widget.config.internalOnOpen = _requestOpen;
    widget.config.internalOnClose = ([reason]) => _close(reason);
  }

  void _unbindConfigControl(GenericPickerConfig<T, K> config) {
    if (config.internalOnOpen == _requestOpen) config.internalOnOpen = null;
    config.internalOnClose = null;
  }

  void _attachListenable(Listenable? listenable) {
    if (listenable == null) return;
    _listenableCallback = _reload;
    listenable.addListener(_listenableCallback!);
  }

  void _detachListenable(Listenable? listenable) {
    if (listenable == null || _listenableCallback == null) return;
    listenable.removeListener(_listenableCallback!);
    _listenableCallback = null;
  }

  @override
  void didUpdateWidget(covariant GenericSearchAnchorPicker<T, K> oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.config != widget.config) {
      _unbindConfigControl(oldWidget.config);
      _bindConfigControl();
      if (_open) {
        _detachListenable(oldWidget.config.listenable);
        _attachListenable(widget.config.listenable);
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted && _open) _reload();
        });
      }
    } else if (_open &&
        oldWidget.config.listenable != widget.config.listenable) {
      _detachListenable(oldWidget.config.listenable);
      _attachListenable(widget.config.listenable);
    }

    if (!_listEquals(oldWidget.initialSelectedIds, widget.initialSelectedIds)) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && _open) _selection.reseed(widget.initialSelectedIds);
      });
    }
  }

  @override
  void dispose() {
    _loadGeneration++;
    WidgetsBinding.instance.removeObserver(this);
    _openPickerStack.remove(this);
    _removeOverlay();
    _unbindConfigControl(widget.config);
    _detachListenable(widget.config.listenable);
    _selectionSession?.dispose();
    _viewTickNotifier?.dispose();
    _openController?.dispose();
    _searchFocusNode?.dispose();
    _ownedController?.dispose();
    super.dispose();
  }

  void _reload() {
    if (!mounted || !_open) return;
    final generation = ++_loadGeneration;
    _loading = true;
    _loadError = null;
    _loadStackTrace = null;
    _viewTickN.value++;

    Future<List<T>>.sync(() => widget.config.loadItems(context)).then(
      (items) {
        if (!mounted || !_open || generation != _loadGeneration) return;
        _itemsSnapshot = items;
        _loading = false;
        _viewTickN.value++;
      },
      onError: (Object error, StackTrace stackTrace) {
        if (!mounted || !_open || generation != _loadGeneration) return;
        _loading = false;
        _loadError = error;
        _loadStackTrace = stackTrace;
        _viewTickN.value++;
      },
    );
  }

  void _onOpen() {
    _selection.open(widget.initialSelectedIds);
    _allowReplaceAllEmpty = false;
    _stableIds = <K>[];
    _itemsSnapshot = null;
    _loadError = null;
    _loadStackTrace = null;
    setState(() => _open = true);
    _openPickerStack
      ..remove(this)
      ..add(this);
    _attachListenable(widget.config.listenable);
    WidgetsBinding.instance
      ..removeObserver(this)
      ..addObserver(this);
    _callLifecycleCallback('viewOnOpen', widget.viewOnOpen);
    _reload();
  }

  void _requestOpen() {
    if (_open || !widget.enabled) return;
    PickerDebug.log('SearchAnchorPicker: Opening picker');
    _onOpen();
    _showOverlay();
  }

  void _close([String? reason]) {
    if (!_open) return;
    PickerDebug.log('SearchAnchorPicker: Closing picker. Reason=$reason');
    setState(() => _open = false);
    WidgetsBinding.instance.removeObserver(this);
    _openPickerStack.remove(this);
    _loadGeneration++;
    final queryAtClose = _controller.text;
    final result = _selection.result();
    final allowEmpty = _allowReplaceAllEmpty;
    final onFinish = widget.onFinish;
    // ignore: deprecated_member_use_from_same_package
    final onFinishReplaceAll = widget.onFinishReplaceAll;

    FocusManager.instance.primaryFocus?.unfocus();
    _removeOverlay();
    _headerKeys = null;
    _detachListenable(widget.config.listenable);
    _callLifecycleCallback('viewOnClose', widget.viewOnClose);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (widget.closeQueryBehavior == CloseQueryBehavior.clear) {
        _controller.clear();
      } else {
        _controller.text = queryAtClose;
      }
      unawaited(
        _runCloseCallbacks(result, allowEmpty, onFinish, onFinishReplaceAll),
      );
    });
  }

  void _clearQuery() {
    _controller.clear();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && _open) {
        _searchFocusNode?.requestFocus();
      }
    });
  }

  Future<void> _runCloseCallbacks(
    PickerSelectionResult<K> result,
    bool allowEmpty,
    GenericOnFinish<K>? onFinish,
    GenericOnFinishReplaceAll<K>? onFinishReplaceAll,
  ) async {
    try {
      await onFinish?.call(
        added: result.added.toList(),
        removed: result.removed.toList(),
      );
    } catch (error, stackTrace) {
      _reportCallbackError('onFinish', error, stackTrace);
    }

    try {
      if (onFinishReplaceAll != null &&
          (result.finalIds.isNotEmpty || allowEmpty)) {
        await onFinishReplaceAll(result.finalIds.toList());
      }
    } catch (error, stackTrace) {
      _reportCallbackError('onFinishReplaceAll', error, stackTrace);
    } finally {
      if (mounted) setState(() => _tick++);
    }
  }

  void _callLifecycleCallback(String name, VoidCallback? callback) {
    if (callback == null) return;
    try {
      callback();
    } catch (error, stackTrace) {
      _reportCallbackError(name, error, stackTrace);
    }
  }

  void _reportCallbackError(String callback, Object error, StackTrace stack) {
    FlutterError.reportError(
      FlutterErrorDetails(
        exception: error,
        stack: stack,
        library: 'generic_search_selector',
        context: ErrorDescription('while running $callback'),
      ),
    );
  }

  @override
  void handleSystemBack() {
    if (_openPickerStack.isEmpty || !identical(_openPickerStack.last, this)) {
      return;
    }
    _close('systemBack');
  }

  @override
  Future<bool> didPopRoute() async {
    if (_openPickerStack.isEmpty) return false;
    _openPickerStack.last.handleSystemBack();
    return true;
  }

  void _showOverlay() {
    final overlay = Overlay.of(context);
    _overlayState = overlay;
    _openedAnchorRect = _currentAnchorRect();
    _animationController.value = 0;
    _overlayEntry = OverlayEntry(builder: (_) => _buildOverlayEntry());
    overlay.insert(_overlayEntry!);
    unawaited(_animationController.forward());
  }

  void _removeOverlay() {
    _overlayEntry?.remove();
    _overlayEntry = null;
    _overlayState = null;
  }

  Rect _currentAnchorRect() {
    final anchorBox = _triggerContext?.findRenderObject() as RenderBox?;
    final overlayBox = _overlayState?.context.findRenderObject() as RenderBox?;
    if (anchorBox == null || overlayBox == null) {
      return Offset.zero & Size(widget.minWidth ?? 360, 0);
    }
    final offset = anchorBox.localToGlobal(Offset.zero, ancestor: overlayBox);
    return offset & anchorBox.size;
  }

  GlobalKey _getKey(Object id) =>
      (_headerKeys ??= <Object, GlobalKey>{}).putIfAbsent(id, GlobalKey.new);

  void _computeStableIds(List<T> items) {
    final selectedFirst = widget.selectedFirst ?? widget.config.selectedFirst;
    if (!selectedFirst) {
      final sorted = [...items];
      if (widget.config.comparator != null) {
        sorted.sort(widget.config.comparator);
      }
      _stableIds = sorted.map(widget.config.idOf).toList();
      return;
    }
    final selected = <T>[];
    final others = <T>[];
    for (final item in items) {
      (_selection.openedIds.contains(widget.config.idOf(item))
              ? selected
              : others)
          .add(item);
    }
    if (widget.config.comparator != null) {
      selected.sort(widget.config.comparator);
      others.sort(widget.config.comparator);
    }
    _stableIds = [
      ...selected.map(widget.config.idOf),
      ...others.map(widget.config.idOf),
    ];
  }

  void _syncStableIds(List<T> items) {
    final currentIds = items.map(widget.config.idOf).toSet();
    _stableIds = _stableIds.where(currentIds.contains).toList();
    final known = _stableIds.toSet();
    final newItems = items
        .where((item) => !known.contains(widget.config.idOf(item)))
        .toList();
    if (widget.config.comparator != null) {
      newItems.sort(widget.config.comparator);
    }
    _stableIds.addAll(newItems.map(widget.config.idOf));
    if (_stableIds.isEmpty) _computeStableIds(items);
  }

  Iterable<K> _filteredLoadedIds() {
    final items = _itemsSnapshot ?? <T>[];
    final query = _controller.text.trim().toLowerCase();
    if (query.isEmpty) return items.map(widget.config.idOf);
    return items
        .where(
          (item) => widget.config
              .searchTermsOf(item)
              .any((term) => term.toLowerCase().contains(query)),
        )
        .map(widget.config.idOf);
  }

  void _recordUserPendingChange(Set<K> before, Set<K> after) {
    _selection.recordExplicitChange(before, after);
  }

  Widget _buildResults(PickerViewStyle style) {
    return ValueListenableBuilder<int>(
      valueListenable: _viewTickN,
      builder: (context, _, child) {
        if (_loading) {
          return widget.loadingBuilder?.call(context) ??
              const DefaultPickerLoading();
        }
        if (_loadError != null) {
          return widget.errorBuilder?.call(
                context,
                _loadError!,
                _loadStackTrace ?? StackTrace.empty,
                _reload,
              ) ??
              DefaultPickerError(retry: _reload);
        }

        final items = _itemsSnapshot ?? <T>[];
        if (_stableIds.isEmpty) {
          _computeStableIds(items);
        } else {
          _syncStableIds(items);
        }
        final actions = GenericPickerActions<T, K>(
          pendingN: _pendingN,
          idOf: widget.config.idOf,
          close: _close,
          mode: widget.mode,
          getKey: _getKey,
          refresh: _reload,
          loadedIds: () => (_itemsSnapshot ?? <T>[]).map(widget.config.idOf),
          filteredIds: _filteredLoadedIds,
          recordDelta: _recordUserPendingChange,
        );
        final header =
            widget.headerBuilder?.call(context, actions, items) ??
            widget.headerTiles ??
            const <Widget>[];
        final byId = <K, T>{
          for (final item in items) widget.config.idOf(item): item,
        };
        final stableItems = <T>[
          for (final id in _stableIds)
            if (byId.containsKey(id)) byId[id]!,
        ];
        return OverlayBody<T, K>(
          header: header,
          stableOrder: stableItems.isEmpty ? items : stableItems,
          ctrl: _controller,
          pendingN: _pendingN,
          mode: widget.mode,
          config: widget.config,
          onToggleGate: widget.onToggle,
          onToggleMode: widget.onToggleMode,
          recordUserPendingChange: _recordUserPendingChange,
          close: _close,
          shrinkWrap: style.shrinkWrap,
          itemBuilder: widget.itemBuilder,
          resultsBuilder: widget.resultsBuilder,
          emptyBuilder: widget.emptyBuilder,
        );
      },
    );
  }

  Widget _buildSearchField(
    BuildContext context,
    PickerViewStyle style,
    bool fullScreen,
  ) {
    return widget.searchFieldBuilder?.call(context, _controller, _close) ??
        DefaultPickerSearchField(
          controller: _controller,
          focusNode: _effectiveSearchFocusNode,
          clearQuery: _clearQuery,
          close: _close,
          style: style,
          isFullScreen: fullScreen,
          leading: widget.viewLeading,
          trailing: widget.viewTrailing,
          hintText: widget.viewHintText,
          headerHeight: widget.headerHeight,
          textCapitalization: widget.textCapitalization,
          onChanged: widget.viewOnChanged,
          onSubmitted: widget.viewOnSubmitted,
          textInputAction: widget.textInputAction,
          keyboardType: widget.keyboardType,
          smartDashesType: widget.smartDashesType,
          smartQuotesType: widget.smartQuotesType,
        );
  }

  Widget _buildSaveEmptyAction(BuildContext context) {
    // ignore: deprecated_member_use_from_same_package
    if (widget.onFinishReplaceAll == null || !widget.showSaveEmptyButton) {
      return const SizedBox.shrink();
    }
    return ValueListenableBuilder<Set<K>>(
      valueListenable: _pendingN,
      builder: (context, pending, _) {
        if (pending.isNotEmpty) return const SizedBox.shrink();
        void save() {
          _allowReplaceAllEmpty = true;
          _close('saveEmpty');
        }

        return widget.saveEmptyBuilder?.call(context, save) ??
            DefaultPickerSaveEmptyButton(
              onPressed: save,
              label: widget.saveEmptyLabel,
            );
      },
    );
  }

  Widget _buildView(
    BuildContext context,
    PickerViewStyle style,
    bool fullScreen,
  ) {
    final parts = PickerViewParts(
      searchField: _buildSearchField(context, style, fullScreen),
      divider: DividerTheme(
        data: DividerTheme.of(context).copyWith(color: style.dividerColor),
        child: const Divider(height: 1),
      ),
      saveEmptyAction: _buildSaveEmptyAction(context),
      results: _buildResults(style),
    );
    return widget.viewBuilder?.call(context, parts) ??
        DefaultPickerView(
          searchField: parts.searchField,
          divider: parts.divider,
          saveEmptyAction: parts.saveEmptyAction,
          results: parts.results,
          shrinkWrap: style.shrinkWrap,
        );
  }

  Widget _buildSurface(
    BuildContext context,
    PickerViewStyle style,
    bool fullScreen,
  ) {
    final child = _buildView(context, style, fullScreen);
    return widget.viewSurfaceBuilder?.call(context, child, fullScreen) ??
        DefaultPickerViewSurface(style: style, child: child);
  }

  bool _isFullScreen(BuildContext context) {
    return widget.isFullScreen ??
        switch (Theme.of(context).platform) {
          TargetPlatform.iOS ||
          TargetPlatform.android ||
          TargetPlatform.fuchsia => true,
          TargetPlatform.macOS ||
          TargetPlatform.linux ||
          TargetPlatform.windows => false,
        };
  }

  BoxConstraints? _legacyConstraints() {
    if (widget.viewConstraints != null ||
        (widget.minWidth == null && widget.maxHeight == null)) {
      return widget.viewConstraints;
    }
    final maxHeight = widget.maxHeight ?? double.infinity;
    return BoxConstraints(
      minWidth: widget.minWidth ?? 360,
      minHeight: math.min(240, maxHeight),
      maxHeight: maxHeight,
    );
  }

  PickerViewStyle _resolveStyle(BuildContext context, bool fullScreen) {
    return PickerViewStyle.resolve(
      context,
      isFullScreen: fullScreen,
      backgroundColor: widget.viewBackgroundColor,
      elevation: widget.viewElevation,
      surfaceTintColor: widget.viewSurfaceTintColor,
      side: widget.viewSide,
      shape: widget.viewShape,
      headerTextStyle: widget.headerTextStyle,
      headerHintStyle: widget.headerHintStyle,
      dividerColor: widget.dividerColor,
      constraints: _legacyConstraints(),
      viewPadding: widget.viewPadding,
      barPadding: widget.viewBarPadding,
      shrinkWrap: widget.shrinkWrap,
    );
  }

  Rect _basePopupRect(
    Size screenSize,
    TextDirection textDirection,
    PickerViewStyle style,
    bool fullScreen,
  ) {
    if (fullScreen) return Offset.zero & screenSize;
    final constraints = style.constraints;
    final width = clampDouble(
      constraints.constrainWidth(_openedAnchorRect.width),
      0,
      screenSize.width,
    );
    final height = clampDouble(
      constraints.constrainHeight(screenSize.height * 2 / 3),
      0,
      screenSize.height,
    );
    var left = textDirection == TextDirection.ltr
        ? _openedAnchorRect.left
        : _openedAnchorRect.right - width;
    var top = _openedAnchorRect.top;
    if (left + width > screenSize.width) left = screenSize.width - width;
    if (left < 0) left = 0;
    if (top + height > screenSize.height) top = screenSize.height - height;
    if (top < 0) top = 0;
    return Offset(left, top) & Size(width, height);
  }

  Offset _resolvedMenuOffset(Rect baseRect, Size screenSize, bool fullScreen) {
    if (fullScreen) return Offset.zero;
    var dx = widget.menuOffset.dx;
    var dy = widget.menuOffset.dy;
    if (baseRect.left + dx < 0 || baseRect.right + dx > screenSize.width) {
      dx = 0;
    }
    if (baseRect.top + dy < 0 || baseRect.bottom + dy > screenSize.height) {
      dy = 0;
    }
    return Offset(dx, dy);
  }

  Widget _buildOverlayEntry() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final screenSize = constraints.biggest;
        final fullScreen = _isFullScreen(context);
        final style = _resolveStyle(context, fullScreen);
        final baseRect = _basePopupRect(
          screenSize,
          Directionality.of(context),
          style,
          fullScreen,
        );
        final resolvedOffset = _resolvedMenuOffset(
          baseRect,
          screenSize,
          fullScreen,
        );
        final openAnimation = CurvedAnimation(
          parent: _animationController,
          curve: _openViewCurve,
        );
        final fadeAnimation = CurvedAnimation(
          parent: _animationController,
          curve: _viewFadeCurve,
        );
        final offsetFraction =
            widget.menuOffsetAnimationDuration.inMicroseconds <= 0
            ? 0.0
            : (widget.menuOffsetAnimationDuration.inMicroseconds /
                      _openViewDuration.inMicroseconds)
                  .clamp(0.0, 1.0);
        final offsetAnimation = offsetFraction == 0
            ? const AlwaysStoppedAnimation<double>(1)
            : CurvedAnimation(
                parent: _animationController,
                curve: Interval(0, offsetFraction, curve: Curves.easeOutCubic),
              );
        final left = fullScreen
            ? 0.0
            : lerpDouble(
                _openedAnchorRect.left,
                baseRect.left,
                openAnimation.value,
              )!;
        final top = fullScreen
            ? 0.0
            : lerpDouble(
                _openedAnchorRect.top,
                baseRect.top,
                openAnimation.value,
              )!;
        final offset =
            Offset.lerp(Offset.zero, resolvedOffset, offsetAnimation.value) ??
            resolvedOffset;
        final scaleX = fullScreen
            ? 1.0
            : lerpDouble(
                (_openedAnchorRect.width / baseRect.width).clamp(0.92, 1),
                1,
                openAnimation.value,
              )!;
        final scaleY = fullScreen
            ? 1.0
            : lerpDouble(
                (_openedAnchorRect.height / baseRect.height).clamp(0.92, 1),
                1,
                openAnimation.value,
              )!;
        final padding = style.viewPadding ?? EdgeInsets.zero;

        return FocusScope(
          autofocus: true,
          onKeyEvent: (_, event) {
            if (event is KeyDownEvent &&
                event.logicalKey == LogicalKeyboardKey.escape) {
              _close('escape');
              return KeyEventResult.handled;
            }
            return KeyEventResult.ignored;
          },
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Positioned.fill(
                child: GestureDetector(
                  behavior: HitTestBehavior.translucent,
                  onTap: () => _close('outside'),
                ),
              ),
              Positioned(
                left: left + offset.dx,
                top: top + offset.dy,
                width: baseRect.width,
                height: baseRect.height,
                child: Opacity(
                  opacity: fadeAnimation.value,
                  child: Transform.scale(
                    alignment: Alignment.topLeft,
                    scaleX: scaleX,
                    scaleY: scaleY,
                    child: Padding(
                      padding: padding,
                      child: _buildSurface(context, style, fullScreen),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final hasSelection = widget.initialSelectedIds.isNotEmpty;
    final trigger =
        widget.triggerBuilder?.call(context, _requestOpen, _tick) ??
        (widget.triggerChild != null
            ? GestureDetector(onTap: _requestOpen, child: widget.triggerChild)
            : DefaultPickerTrigger(
                onPressed: _requestOpen,
                icon: hasSelection
                    ? widget.iconWhenSelected ?? widget.iconWhenEmpty
                    : widget.iconWhenEmpty,
                iconSize: widget.iconSize,
                tooltip: widget.config.title,
                enabled: widget.enabled,
              ));

    return IgnorePointer(
      ignoring: !widget.enabled,
      child: AnimatedOpacity(
        opacity: widget.enabled ? 1 : 0.38,
        duration: const Duration(milliseconds: 100),
        child: Builder(
          builder: (triggerContext) {
            _triggerContext = triggerContext;
            return trigger;
          },
        ),
      ),
    );
  }
}

bool _listEquals<T>(List<T> a, List<T> b) {
  if (identical(a, b)) return true;
  if (a.length != b.length) return false;
  for (var index = 0; index < a.length; index++) {
    if (a[index] != b[index]) return false;
  }
  return true;
}
