import 'dart:async';

import 'package:flutter/material.dart';
import 'package:search_anchor_picker/src/raw/picker_builders.dart';
import 'package:search_anchor_picker/src/raw/picker_config.dart';
import 'package:search_anchor_picker/src/raw/picker_debug.dart';
import 'package:search_anchor_picker/src/raw/widgets/picker_defaults.dart';

/// Core result-list coordinator. Public callers should customize it through
/// picker builders rather than constructing this widget directly.
class OverlayBody<T, K> extends StatefulWidget {
  const OverlayBody({
    required this.header,
    required this.stableOrder,
    required this.ctrl,
    required this.pendingN,
    required this.selectionMode,
    required this.config,
    required this.applySelectionDelta,
    required this.close,
    required this.shrinkWrap,
    super.key,
    this.isSelectable,
    this.itemBuilder,
    this.resultsBuilder,
    this.emptyBuilder,
    this.emptyText,
    this.noResultsText,
  });

  final List<Widget> header;
  final List<T> stableOrder;
  final SearchController ctrl;
  final ValueNotifier<Set<K>> pendingN;
  final SelectionMode selectionMode;
  final GenericRawPickerConfig<T, K> config;
  final Future<bool> Function({
    required BuildContext context,
    required Set<K> added,
    required Set<K> removed,
  })
  applySelectionDelta;
  final void Function([String? reason]) close;
  final bool shrinkWrap;

  /// Per-item rule that makes a row inert. Null means every row is selectable.
  final bool Function(T item)? isSelectable;
  final Widget Function(
    BuildContext context,
    T item,
    bool isSelected,
    VoidCallback toggle,
  )?
  itemBuilder;
  final PickerResultsBuilder? resultsBuilder;
  final PickerEmptyBuilder? emptyBuilder;
  final String? emptyText;
  final String? noResultsText;

  @override
  State<OverlayBody<T, K>> createState() => _OverlayBodyState<T, K>();
}

class _OverlayBodyState<T, K> extends State<OverlayBody<T, K>> {
  final ScrollController _scroll = ScrollController();
  final Set<K> _toggling = <K>{};

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

  Future<void> _toggle(T item, K id, bool next) async {
    PickerDebug.log('OverlayBody: User toggle item=$item, next=$next');
    if (widget.isSelectable?.call(item) == false) return;
    if (_toggling.contains(id) ||
        (widget.selectionMode != SelectionMode.multi && _toggling.isNotEmpty) ||
        (!next && widget.selectionMode == SelectionMode.single)) {
      return;
    }
    _toggling.add(id);
    try {
      final current = widget.pendingN.value;
      late final Set<K> added;
      late final Set<K> removed;
      if (widget.selectionMode != SelectionMode.multi) {
        final nextPending = next ? <K>{id} : <K>{};
        added = nextPending.difference(current);
        removed = current.difference(nextPending);
      } else {
        added = next ? {id} : <K>{};
        removed = next ? <K>{} : {id};
      }
      final applied = await widget.applySelectionDelta(
        context: context,
        added: added,
        removed: removed,
      );
      if (!applied || !mounted) return;
      if (widget.selectionMode != SelectionMode.multi) {
        widget.close('single');
      }
    } finally {
      _toggling.remove(id);
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
                    DefaultPickerEmpty(
                      query: query,
                      emptyText: widget.emptyText,
                      noResultsText: widget.noResultsText,
                    ),
              );
            } else {
              for (final item in filtered) {
                final id = widget.config.idOf(item);
                final selected = pending.contains(id);
                void toggle() => _toggle(item, id, !selected);
                children.add(
                  widget.itemBuilder?.call(context, item, selected, toggle) ??
                      RawDefaultPickerItemTile(
                        selected: selected,
                        onToggle: (next) => _toggle(item, id, next),
                        label: widget.config.labelOf(item),
                        tooltip: widget.config.tooltipOf?.call(item),
                        leading: widget.config.iconOf?.call(item),
                        selectionMode: widget.selectionMode,
                        enabled: widget.isSelectable?.call(item) ?? true,
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
