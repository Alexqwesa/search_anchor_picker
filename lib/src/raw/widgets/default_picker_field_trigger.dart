import 'package:flutter/material.dart';
import 'package:search_anchor_picker/src/raw/picker_config.dart';

/// Outlined field trigger: selected chips plus an Add or Change control.
///
/// This is the field-style counterpart to DefaultPickerTrigger. Pass it from
/// `triggerBuilder`. Tapping the field, a chip, or the action button opens the
/// picker. Chip delete icons call [onDeleted] and do not open the popup.
///
/// Chip deletion is outside the picker session. Update the same selected-ID
/// set you pass as `initialSelectedIds`, and persist that write yourself if
/// the application also saves from `onChange` or `onClose`.
class DefaultPickerFieldTrigger<K> extends StatelessWidget {
  /// Creates a Material selection field used as a picker trigger.
  const DefaultPickerFieldTrigger({
    required this.onOpen,
    super.key,
    this.selectedIds = const [],
    this.labelOf,
    this.onDeleted,
    this.selectionMode = SelectionMode.multi,
    this.showChips = true,
    this.enabled = true,
    this.decoration,
    this.addLabel,
    this.changeLabel,
  });

  /// Opens the picker.
  final VoidCallback onOpen;

  /// IDs shown as chips when [showChips] is true.
  final Iterable<K> selectedIds;

  /// Chip label for one selected ID. Defaults to `'$id'`.
  final String Function(K id)? labelOf;

  /// Removes one ID when the chip delete icon is pressed.
  ///
  /// When null, chips have no delete icon.
  final ValueChanged<K>? onDeleted;

  /// Chooses the action label: Add for [SelectionMode.multi], Change otherwise.
  final SelectionMode selectionMode;

  /// Whether selected IDs are listed as chips inside the field.
  final bool showChips;

  /// Whether the field, chips, and action button accept input.
  final bool enabled;

  /// Optional field chrome. When null, an outlined dense decoration is used.
  final InputDecoration? decoration;

  /// Overrides the localized Add label used in multi-select.
  final String? addLabel;

  /// Overrides the localized Change label used in single-select modes.
  final String? changeLabel;

  @override
  Widget build(BuildContext context) {
    final actions = _fieldTriggerActions(context);
    final isSingle = selectionMode != SelectionMode.multi;
    final ids = selectedIds.toList();
    final showSelectedChips = showChips && ids.isNotEmpty;
    final buttonLabel = isSingle
        ? (changeLabel ?? actions.change)
        : (addLabel ?? actions.add);
    final effectiveDecoration = _resolveDecoration(decoration);

    return SizedBox(
      width: double.infinity,
      child: Material(
        type: MaterialType.transparency,
        child: InkWell(
          onTap: enabled ? onOpen : null,
          mouseCursor: enabled
              ? SystemMouseCursors.click
              : SystemMouseCursors.basic,
          customBorder: switch (effectiveDecoration.border) {
            final ShapeBorder border => border,
            _ => null,
          },
          child: InputDecorator(
            decoration: effectiveDecoration,
            isEmpty: !showSelectedChips,
            child: ConstrainedBox(
              constraints: const BoxConstraints(minHeight: 32),
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  if (showSelectedChips)
                    for (final id in ids)
                      InputChip(
                        label: Text(labelOf?.call(id) ?? '$id'),
                        onPressed: enabled ? onOpen : null,
                        onDeleted: enabled && onDeleted != null
                            ? () => onDeleted!(id)
                            : null,
                      ),
                  TextButton.icon(
                    onPressed: enabled ? onOpen : null,
                    icon: Icon(
                      isSingle ? Icons.edit_outlined : Icons.add,
                      size: 18,
                    ),
                    label: Text(buttonLabel),
                    style: TextButton.styleFrom(
                      visualDensity: VisualDensity.compact,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

InputDecoration _resolveDecoration(InputDecoration? decoration) {
  const fallback = InputDecoration(
    border: OutlineInputBorder(),
    isDense: true,
    alignLabelWithHint: true,
    contentPadding: EdgeInsets.fromLTRB(8, 8, 8, 8),
  );
  if (decoration == null) return fallback;
  return decoration.copyWith(
    border: decoration.border ?? fallback.border,
    isDense: decoration.isDense ?? fallback.isDense,
    contentPadding: decoration.contentPadding ?? fallback.contentPadding,
  );
}

typedef _FieldTriggerActions = ({String add, String change});

const _FieldTriggerActions _englishFieldTriggerActions = (
  add: 'Add',
  change: 'Change',
);

const Map<String, _FieldTriggerActions> _fieldTriggerActionsByLanguage = {
  'ar': (add: 'إضافة', change: 'تغيير'),
  'de': (add: 'Hinzufügen', change: 'Ändern'),
  'en': _englishFieldTriggerActions,
  'es': (add: 'Añadir', change: 'Cambiar'),
  'fr': (add: 'Ajouter', change: 'Modifier'),
  'it': (add: 'Aggiungi', change: 'Cambia'),
  'ja': (add: '追加', change: '変更'),
  'ko': (add: '추가', change: '변경'),
  'pt': (add: 'Adicionar', change: 'Alterar'),
  'ru': (add: 'Добавить', change: 'Изменить'),
  'uk': (add: 'Додати', change: 'Змінити'),
  'vi': (add: 'Thêm', change: 'Đổi'),
  'zh': (add: '添加', change: '更改'),
};

_FieldTriggerActions _fieldTriggerActions(BuildContext context) {
  final languageCode = Localizations.maybeLocaleOf(context)?.languageCode;
  return _fieldTriggerActionsByLanguage[languageCode] ??
      _englishFieldTriggerActions;
}
