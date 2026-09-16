import 'package:flutter/widgets.dart';
import 'package:search_anchor_picker/src/picker_config.dart';
import 'package:search_anchor_picker/src/picker_status.dart';
import 'package:search_anchor_picker/src/widgets/picker_defaults.dart';

PickerRelatedListItemStatus relatedListStatusOf<T, K>(
  GenericPickerConfig<T, K> config,
  T item,
) {
  return config.relatedListItemStatusOf?.call(item) ??
      const PickerRelatedListItemStatus();
}

Future<bool> relatedListCanUnselect<T, K>(
  BuildContext context,
  GenericPickerConfig<T, K> config,
  T item,
) {
  return applyRelatedListUnselectPolicy(
    context,
    config,
    item,
    relatedListStatusOf(config, item).unselectPolicy,
  );
}

Widget Function(BuildContext, T, bool, VoidCallback)
relatedListRowBuilder<T, K>(
  GenericPickerConfig<T, K> config,
  SelectionMode selectionMode,
  Widget Function(
    BuildContext,
    T,
    bool,
    PickerRelatedListItemStatus,
    VoidCallback,
  )?
  itemBuilder,
) {
  return (context, item, selected, toggle) {
    final status = relatedListStatusOf(config, item);
    return itemBuilder?.call(context, item, selected, status, toggle) ??
        DefaultPickerItemTile(
          selected: selected,
          onToggle: (_) => toggle(),
          label: config.labelOf(item),
          tooltip: config.tooltipOf?.call(item),
          leading: config.iconOf?.call(item),
          auxiliaryMembership: status.auxiliaryMembership,
          selectionMode: selectionMode,
        );
  };
}
