import 'dart:async';

import 'package:flutter/material.dart';
import 'package:search_anchor_picker/search_anchor_picker.dart';

import 'example_card.dart';
import 'people.dart';

enum BulkCommands { none, filtered, loaded, all }

enum RelatedStatus {
  none,
  knownDirectory,
  pagedDirectory,
  blockedInUse,
  confirmMember,
  lockedInactive,
}

PickerRelatedListItemStatus? relatedStatus(
  RelatedStatus related,
  Person person,
) {
  switch (related) {
    case RelatedStatus.none:
      return null;
    case RelatedStatus.knownDirectory:
      return PickerRelatedListItemStatus(
        auxiliaryMembership: knownDirectoryIds.contains(person.id)
            ? PickerAuxiliaryMembership.member
            : PickerAuxiliaryMembership.notMember,
      );
    case RelatedStatus.pagedDirectory:
      return PickerRelatedListItemStatus(
        auxiliaryMembership: pagedDirectoryIds.contains(person.id)
            ? PickerAuxiliaryMembership.member
            : PickerAuxiliaryMembership.unknown,
      );
    case RelatedStatus.blockedInUse:
      return PickerRelatedListItemStatus(
        auxiliaryMembership: knownDirectoryIds.contains(person.id)
            ? PickerAuxiliaryMembership.member
            : PickerAuxiliaryMembership.notMember,
        unselectPolicy: person.inUse
            ? PickerUnselectPolicy.blocked
            : PickerUnselectPolicy.allow,
      );
    case RelatedStatus.lockedInactive:
      return PickerRelatedListItemStatus(selectable: !person.locked);
    case RelatedStatus.confirmMember:
      return PickerRelatedListItemStatus(
        auxiliaryMembership: knownDirectoryIds.contains(person.id)
            ? PickerAuxiliaryMembership.member
            : PickerAuxiliaryMembership.notMember,
        unselectPolicy: knownDirectoryIds.contains(person.id)
            ? PickerUnselectPolicy.confirm
            : PickerUnselectPolicy.allow,
      );
  }
}

class SimpleCard extends StatefulWidget {
  const SimpleCard({
    required this.title,
    required this.persistLabel,
    required this.difference,
    required this.source,
    super.key,
    this.seed = const {},
    this.mode = SelectionMode.multi,
    this.persist = Persist.close,
    this.selectedFirst = true,
    this.fullScreen = false,
    this.failClose = false,
    this.failChange = false,
    this.failLoad = false,
    this.failSnackbar = false,
    this.customFail = false,
    this.customSaving = false,
    this.bulk = BulkCommands.none,
    this.wide = false,
    this.viewConstraints,
    this.saveDelay,
    this.loadItems,
    this.includeSelectedInLoad = false,
    this.related = RelatedStatus.none,
    this.emptyText,
    this.noResultsText,
    this.showChips = true,
  });

  final String title;
  final String persistLabel;
  final String difference;
  final String source;
  final Set<int> seed;
  final SelectionMode mode;
  final Persist persist;
  final bool selectedFirst;
  final bool fullScreen;
  final bool failClose;
  final bool failChange;
  final bool failLoad;
  final bool failSnackbar;
  final bool customFail;
  final bool customSaving;
  final BulkCommands bulk;
  final bool wide;
  final BoxConstraints? viewConstraints;
  final Duration? saveDelay;
  final Future<List<Person>> Function(BuildContext context)? loadItems;
  final bool includeSelectedInLoad;
  final RelatedStatus related;
  final String? emptyText;
  final String? noResultsText;
  final bool showChips;

  @override
  State<SimpleCard> createState() => _SimpleCardState();
}

class _SimpleCardState extends State<SimpleCard> {
  late final Set<int> _selected;
  bool _fail = true;

  @override
  void initState() {
    super.initState();
    _selected = {...widget.seed};
  }

  @override
  Widget build(BuildContext context) {
    return ExampleCard(
      title: widget.title,
      persist: widget.persistLabel,
      difference: widget.difference,
      source: widget.source,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (widget.failClose || widget.failChange || widget.failLoad)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Wrap(
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  Checkbox(
                    value: _fail,
                    onChanged: (value) =>
                        setState(() => _fail = value ?? false),
                  ),
                  Text(_failLabel),
                ],
              ),
            ),
          SearchAnchorPicker<Person>(
            config: peopleConfig(
              title: widget.title,
              loadItems:
                  widget.failLoad ||
                      widget.includeSelectedInLoad ||
                      widget.loadItems != null
                  ? _load
                  : null,
              selectedFirst: widget.selectedFirst,
              relatedListItemStatusOf: widget.related == RelatedStatus.none
                  ? null
                  : (person) => relatedStatus(widget.related, person)!,
            ),
            initialSelectedIds: _selected.toList(),
            selectionMode: widget.mode,
            isFullScreen: widget.fullScreen,
            viewHintText: 'Search people',
            emptyText: widget.emptyText,
            noResultsText: widget.noResultsText,
            viewConstraints: widget.viewConstraints ?? popupConstraints,
            onChange: widget.persist == Persist.change
                ? (delta) async {
                    await _maybeDelay();
                    if (widget.failChange && _fail) {
                      _showFailSnack('API fail change');
                      throw StateError('simulated onChange failure');
                    }
                    setState(() => applyDelta(_selected, delta));
                  }
                : null,
            onClose: widget.persist == Persist.close
                ? (result) async {
                    await _maybeDelay();
                    if (widget.failClose && _fail && !result.isEmpty) {
                      throw StateError('simulated onClose failure');
                    }
                    setState(() => applyDelta(_selected, result));
                  }
                : null,
            closeSavingBuilder: widget.customSaving ? _savingWrap : null,
            closeSaveFailedBuilder: widget.customFail ? _customFailClose : null,
            headerBuilder: widget.bulk == BulkCommands.none
                ? null
                : (context, controller, items) => _bulkButtons(controller),
            triggerBuilder: (context, open, _) => peopleFieldTrigger(
              open,
              _selected,
              onDeleted: (id) => setState(() => _selected.remove(id)),
              selectionMode: widget.mode,
              showChips: widget.showChips,
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _bulkButtons(GenericPickerController<Person, int> controller) {
    final filtered =
        widget.bulk == BulkCommands.filtered || widget.bulk == BulkCommands.all;
    final loaded =
        widget.bulk == BulkCommands.loaded || widget.bulk == BulkCommands.all;
    final cells = <Widget>[
      if (filtered) ...[
        _bulkCell(
          label: 'Select results',
          onPressed: controller.selectFiltered,
        ),
        _bulkCell(label: 'Clear results', onPressed: controller.clearFiltered),
      ],
      if (loaded) ...[
        _bulkCell(label: 'Select loaded', onPressed: controller.selectLoaded),
        _bulkCell(label: 'Clear loaded', onPressed: controller.clearLoaded),
      ],
    ];
    final columns = widget.wide && cells.length == 4 ? 4 : 2;
    final rows = <TableRow>[];
    for (var i = 0; i < cells.length; i += columns) {
      final end = (i + columns <= cells.length) ? i + columns : cells.length;
      final rowCells = [
        ...cells.sublist(i, end),
        for (var pad = end - i; pad < columns; pad++) const SizedBox.shrink(),
      ];
      rows.add(
        TableRow(
          children: [
            for (final cell in rowCells)
              Padding(padding: const EdgeInsets.all(4), child: cell),
          ],
        ),
      );
    }
    return [
      Padding(
        padding: const EdgeInsets.fromLTRB(8, 8, 8, 4),
        child: Table(children: rows),
      ),
    ];
  }

  Widget _bulkCell({required String label, required VoidCallback onPressed}) {
    return OutlinedButton(
      onPressed: onPressed,
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
        visualDensity: VisualDensity.compact,
      ),
      child: Text(label, textAlign: TextAlign.center),
    );
  }

  String get _failLabel {
    if (widget.failLoad) return 'API fail search';
    if (widget.failChange) return 'API fail change';
    return 'API fail close';
  }

  Future<void> _maybeDelay() async {
    final delay = widget.saveDelay;
    if (delay != null) await Future<void>.delayed(delay);
  }

  void _showFailSnack(String message) {
    if (!widget.failSnackbar || !mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(content: Text(message), behavior: SnackBarBehavior.floating),
      );
  }

  Future<List<Person>> _load(BuildContext context) async {
    if (widget.failLoad) {
      await Future<void>.delayed(const Duration(milliseconds: 500));
      if (_fail) throw StateError('simulated search API failure');
    }
    if (widget.includeSelectedInLoad) return _selectedPlusCatalog();
    if (widget.loadItems != null) {
      if (!context.mounted) return const <Person>[];
      return widget.loadItems!(context);
    }
    return people;
  }

  Widget _savingWrap(BuildContext context, Widget child) {
    final theme = Theme.of(context);
    return Stack(
      children: [
        IgnorePointer(child: child),
        Positioned.fill(
          child: ColoredBox(
            color: theme.colorScheme.scrim.withValues(alpha: 0.45),
          ),
        ),
        Center(
          child: Material(
            elevation: 6,
            color: theme.colorScheme.surface,
            borderRadius: BorderRadius.circular(16),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(28, 24, 28, 20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(
                    width: 36,
                    height: 36,
                    child: CircularProgressIndicator(
                      strokeWidth: 3,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text('Writing members…', style: theme.textTheme.titleSmall),
                  const SizedBox(height: 4),
                  Text(
                    'Stay in the popup until this finishes.',
                    style: theme.textTheme.bodySmall,
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Future<CloseSaveFailedAction> _customFailClose(
    BuildContext context,
    Object error,
    StackTrace stackTrace,
  ) async {
    final overlay = Overlay.of(context);
    final completer = Completer<CloseSaveFailedAction>();
    late final OverlayEntry entry;

    void finish(CloseSaveFailedAction action) {
      if (completer.isCompleted) return;
      entry.remove();
      completer.complete(action);
    }

    entry = OverlayEntry(
      builder: (context) {
        return Material(
          color: Colors.black54,
          child: Center(
            child: AlertDialog(
              title: const Text('Could not write members'),
              content: Text('$error'),
              actions: [
                TextButton(
                  onPressed: () =>
                      finish(CloseSaveFailedAction.updateSelection),
                  child: const Text('Keep editing'),
                ),
                TextButton(
                  onPressed: () =>
                      finish(CloseSaveFailedAction.closeWithoutSaving),
                  child: const Text('Close without saving'),
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

  List<Person> _selectedPlusCatalog() {
    final catalog = mainCatalogPeople();
    final catalogIds = catalog.map((person) => person.id).toSet();
    final extras = [
      for (final person in people)
        if (_selected.contains(person.id) && !catalogIds.contains(person.id))
          person,
    ];
    return [...extras, ...catalog];
  }
}
