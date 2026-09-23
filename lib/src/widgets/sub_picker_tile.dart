import 'dart:async';

import 'package:flutter/material.dart';
import 'package:search_anchor_picker/src/picker_config.dart';
import 'package:search_anchor_picker/src/picker_status.dart';
import 'package:search_anchor_picker/src/raw/widgets/sub_picker_tile.dart';
import 'package:search_anchor_picker/src/related_list_item.dart';

/// Child `onChange` for [GenericSubPickerTile].
///
/// [notifyParent] applies [SubPickerParentSelectionEffect] to the open parent.
/// When `onClose` is also set, call this after every successfully handled
/// `onChange` if parent synchronization should happen immediately.
///
/// Do not call it selectively within one open session. If it is never called,
/// the parent effect is applied once after a successful `onClose`. If
/// `onClose` is omitted, the effect also runs after this callback returns.
typedef SubPickerOnChange<K> =
    FutureOr<void> Function(PickerDelta<K> delta, void Function() notifyParent);

/// Optional effect that a sub-picker result applies to parent pending selection.
///
/// Auxiliary-list membership and parent selection are independent by default.
/// The usual path updates the open parent's pending checkboxes after a
/// successful `onClose`. If `onClose` is omitted, the effect applies after
/// each accepted `onChange`. See [SubPickerOnChange] for when to call
/// `notifyParent()`. `onChange` is not a persist signal when `onClose` is
/// present. They do not run while the write is in flight. A thrown persist or
/// Close without saving leaves the parent unchanged. A save that completes
/// after disposal is ignored. They do not persist parent selection or create
/// parent `onChange` / `onClose` deltas.
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
    SubPickerOnChange<K>? onChange,
    super.onClose,
    super.closeSavingBuilder,
    super.closeSaveFailedBuilder,
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
  }) : _onChange = onChange,
       assert(
         parentSelectionEffect == SubPickerParentSelectionEffect.none ||
             parentController != null,
         'parentController is required when parentSelectionEffect modifies selection.',
       ),
       super(
         config: config,
         selectionMode: selectionMode,
         itemBuilder: relatedListRowBuilder(config, selectionMode, itemBuilder),
         isSelectable: (item) => relatedListIsSelectable(config, item),
         canUnselect: (context, item) {
           return relatedListCanUnselect(context, config, item);
         },
         onChange: null,
       );

  /// Parent controller used only when [parentSelectionEffect] modifies selection.
  final GenericPickerController<T, K>? parentController;

  /// Explicit effect of sub-list changes on the parent pending selection.
  final SubPickerParentSelectionEffect parentSelectionEffect;

  final SubPickerOnChange<K>? _onChange;

  @override
  Widget createPicker({
    FutureOr<void> Function(PickerDelta<K> delta)? onChange,
    FutureOr<void> Function(PickerDelta<K> delta)? onClose,
  }) {
    if (onChange != null || onClose != null) {
      return super.createPicker(onChange: onChange, onClose: onClose);
    }
    if (parentSelectionEffect == SubPickerParentSelectionEffect.none) {
      final user = _onChange;
      return super.createPicker(
        onChange: user == null ? null : (delta) => user(delta, () {}),
        onClose: this.onClose,
      );
    }
    return _ParentEffectHost<T, K>(
      parentController: parentController!,
      parentSelectionEffect: parentSelectionEffect,
      userOnChange: _onChange,
      userOnClose: this.onClose,
      builder: (wrappedOnChange, wrappedOnClose) => super.createPicker(
        onChange: wrappedOnChange,
        onClose: wrappedOnClose,
      ),
    );
  }
}

/// Applies [SubPickerParentSelectionEffect] after a successful child persist.
class _ParentEffectHost<T, K> extends StatefulWidget {
  const _ParentEffectHost({
    required this.parentController,
    required this.parentSelectionEffect,
    required this.userOnChange,
    required this.userOnClose,
    required this.builder,
  });

  final GenericPickerController<T, K> parentController;
  final SubPickerParentSelectionEffect parentSelectionEffect;
  final SubPickerOnChange<K>? userOnChange;
  final FutureOr<void> Function(PickerDelta<K> delta)? userOnClose;
  final Widget Function(
    Future<void> Function(PickerDelta<K> delta)? onChange,
    FutureOr<void> Function(PickerDelta<K> delta)? onClose,
  )
  builder;

  @override
  State<_ParentEffectHost<T, K>> createState() =>
      _ParentEffectHostState<T, K>();
}

class _ParentEffectHostState<T, K> extends State<_ParentEffectHost<T, K>> {
  bool get _closePersist => widget.userOnClose != null;

  bool _notifiedThisSession = false;

  void _apply(PickerDelta<K> delta) {
    if (delta.isEmpty) return;
    _applyParentEffect(
      widget.parentController,
      widget.parentSelectionEffect,
      delta.added,
      delta.removed,
    );
  }

  Future<void> _runPersist(
    PickerDelta<K> delta,
    FutureOr<void> Function(PickerDelta<K> delta) persist, {
    required bool applyEffect,
  }) async {
    widget.parentController.beginChildSave();
    try {
      await persist(delta);
      if (!mounted) return;
      if (applyEffect) _apply(delta);
    } finally {
      widget.parentController.endChildSave();
    }
  }

  Future<void> _onChange(PickerDelta<K> delta) async {
    var notified = false;
    void notifyParent() {
      if (notified) return;
      notified = true;
      _notifiedThisSession = true;
      if (mounted) _apply(delta);
    }

    final user = widget.userOnChange;
    if (user != null) {
      widget.parentController.beginChildSave();
      try {
        await user(delta, notifyParent);
      } finally {
        widget.parentController.endChildSave();
      }
    }
    if (!mounted) return;
    if (!notified && !_closePersist) notifyParent();
  }

  Future<void> _onClose(PickerDelta<K> delta) async {
    final persist = widget.userOnClose;
    if (persist == null) return;
    await _runPersist(
      delta,
      persist,
      applyEffect: !_notifiedThisSession,
    );
    _notifiedThisSession = false;
  }

  @override
  Widget build(BuildContext context) {
    final wrapOnChange = widget.userOnChange != null || !_closePersist;
    return widget.builder(
      wrapOnChange ? _onChange : null,
      _closePersist ? _onClose : null,
    );
  }
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
    super.onChange,
    super.onClose,
    super.closeSavingBuilder,
    super.closeSaveFailedBuilder,
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
