import 'dart:async';

import 'package:flutter/material.dart';
import 'package:search_anchor_picker/src/picker_builders.dart';
import 'package:search_anchor_picker/src/picker_config.dart';
import 'package:search_anchor_picker/src/picker_debug.dart';
import 'package:search_anchor_picker/src/widgets/picker_defaults.dart';

/// Core result-list coordinator. Public callers should customize it through
/// picker builders rather than constructing this widget directly.
class OverlayBody<T, K> extends StatefulWidget {
  const OverlayBody({
    super.key,
    required this.header,
    required this.stableOrder,
    required this.ctrl,
    required this.pendingN,
    required this.mode,
    required this.config,
    required this.recordUserPendingChange,
    required this.close,
    required this.shrinkWrap,
    this.onToggleGate,
    this.onToggleMode = OnToggleMode.awaitGate,
    this.itemBuilder,
    this.resultsBuilder,
    this.emptyBuilder,
  });

  final List<Widget> header;
  final List<T> stableOrder;
  final SearchController ctrl;
  final ValueNotifier<Set<K>> pendingN;
  final PickerMode mode;
  final GenericPickerConfig<T, K> config;
  final Future<bool> Function(T item, bool nextSelected)? onToggleGate;
  final OnToggleMode onToggleMode;
  final void Function(Set<K> before, Set<K> after) recordUserPendingChange;
  final void Function([String? reason]) close;
  final bool shrinkWrap;
  final Widget Function(
    BuildContext context,
    T item,
    bool isSelected,
    VoidCallback toggle,
  )?
  itemBuilder;
  final PickerResultsBuilder? resultsBuilder;
  final PickerEmptyBuilder? emptyBuilder;

  @override
  State<OverlayBody<T, K>> createState() => _OverlayBodyState<T, K>();
}

class _OverlayBodyState<T, K> extends State<OverlayBody<T, K>> {
  final ScrollController _scroll = ScrollController();

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  bool _matches(T item, String query) {
    if (query.isEmpty) return true;
    return widget.config
        .searchTermsOf(item)
        .any((term) => term.toLowerCase().contains(query));
  }

  Future<bool> _confirmUnselect(BuildContext context, T item) async {
    switch (widget.config.unselectBehavior) {
      case UnselectBehavior.block:
        return false;
      case UnselectBehavior.showWarning:
        final content =
            widget.config.unselectWarningBuilder?.call(context, item) ??
            DefaultPickerUnselectWarning(label: widget.config.labelOf(item));
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: content, duration: const Duration(seconds: 2)),
        );
        return false;
      case UnselectBehavior.alert:
        return widget.config.unselectConfirmationBuilder?.call(context, item) ??
            showDefaultPickerUnselectConfirmation(
              context,
              label: widget.config.labelOf(item),
            );
      case UnselectBehavior.allow:
        return true;
    }
  }

  Future<void> _toggle(T item, K id, bool next) async {
    PickerDebug.log('OverlayBody: User toggle item=$item, next=$next');
    final useOptimistic =
        widget.onToggleMode == OnToggleMode.optimistic &&
        widget.mode == PickerMode.multi &&
        widget.onToggleGate != null;

    if (!useOptimistic && widget.onToggleGate != null) {
      final accepted = await widget.onToggleGate!(item, next);
      if (!mounted || !accepted) return;
    }

    final current = widget.pendingN.value;
    if (widget.mode != PickerMode.multi) {
      if (!next && widget.mode == PickerMode.radio) return;
      final nextPending = next ? <K>{id} : <K>{};
      widget.recordUserPendingChange(current, nextPending);
      widget.pendingN.value = nextPending;
      widget.close('radio');
      return;
    }

    if (!next &&
        (widget.config.isItemInUse?.call(item) ?? false) &&
        !await _confirmUnselect(context, item)) {
      return;
    }
    if (!mounted) return;

    final before = {...widget.pendingN.value};
    final after = {...before};
    next ? after.add(id) : after.remove(id);
    widget.recordUserPendingChange(before, after);
    widget.pendingN.value = after;

    if (useOptimistic) {
      unawaited(() async {
        final accepted = await widget.onToggleGate!(item, next);
        if (!mounted || accepted) return;
        final latest = {...widget.pendingN.value};
        final reverted = {...latest};
        before.contains(id) ? reverted.add(id) : reverted.remove(id);
        widget.recordUserPendingChange(latest, reverted);
        widget.pendingN.value = reverted;
      }());
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.ctrl,
      builder: (context, _) {
        final query = widget.ctrl.text.trim().toLowerCase();
        final filtered = widget.stableOrder
            .where((item) => _matches(item, query))
            .toList();
        return ValueListenableBuilder<Set<K>>(
          valueListenable: widget.pendingN,
          builder: (context, pending, _) {
            final children = <Widget>[...widget.header];
            if (filtered.isEmpty) {
              children.add(
                widget.emptyBuilder?.call(context, query) ??
                    DefaultPickerEmpty(query: query),
              );
            } else {
              for (final item in filtered) {
                final id = widget.config.idOf(item);
                final selected = pending.contains(id);
                void toggle() => _toggle(item, id, !selected);
                children.add(
                  widget.itemBuilder?.call(context, item, selected, toggle) ??
                      DefaultPickerItemTile(
                        selected: selected,
                        onToggle: (next) => _toggle(item, id, next),
                        label: widget.config.labelOf(item),
                        tooltip: widget.config.tooltipOf?.call(item),
                        leading: widget.config.iconOf?.call(item),
                        mode: widget.mode,
                      ),
                );
              }
            }

            return widget.resultsBuilder?.call(context, _scroll, children) ??
                DefaultPickerResultsList(
                  controller: _scroll,
                  shrinkWrap: widget.shrinkWrap,
                  children: children,
                );
          },
        );
      },
    );
  }
}
