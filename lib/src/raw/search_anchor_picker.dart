import 'dart:async';
import 'dart:ui' show clampDouble, lerpDouble;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:search_anchor_picker/src/raw/overlay_body.dart';
import 'package:search_anchor_picker/src/raw/picker_builders.dart';
import 'package:search_anchor_picker/src/raw/picker_config.dart';
import 'package:search_anchor_picker/src/raw/picker_debug.dart';
import 'package:search_anchor_picker/src/raw/picker_resource_tracker.dart';
import 'package:search_anchor_picker/src/raw/selection_session.dart';
import 'package:search_anchor_picker/src/raw/widgets/picker_defaults.dart';

/// SearchAnchor-like picker with stable selection and nested popup support.
class GenericRawSearchAnchorPicker<T, K> extends StatefulWidget {
  const GenericRawSearchAnchorPicker({
    required this.config,
    required this.initialSelectedIds,
    super.key,
    this.selectionMode = SelectionMode.multi,
    this.isSelectable,
    this.onChange,
    this.onClose,
    this.closeSavingBuilder,
    this.closeSaveFailedBuilder,
    this.searchController,
    this.triggerBuilder,
    this.triggerChild,
    this.iconWhenEmpty,
    this.iconWhenSelected,
    this.iconSize,
    this.headerBuilder,
    this.headerTiles,
    this.selectedFirst,
    this.closeQueryBehavior = CloseQueryBehavior.keep,
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

  final GenericRawPickerConfig<T, K> config;
  final List<K> initialSelectedIds;
  final SelectionMode selectionMode;

  /// Optional per-item rule that makes a row inert.
  ///
  /// Return `false` and the row cannot be changed by the user in either
  /// direction: the default row is rendered disabled, taps on it do nothing,
  /// and bulk commands skip the ID. Rules the user cannot satisfy belong here,
  /// where they read as an inactive row, instead of in a save that lets the
  /// checkbox move and then springs it back.
  ///
  /// It is a synchronous rule on a loaded item, so an ID that is selected but
  /// absent from the current `loadItems` result is not filtered.
  ///
  /// Leaving this null is the same as always returning `true`.
  final bool Function(T item)? isSelectable;

  /// Immediate save, run on each accepted delta once the checkboxes moved.
  ///
  /// The picker owns the pending IDs and notifies; the application saves.
  /// Save from IDs: loaded items can be missing from the current `loadItems`
  /// result. If this returns a [Future] the picker awaits it, so close waits
  /// for in-flight work.
  ///
  /// This is where the application reacts to the tap: validate, save, and
  /// throw to refuse. A thrown error is reported and restores the checkbox
  /// and the session intent, so the pending set never keeps a change the save
  /// rejected. Rules that are known up front belong in [isSelectable], which
  /// shows the row as inactive instead of letting the checkbox move first.
  ///
  /// A bulk command takes this same path and arrives as one delta over every
  /// loaded or filtered ID, so send it as one request: a save that loops
  /// [PickerDelta.added] turns a single tap into a burst of calls. [onClose]
  /// sidesteps that, since a whole session collapses into one net delta.
  final FutureOr<void> Function(PickerDelta<K> delta)? onChange;

  /// Deferred save, run once when the session closes, with its net [PickerDelta].
  ///
  /// This is not overlay-lifecycle [viewOnClose].
  /// Toggling and bulk commands inside one session collapse into one delta,
  /// which is what makes this the cheap place to save a picker where the user
  /// explores before settling.
  ///
  /// Persist [PickerDelta.added] and [PickerDelta.removed]. Apply that to the
  /// seed you already hold. A failed or empty `loadItems` is not "the list is
  /// empty".
  ///
  /// If this returns a [Future], the picker awaits it while the overlay stays
  /// open. A thrown error is reported and the user is asked whether to keep
  /// editing or close without saving.
  final FutureOr<void> Function(PickerDelta<K> delta)? onClose;

  /// Optional wrap for the open view while [onClose] is saving.
  ///
  /// When null, a localized saving overlay is shown.
  final PickerCloseSavingBuilder? closeSavingBuilder;

  /// Optional prompt after [onClose] throws.
  ///
  /// When null, a localized dialog offers update-selection or close-without-saving.
  final PickerCloseSaveFailedBuilder? closeSaveFailedBuilder;
  final SearchController? searchController;
  final Widget Function(BuildContext, VoidCallback, int)? triggerBuilder;
  final Widget? triggerChild;
  final Widget? iconWhenEmpty;
  final Widget? iconWhenSelected;
  final double? iconSize;

  final List<Widget> Function(
    BuildContext context,
    GenericRawPickerController<T, K> controller,
    List<T> allItems,
  )?
  headerBuilder;
  final List<Widget>? headerTiles;
  final bool? selectedFirst;
  final CloseQueryBehavior closeQueryBehavior;

  /// Replaces the default row.
  ///
  /// Called as `(context, item, isSelected, toggle)`.
  final Widget Function(
    BuildContext context,
    T item,
    bool isSelected,
    VoidCallback toggle,
  )?
  itemBuilder;

  /// Optional per-item unselect gate. When null, [PickerUnselectPolicy] on
  /// the config is used.
  final Future<bool> Function(BuildContext context, T item)? canUnselect;
  final PickerResultsBuilder? resultsBuilder;
  final PickerSearchFieldBuilder? searchFieldBuilder;
  final PickerLoadingBuilder? loadingBuilder;
  final PickerEmptyBuilder? emptyBuilder;

  /// Overrides the localized default shown when no items were loaded.
  final String? emptyText;

  /// Overrides the localized default shown when a query has no matches.
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
  State<GenericRawSearchAnchorPicker<T, K>> createState() =>
      _GenericRawSearchAnchorPickerState<T, K>();
}

class RawSearchAnchorPicker<T> extends GenericRawSearchAnchorPicker<T, int> {
  const RawSearchAnchorPicker({
    required super.config,
    required super.initialSelectedIds,
    super.key,
    super.selectionMode,
    super.isSelectable,
    super.onChange,
    super.onClose,
    super.closeSavingBuilder,
    super.closeSaveFailedBuilder,
    super.searchController,
    super.triggerBuilder,
    super.triggerChild,
    super.iconWhenEmpty,
    super.iconWhenSelected,
    super.iconSize,
    super.headerBuilder,
    super.headerTiles,
    super.selectedFirst,
    super.closeQueryBehavior,
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

class _GenericRawSearchAnchorPickerState<T, K>
    extends State<GenericRawSearchAnchorPicker<T, K>>
    with TickerProviderStateMixin, WidgetsBindingObserver
    implements _PickerBackTarget {
  SearchController? _ownedController;
  String _retainedQuery = '';
  FocusNode? _searchFocusNode;
  AnimationController? _openController;
  PickerSelectionSession<K>? _selectionSession;
  int _pendingToggles = 0;
  bool _closeAfterToggle = false;
  bool _savingClose = false;
  bool _saveFailedPromptOpen = false;
  ValueNotifier<bool>? _savingNotifier;

  SearchController get _controller {
    if (widget.searchController case final external?) return external;
    if (_ownedController case final owned?) return owned;
    final controller = SearchController()..text = _retainedQuery;
    PickerResourceTracker.register(controller);
    return _ownedController = controller;
  }

  FocusNode get _effectiveSearchFocusNode {
    if (_searchFocusNode case final focusNode?) return focusNode;
    final focusNode = FocusNode(debugLabel: 'Picker search');
    PickerResourceTracker.register(focusNode);
    return _searchFocusNode = focusNode;
  }

  AnimationController get _animationController {
    if (_openController case final controller?) return controller;
    final controller = AnimationController(
      vsync: this,
      duration: _openViewDuration,
    )..addListener(() => _overlayEntry?.markNeedsBuild());
    PickerResourceTracker.register(controller);
    return _openController = controller;
  }

  PickerSelectionSession<K> get _selection {
    if (_selectionSession case final session?) return session;
    final session = PickerSelectionSession<K>(widget.initialSelectedIds);
    PickerResourceTracker.register(session);
    return _selectionSession = session;
  }

  ValueNotifier<Set<K>> get _pendingN => _selection.pendingN;

  OverlayEntry? _overlayEntry;
  OverlayState? _overlayState;
  BuildContext? _triggerContext;
  Rect _openedAnchorRect = Rect.zero;
  bool _open = false;
  int _tick = 0;
  ValueNotifier<int>? _viewTickNotifier;
  ValueNotifier<int> get _viewTickN {
    if (_viewTickNotifier case final notifier?) return notifier;
    final notifier = ValueNotifier<int>(0);
    PickerResourceTracker.register(notifier);
    return _viewTickNotifier = notifier;
  }

  ValueNotifier<bool> get _savingN {
    if (_savingNotifier case final notifier?) return notifier;
    final notifier = ValueNotifier<bool>(false);
    PickerResourceTracker.register(notifier);
    return _savingNotifier = notifier;
  }

  Map<Object, GlobalKey>? _headerKeys;
  List<K> _stableIds = <K>[];
  List<T>? _itemsSnapshot;
  Object? _loadError;
  StackTrace? _loadStackTrace;
  bool _loading = false;
  int _loadGeneration = 0;
  int _scheduledReloadGeneration = 0;
  bool _reloadScheduled = false;
  VoidCallback? _listenableCallback;
  VoidCallback? _rebuildListenableCallback;

  @override
  void initState() {
    super.initState();
    _bindConfigControl();
  }

  void _bindConfigControl() {
    widget.config.internalOnOpen = _requestOpen;
    widget.config.internalOnClose = _close;
  }

  void _unbindConfigControl(GenericRawPickerConfig<T, K> config) {
    if (config.internalOnOpen == _requestOpen) config.internalOnOpen = null;
    config.internalOnClose = null;
  }

  void _attachListenable(Listenable? listenable) {
    if (listenable == null) return;
    _listenableCallback = _reload;
    PickerResourceTracker.register(_listenableCallback!);
    listenable.addListener(_listenableCallback!);
  }

  void _detachListenable(Listenable? listenable) {
    if (listenable == null || _listenableCallback == null) return;
    listenable.removeListener(_listenableCallback!);
    PickerResourceTracker.unregister(_listenableCallback!);
    _listenableCallback = null;
  }

  void _attachRebuildListenable(Listenable? listenable) {
    if (listenable == null) return;
    _rebuildListenableCallback = _rebuildOverlay;
    PickerResourceTracker.register(_rebuildListenableCallback!);
    listenable.addListener(_rebuildListenableCallback!);
  }

  void _detachRebuildListenable(Listenable? listenable) {
    if (listenable == null || _rebuildListenableCallback == null) {
      return;
    }
    listenable.removeListener(_rebuildListenableCallback!);
    PickerResourceTracker.unregister(_rebuildListenableCallback!);
    _rebuildListenableCallback = null;
  }

  void _rebuildOverlay() {
    if (mounted && _open) _viewTickN.value++;
  }

  void _clearHeaderKeys() {
    final keys = _headerKeys;
    if (keys == null) return;
    keys.values.forEach(PickerResourceTracker.unregister);
    PickerResourceTracker.unregister(keys);
    _headerKeys = null;
  }

  void _disposeSelectionSession() {
    final session = _selectionSession;
    if (session == null) return;
    PickerResourceTracker.unregister(session);
    session.dispose();
    _selectionSession = null;
  }

  void _disposeViewTickNotifier() {
    final notifier = _viewTickNotifier;
    if (notifier == null) return;
    PickerResourceTracker.unregister(notifier);
    notifier.dispose();
    _viewTickNotifier = null;
  }

  void _disposeSavingNotifier() {
    final notifier = _savingNotifier;
    if (notifier == null) return;
    PickerResourceTracker.unregister(notifier);
    notifier.dispose();
    _savingNotifier = null;
  }

  void _disposeOpenController() {
    final controller = _openController;
    if (controller == null) return;
    PickerResourceTracker.unregister(controller);
    controller.dispose();
    _openController = null;
  }

  void _disposeSearchFocusNode() {
    final focusNode = _searchFocusNode;
    if (focusNode == null) return;
    PickerResourceTracker.unregister(focusNode);
    focusNode.dispose();
    _searchFocusNode = null;
  }

  void _disposeOwnedController() {
    final controller = _ownedController;
    if (controller == null) return;
    PickerResourceTracker.unregister(controller);
    controller.dispose();
    _ownedController = null;
  }

  @override
  void didUpdateWidget(covariant GenericRawSearchAnchorPicker<T, K> oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.config != widget.config) {
      _unbindConfigControl(oldWidget.config);
      _bindConfigControl();
      final entry = _overlayEntry;
      if (_open && entry != null) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted && _open && identical(_overlayEntry, entry)) {
            entry.markNeedsBuild();
          }
        });
      }
    }

    if (_open && oldWidget.config.listenable != widget.config.listenable) {
      _detachListenable(oldWidget.config.listenable);
      _attachListenable(widget.config.listenable);
    }
    if (_open &&
        oldWidget.config.rebuildListenable != widget.config.rebuildListenable) {
      _detachRebuildListenable(oldWidget.config.rebuildListenable);
      _attachRebuildListenable(widget.config.rebuildListenable);
    }
    if (_open && oldWidget.config.reloadKey != widget.config.reloadKey) {
      _scheduleReload();
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
    _cancelScheduledReload();
    WidgetsBinding.instance.removeObserver(this);
    _openPickerStack.remove(this);
    _removeOverlay();
    _unbindConfigControl(widget.config);
    _detachListenable(widget.config.listenable);
    _detachRebuildListenable(widget.config.rebuildListenable);
    _clearHeaderKeys();
    _disposeSelectionSession();
    _disposeViewTickNotifier();
    _disposeSavingNotifier();
    _disposeOpenController();
    _disposeSearchFocusNode();
    _disposeOwnedController();
    super.dispose();
  }

  void _scheduleReload() {
    if (_reloadScheduled) return;
    _reloadScheduled = true;
    final generation = ++_scheduledReloadGeneration;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (generation != _scheduledReloadGeneration) return;
      _reloadScheduled = false;
      if (mounted && _open) _reload();
    });
  }

  void _cancelScheduledReload() {
    _scheduledReloadGeneration++;
    _reloadScheduled = false;
  }

  void _reload() {
    if (!mounted || !_open) return;
    final generation = ++_loadGeneration;
    _loading = true;
    _loadError = null;
    _loadStackTrace = null;
    _viewTickN.value++;

    unawaited(
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
      ),
    );
  }

  void _onOpen() {
    _selection.open(widget.initialSelectedIds);
    _pendingToggles = 0;
    _closeAfterToggle = false;
    _savingClose = false;
    _saveFailedPromptOpen = false;
    if (_savingNotifier != null) _savingN.value = false;
    _stableIds = <K>[];
    _itemsSnapshot = null;
    _loadError = null;
    _loadStackTrace = null;
    setState(() => _open = true);
    _openPickerStack
      ..remove(this)
      ..add(this);
    _attachListenable(widget.config.listenable);
    _attachRebuildListenable(widget.config.rebuildListenable);
    WidgetsBinding.instance
      ..removeObserver(this)
      ..addObserver(this);
    _callLifecycleCallback('viewOnOpen', widget.viewOnOpen);
    _reload();
  }

  void _requestOpen() {
    if (_open || !widget.enabled) return;
    PickerDebug.log('RawSearchAnchorPicker: Opening picker');
    _onOpen();
    _showOverlay();
  }

  void _close([String? reason]) {
    if (!_open || _savingClose || _saveFailedPromptOpen) return;
    if (_pendingToggles > 0) {
      _closeAfterToggle = true;
      return;
    }
    if (widget.onClose == null) {
      _finishClose(reason);
      return;
    }
    unawaited(_saveThenClose(reason));
  }

  Future<void> _saveThenClose(String? reason) async {
    _savingClose = true;
    _savingN.value = true;
    _overlayEntry?.markNeedsBuild();
    final result = _selection.result();
    try {
      await widget.onClose!(result);
      if (!mounted) return;
      _finishClose(reason);
    } on Object catch (error, stackTrace) {
      _reportCallbackError('onClose', error, stackTrace);
      if (!mounted || !_open) return;
      _savingN.value = false;
      _savingClose = false;
      _overlayEntry?.markNeedsBuild();
      _saveFailedPromptOpen = true;
      try {
        final action =
            await (widget.closeSaveFailedBuilder?.call(
                  context,
                  error,
                  stackTrace,
                ) ??
                showDefaultPickerCloseSaveFailed(context));
        if (!mounted) return;
        if (action == CloseSaveFailedAction.closeWithoutSaving) {
          _finishClose(reason);
        }
      } on Object catch (dialogError, dialogStack) {
        _reportCallbackError('closeSaveFailedBuilder', dialogError, dialogStack);
      } finally {
        _saveFailedPromptOpen = false;
      }
    }
  }

  void _finishClose([String? reason]) {
    if (!_open) return;
    PickerDebug.log('RawSearchAnchorPicker: Closing picker. Reason=$reason');
    _savingClose = false;
    _saveFailedPromptOpen = false;
    setState(() => _open = false);
    WidgetsBinding.instance.removeObserver(this);
    _openPickerStack.remove(this);
    _loadGeneration++;
    _cancelScheduledReload();
    final queryAtClose = _controller.text;
    final externalController = widget.searchController;

    FocusManager.instance.primaryFocus?.unfocus();
    _removeOverlay();
    _clearHeaderKeys();
    _detachListenable(widget.config.listenable);
    _detachRebuildListenable(widget.config.rebuildListenable);
    _itemsSnapshot = null;
    _stableIds = <K>[];
    _disposeSelectionSession();
    _disposeViewTickNotifier();
    _disposeSavingNotifier();
    _disposeOpenController();
    _disposeSearchFocusNode();
    if (externalController == null) {
      _retainedQuery = widget.closeQueryBehavior == CloseQueryBehavior.clear
          ? ''
          : queryAtClose;
      _disposeOwnedController();
    }
    _callLifecycleCallback('viewOnClose', widget.viewOnClose);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (externalController != null) {
        if (widget.closeQueryBehavior == CloseQueryBehavior.clear) {
          externalController.clear();
        } else {
          externalController.text = queryAtClose;
        }
      }
      setState(() => _tick++);
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

  void _callLifecycleCallback(String name, VoidCallback? callback) {
    if (callback == null) return;
    try {
      callback();
    } on Object catch (error, stackTrace) {
      _reportCallbackError(name, error, stackTrace);
    }
  }

  void _reportCallbackError(String callback, Object error, StackTrace stack) {
    FlutterError.reportError(
      FlutterErrorDetails(
        exception: error,
        stack: stack,
        library: 'search_anchor_picker',
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
    final entry = OverlayEntry(builder: (_) => _buildOverlayEntry());
    PickerResourceTracker.register(entry);
    _overlayEntry = entry;
    overlay.insert(entry);
    unawaited(_animationController.forward());
  }

  void _removeOverlay() {
    final entry = _overlayEntry;
    if (entry != null) {
      entry.remove();
      PickerResourceTracker.unregister(entry);
    }
    _overlayEntry = null;
    _overlayState = null;
  }

  Rect _currentAnchorRect() {
    final anchorBox = _triggerContext?.findRenderObject() as RenderBox?;
    final overlayBox = _overlayState?.context.findRenderObject() as RenderBox?;
    if (anchorBox == null || overlayBox == null) {
      return Offset.zero & Size(widget.viewConstraints?.minWidth ?? 360, 0);
    }
    final offset = anchorBox.localToGlobal(Offset.zero, ancestor: overlayBox);
    return offset & anchorBox.size;
  }

  GlobalKey _getKey(Object id) {
    var keys = _headerKeys;
    if (keys == null) {
      keys = <Object, GlobalKey>{};
      PickerResourceTracker.register(keys);
      _headerKeys = keys;
    }
    return keys.putIfAbsent(id, () {
      final key = GlobalKey();
      PickerResourceTracker.register(key);
      return key;
    });
  }

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

  Future<bool> _applySelectionDelta({
    required BuildContext context,
    required Set<K> added,
    required Set<K> removed,
  }) async {
    if (added.isEmpty && removed.isEmpty) return true;
    _pendingToggles++;
    try {
      final items = _itemsSnapshot ?? <T>[];
      final byId = <K, T>{
        for (final item in items) widget.config.idOf(item): item,
      };
      final selectableAdded = _withoutInertIds(added, byId);
      final selectableRemoved = _withoutInertIds(removed, byId);
      if (selectableAdded.isEmpty && selectableRemoved.isEmpty) return false;
      if (widget.selectionMode != SelectionMode.multi &&
          selectableRemoved.length != removed.length) {
        // The displaced selection is inert, so the replacement cannot happen
        // without leaving two IDs selected in a single-selection picker.
        return false;
      }

      final removedItems = [
        for (final id in selectableRemoved)
          if (byId[id] != null) byId[id]!,
      ];
      for (final item in removedItems) {
        if (!await _canUnselect(context, item)) return false;
      }
      if (!mounted || !_open) return false;

      final delta = PickerDelta(
        added: selectableAdded,
        removed: selectableRemoved,
      );
      final before = {..._pendingN.value};
      final after = {...before, ...selectableAdded}
        ..removeAll(selectableRemoved);
      _selection.recordExplicitChange(before, after);
      _pendingN.value = after;
      if (!await _runOnChange(delta)) {
        _selection.recordExplicitChange(after, before);
        if (_pendingN.value.length == after.length &&
            _pendingN.value.containsAll(after)) {
          _pendingN.value = before;
        }
        return false;
      }
      return true;
    } finally {
      _pendingToggles--;
      if (_pendingToggles == 0 && _closeAfterToggle && mounted) {
        _close('toggleSettled');
      }
    }
  }

  Set<K> _withoutInertIds(Set<K> ids, Map<K, T> byId) {
    final isSelectable = widget.isSelectable;
    if (isSelectable == null) return ids;
    return {
      for (final id in ids)
        if (byId[id] == null || isSelectable(byId[id] as T)) id,
    };
  }

  Future<bool> _canUnselect(BuildContext context, T item) async {
    if (widget.canUnselect != null) {
      return widget.canUnselect!(context, item);
    }
    return applyUnselectPolicy(
      context,
      widget.config,
      item,
      widget.config.unselectPolicy,
    );
  }

  Future<bool> _runOnChange(PickerDelta<K> delta) async {
    if (widget.onChange == null) return true;
    try {
      await widget.onChange!(delta);
      return true;
    } on Object catch (error, stack) {
      _reportCallbackError('onChange', error, stack);
      return false;
    }
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
        final session = _selection;
        final controller = GenericRawPickerController<T, K>(
          pendingN: _pendingN,
          idOf: widget.config.idOf,
          close: _close,
          selectionMode: widget.selectionMode,
          getKey: _getKey,
          refresh: _reload,
          loadedIds: () => (_itemsSnapshot ?? <T>[]).map(widget.config.idOf),
          filteredIds: _filteredLoadedIds,
          applyDelta: (added, removed) => _applySelectionDelta(
            context: context,
            added: added,
            removed: removed,
          ),
          isActive: () =>
              mounted && _open && identical(_selectionSession, session),
        );
        final header =
            widget.headerBuilder?.call(context, controller, items) ??
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
          selectionMode: widget.selectionMode,
          config: widget.config,
          applySelectionDelta: _applySelectionDelta,
          isSelectable: widget.isSelectable,
          close: _close,
          shrinkWrap: style.shrinkWrap,
          itemBuilder: widget.itemBuilder,
          resultsBuilder: widget.resultsBuilder,
          emptyBuilder: widget.emptyBuilder,
          emptyText: widget.emptyText,
          noResultsText: widget.noResultsText,
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
      results: _buildResults(style),
    );
    return widget.viewBuilder?.call(context, parts) ??
        DefaultPickerView(
          searchField: parts.searchField,
          divider: parts.divider,
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
    final surface =
        widget.viewSurfaceBuilder?.call(context, child, fullScreen) ??
        DefaultPickerViewSurface(style: style, child: child);
    if (widget.onClose == null) return surface;
    return ValueListenableBuilder<bool>(
      valueListenable: _savingN,
      builder: (context, saving, _) {
        if (!saving) return surface;
        return widget.closeSavingBuilder?.call(context, surface) ??
            DefaultPickerCloseSaving(child: surface);
      },
    );
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
      constraints: widget.viewConstraints,
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
                      child: Material(
                        type: MaterialType.transparency,
                        child: _buildSurface(context, style, fullScreen),
                      ),
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

    final triggerWithContext = Builder(
      builder: (triggerContext) {
        _triggerContext = triggerContext;
        return trigger;
      },
    );
    if (widget.enabled) return triggerWithContext;
    return IgnorePointer(
      child: Opacity(opacity: 0.38, child: triggerWithContext),
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
