import 'dart:async';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:search_anchor_picker/src/raw/picker_builders.dart';
import 'package:search_anchor_picker/src/raw/picker_config.dart';
import 'package:search_anchor_picker/src/raw/widgets/overflow_tooltip_text.dart';
import 'package:search_anchor_picker/src/raw/widgets/passive_tooltip.dart';

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

/// SearchAnchor-style default row for one picker item.
///
/// This primitive has no related-list membership. The public default tile
/// adds that.
class RawDefaultPickerItemTile extends StatelessWidget {
  const RawDefaultPickerItemTile({
    required this.selected,
    required this.onToggle,
    required this.label,
    required this.selectionMode,
    super.key,
    this.leading,
    this.tooltip,
    this.enabled = true,
  });

  final bool selected;
  final ValueChanged<bool> onToggle;
  final String label;
  final Widget? leading;
  final SelectionMode selectionMode;
  final String? tooltip;

  /// Whether the row accepts taps. A disabled row is greyed out.
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final labelWidget = tooltip == null
        ? OverflowTooltipText(label)
        : PassiveTooltip(
            message: tooltip!,
            child: Text(label, maxLines: 1, overflow: TextOverflow.ellipsis),
          );
    return CheckboxListTile(
      checkboxShape: selectionMode == SelectionMode.multi
          ? null
          : const CircleBorder(),
      value: selected,
      onChanged: enabled ? (value) => onToggle(value ?? false) : null,
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

/// Default message shown when the picker has no visible results.
class DefaultPickerEmpty extends StatelessWidget {
  /// Creates the default empty-results view for [query].
  const DefaultPickerEmpty({
    required this.query,
    super.key,
    this.emptyText,
    this.noResultsText,
  });

  /// The current search query, or an empty string when no search is active.
  final String query;

  /// Text shown when no items were loaded.
  ///
  /// When null, a built-in translation is selected from the current locale.
  final String? emptyText;

  /// Text shown when loaded items do not match [query].
  ///
  /// When null, a built-in translation is selected from the current locale.
  final String? noResultsText;

  @override
  Widget build(BuildContext context) {
    final messages = _pickerDefaultMessages(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Text(
          query.isEmpty
              ? emptyText ?? messages.empty
              : noResultsText ?? messages.noResults,
        ),
      ),
    );
  }
}

typedef _PickerDefaultMessages = ({
  String empty,
  String noResults,
  String retry,
  String removeItemTitle,
  String inUse,
  String removeImpact,
  String remove,
  String saving,
  String closeSaveFailedTitle,
  String closeSaveFailedMessage,
  String updateSelection,
  String closeWithoutSaving,
});

const _PickerDefaultMessages _englishPickerDefaultMessages = (
  empty: 'No items',
  noResults: 'No results',
  retry: 'Retry',
  removeItemTitle: 'Remove item?',
  inUse: '{label} is currently in use.',
  removeImpact: 'Removing it might affect other data.',
  remove: 'Remove',
  saving: 'Saving…',
  closeSaveFailedTitle: 'Selection not saved',
  closeSaveFailedMessage: 'The popup could not be saved because of an error.',
  updateSelection: 'Keep editing',
  closeWithoutSaving: 'Close without saving',
);

const _pickerDefaultMessagesByLanguage = <String, _PickerDefaultMessages>{
  'ar': (
    empty: 'لا توجد عناصر',
    noResults: 'لا توجد نتائج',
    retry: 'إعادة المحاولة',
    removeItemTitle: 'إزالة العنصر؟',
    inUse: '{label} قيد الاستخدام حاليًا.',
    removeImpact: 'قد تؤثر إزالته في بيانات أخرى.',
    remove: 'إزالة',
    saving: 'جارٍ الحفظ…',
    closeSaveFailedTitle: 'لم يتم حفظ التحديد',
    closeSaveFailedMessage: 'تعذر حفظ النافذة المنبثقة بسبب خطأ.',
    updateSelection: 'تحديث التحديد',
    closeWithoutSaving: 'إغلاق بدون حفظ',
  ),
  'de': (
    empty: 'Keine Einträge',
    noResults: 'Keine Ergebnisse',
    retry: 'Erneut versuchen',
    removeItemTitle: 'Element entfernen?',
    inUse: '{label} wird derzeit verwendet.',
    removeImpact: 'Das Entfernen kann sich auf andere Daten auswirken.',
    remove: 'Entfernen',
    saving: 'Speichern…',
    closeSaveFailedTitle: 'Auswahl nicht gespeichert',
    closeSaveFailedMessage:
        'Das Popup konnte aufgrund eines Fehlers nicht gespeichert werden.',
    updateSelection: 'Auswahl aktualisieren',
    closeWithoutSaving: 'Schließen ohne Speichern',
  ),
  'en': _englishPickerDefaultMessages,
  'es': (
    empty: 'No hay elementos',
    noResults: 'No hay resultados',
    retry: 'Reintentar',
    removeItemTitle: '¿Quitar elemento?',
    inUse: '{label} está actualmente en uso.',
    removeImpact: 'Quitar este elemento puede afectar a otros datos.',
    remove: 'Quitar',
    saving: 'Guardando…',
    closeSaveFailedTitle: 'Selección no guardada',
    closeSaveFailedMessage:
        'No se pudo guardar la ventana emergente por un error.',
    updateSelection: 'Actualizar selección',
    closeWithoutSaving: 'Cerrar sin guardar',
  ),
  'fr': (
    empty: 'Aucun élément',
    noResults: 'Aucun résultat',
    retry: 'Réessayer',
    removeItemTitle: 'Supprimer l’élément ?',
    inUse: '{label} est actuellement utilisé.',
    removeImpact: 'Sa suppression peut affecter d’autres données.',
    remove: 'Supprimer',
    saving: 'Enregistrement…',
    closeSaveFailedTitle: 'Sélection non enregistrée',
    closeSaveFailedMessage:
        'La fenêtre n’a pas pu être enregistrée à cause d’une erreur.',
    updateSelection: 'Modifier la sélection',
    closeWithoutSaving: 'Fermer sans enregistrer',
  ),
  'it': (
    empty: 'Nessun elemento',
    noResults: 'Nessun risultato',
    retry: 'Riprova',
    removeItemTitle: 'Rimuovere l’elemento?',
    inUse: '{label} è attualmente in uso.',
    removeImpact: 'La rimozione potrebbe influire su altri dati.',
    remove: 'Rimuovi',
    saving: 'Salvataggio…',
    closeSaveFailedTitle: 'Selezione non salvata',
    closeSaveFailedMessage:
        'Impossibile salvare la finestra a causa di un errore.',
    updateSelection: 'Aggiorna selezione',
    closeWithoutSaving: 'Chiudi senza salvare',
  ),
  'ja': (
    empty: '項目がありません',
    noResults: '結果がありません',
    retry: '再試行',
    removeItemTitle: '項目を削除しますか？',
    inUse: '{label} は現在使用中です。',
    removeImpact: '削除すると他のデータに影響する可能性があります。',
    remove: '削除',
    saving: '保存しています…',
    closeSaveFailedTitle: '選択は保存されませんでした',
    closeSaveFailedMessage: 'エラーのためポップアップを保存できませんでした。',
    updateSelection: '選択を更新',
    closeWithoutSaving: '保存せずに閉じる',
  ),
  'ko': (
    empty: '항목 없음',
    noResults: '결과 없음',
    retry: '다시 시도',
    removeItemTitle: '항목을 제거할까요?',
    inUse: '{label}은(는) 현재 사용 중입니다.',
    removeImpact: '제거하면 다른 데이터에 영향을 줄 수 있습니다.',
    remove: '제거',
    saving: '저장 중…',
    closeSaveFailedTitle: '선택이 저장되지 않음',
    closeSaveFailedMessage: '오류로 인해 팝업을 저장하지 못했습니다.',
    updateSelection: '선택 업데이트',
    closeWithoutSaving: '저장하지 않고 닫기',
  ),
  'pt': (
    empty: 'Nenhum item',
    noResults: 'Nenhum resultado',
    retry: 'Tentar novamente',
    removeItemTitle: 'Remover item?',
    inUse: '{label} está em uso.',
    removeImpact: 'A remoção pode afetar outros dados.',
    remove: 'Remover',
    saving: 'Salvando…',
    closeSaveFailedTitle: 'Seleção não salva',
    closeSaveFailedMessage:
        'Não foi possível salvar o pop-up devido a um erro.',
    updateSelection: 'Atualizar seleção',
    closeWithoutSaving: 'Fechar sem salvar',
  ),
  'ru': (
    empty: 'Нет элементов',
    noResults: 'Нет результатов',
    retry: 'Повторить',
    removeItemTitle: 'Удалить элемент?',
    inUse: '{label} сейчас используется.',
    removeImpact: 'Удаление может повлиять на другие данные.',
    remove: 'Удалить',
    saving: 'Сохранение…',
    closeSaveFailedTitle: 'Выбор не сохранён',
    closeSaveFailedMessage:
        'Не удалось сохранить всплывающее окно из‑за ошибки.',
    updateSelection: 'Изменить выбор',
    closeWithoutSaving: 'Закрыть без сохранения',
  ),
  'uk': (
    empty: 'Немає елементів',
    noResults: 'Немає результатів',
    retry: 'Повторити',
    removeItemTitle: 'Видалити елемент?',
    inUse: '{label} зараз використовується.',
    removeImpact: 'Видалення може вплинути на інші дані.',
    remove: 'Видалити',
    saving: 'Збереження…',
    closeSaveFailedTitle: 'Вибір не збережено',
    closeSaveFailedMessage:
        'Не вдалося зберегти спливаюче вікно через помилку.',
    updateSelection: 'Оновити вибір',
    closeWithoutSaving: 'Закрити без збереження',
  ),
  'vi': (
    empty: 'Không có mục nào',
    noResults: 'Không có kết quả',
    retry: 'Thử lại',
    removeItemTitle: 'Xóa mục?',
    inUse: '{label} hiện đang được sử dụng.',
    removeImpact: 'Việc xóa có thể ảnh hưởng đến dữ liệu khác.',
    remove: 'Xóa',
    saving: 'Đang lưu…',
    closeSaveFailedTitle: 'Chưa lưu lựa chọn',
    closeSaveFailedMessage: 'Không thể lưu cửa sổ bật lên vì có lỗi.',
    updateSelection: 'Cập nhật lựa chọn',
    closeWithoutSaving: 'Đóng mà không lưu',
  ),
  'zh': (
    empty: '没有项目',
    noResults: '没有结果',
    retry: '重试',
    removeItemTitle: '移除项目？',
    inUse: '{label} 当前正在使用。',
    removeImpact: '移除它可能会影响其他数据。',
    remove: '移除',
    saving: '正在保存…',
    closeSaveFailedTitle: '未保存选择',
    closeSaveFailedMessage: '由于错误，无法保存弹出窗口。',
    updateSelection: '更新选择',
    closeWithoutSaving: '关闭且不保存',
  ),
};

_PickerDefaultMessages _pickerDefaultMessages(BuildContext context) {
  final languageCode = Localizations.maybeLocaleOf(context)?.languageCode;
  return _pickerDefaultMessagesByLanguage[languageCode] ??
      _englishPickerDefaultMessages;
}

String _withLabel(String message, String label) =>
    message.replaceAll('{label}', label);

class DefaultPickerError extends StatelessWidget {
  const DefaultPickerError({required this.retry, super.key});

  final VoidCallback retry;

  @override
  Widget build(BuildContext context) {
    final messages = _pickerDefaultMessages(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: FilledButton.tonalIcon(
          onPressed: retry,
          icon: const Icon(Icons.refresh),
          label: Text(messages.retry),
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
  Widget build(BuildContext context) {
    final messages = _pickerDefaultMessages(context);
    return Text(_withLabel(messages.inUse, label));
  }
}

Future<bool> showDefaultPickerUnselectConfirmation(
  BuildContext context, {
  required String label,
}) async {
  final overlay = Overlay.of(context, rootOverlay: true);
  final messages = _pickerDefaultMessages(context);
  final materialLocalizations = Localizations.of<MaterialLocalizations>(
    context,
    MaterialLocalizations,
  );
  final completer = Completer<bool>();
  late final OverlayEntry entry;

  void close(bool result) {
    if (completer.isCompleted) return;
    entry.remove();
    completer.complete(result);
  }

  entry = OverlayEntry(
    builder: (context) {
      final cancelLabel =
          materialLocalizations?.cancelButtonLabel ??
          MaterialLocalizations.of(context).cancelButtonLabel;
      return Material(
        color: Colors.black54,
        child: Center(
          child: AlertDialog(
            title: Text(messages.removeItemTitle),
            content: Text(
              '${_withLabel(messages.inUse, label)} '
              '${messages.removeImpact}',
            ),
            actions: [
              TextButton(
                onPressed: () => close(false),
                child: Text(cancelLabel),
              ),
              TextButton(
                onPressed: () => close(true),
                child: Text(messages.remove),
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

/// Default wrap shown while `onClose` is saving.
class DefaultPickerCloseSaving extends StatelessWidget {
  const DefaultPickerCloseSaving({required this.child, super.key});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final messages = _pickerDefaultMessages(context);
    final theme = Theme.of(context);
    return Stack(
      children: [
        IgnorePointer(child: child),
        const Positioned.fill(child: ColoredBox(color: Color(0x42000000))),
        Center(
          child: Material(
            elevation: 3,
            borderRadius: BorderRadius.circular(12),
            color: theme.colorScheme.surface,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const CircularProgressIndicator(strokeWidth: 2),
                  const SizedBox(height: 12),
                  Text(messages.saving, style: theme.textTheme.bodyMedium),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

Future<CloseSaveFailedAction> showDefaultPickerCloseSaveFailed(
  BuildContext context,
) async {
  final overlay = Overlay.of(context, rootOverlay: true);
  final messages = _pickerDefaultMessages(context);
  final completer = Completer<CloseSaveFailedAction>();
  late final OverlayEntry entry;

  void close(CloseSaveFailedAction result) {
    if (completer.isCompleted) return;
    entry.remove();
    completer.complete(result);
  }

  entry = OverlayEntry(
    builder: (context) {
      return Material(
        color: Colors.black54,
        child: Center(
          child: AlertDialog(
            title: Text(messages.closeSaveFailedTitle),
            content: Text(messages.closeSaveFailedMessage),
            actions: [
              TextButton(
                onPressed: () => close(CloseSaveFailedAction.updateSelection),
                child: Text(messages.updateSelection),
              ),
              TextButton(
                onPressed: () =>
                    close(CloseSaveFailedAction.closeWithoutSaving),
                child: Text(messages.closeWithoutSaving),
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

Future<bool> applyUnselectPolicy<T, K>(
  BuildContext context,
  GenericRawPickerConfig<T, K> config,
  T item,
  PickerUnselectPolicy policy,
) async {
  switch (policy) {
    case PickerUnselectPolicy.blocked:
      final content =
          config.unselectWarningBuilder?.call(context, item) ??
          DefaultPickerUnselectWarning(label: config.labelOf(item));
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: content, duration: const Duration(seconds: 2)),
      );
      return false;
    case PickerUnselectPolicy.confirm:
      return config.unselectConfirmationBuilder?.call(context, item) ??
          showDefaultPickerUnselectConfirmation(
            context,
            label: config.labelOf(item),
          );
    case PickerUnselectPolicy.allow:
      return true;
  }
}
