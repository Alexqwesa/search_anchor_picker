import 'dart:async';

import 'package:flutter/material.dart';
import 'package:search_anchor_picker/search_anchor_picker.dart';

import 'example_card.dart';
import 'people.dart';

enum BulkCommands { none, filtered, loaded, all }

/// Where off-page people from the kept initial selection appear.
enum HiddenItemsMode { inList, onlyIfSelected, section, none }

enum RelatedStatus {
  none,
  knownDirectory,
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
    case RelatedStatus.lockedInactive:
      return PickerRelatedListItemStatus(selectable: !person.locked);
    case RelatedStatus.blockedInUse:
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
    this.source = '',
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
    this.itemsLoader,
    this.includeSelectedInLoad = false,
    this.related = RelatedStatus.none,
    this.emptyText,
    this.noResultsText,
    this.showChips = true,
    this.emptyCatalog = false,
    this.warnHiddenChip = false,
    this.hiddenItemsControl = false,
    this.visibleCatalogIds,
    this.selectedItemCache = false,
    this.richItemTile = false,
    this.sourceTag,
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
  final ItemsLoader<Person>? itemsLoader;
  final bool includeSelectedInLoad;
  final RelatedStatus related;
  final String? emptyText;
  final String? noResultsText;
  final bool showChips;
  final bool emptyCatalog;
  final bool warnHiddenChip;

  /// Four-way control for off-page people from the kept initial selection.
  final bool hiddenItemsControl;
  final Set<int>? visibleCatalogIds;
  final bool selectedItemCache;
  final bool richItemTile;

  /// `/*source:name*/` region in this file. Replaces [source] in the dialog.
  final String? sourceTag;

  @override
  State<SimpleCard> createState() => _SimpleCardState();
}

class _SimpleCardState extends State<SimpleCard> {
  late final Set<int> _selected;

  /// People for the initial selection this app keeps across closes.
  late List<Person> _keptInitialItems;
  bool _fail = true;
  bool _warnHiddenChip = true;

  HiddenItemsMode _hiddenMode = HiddenItemsMode.section;

  @override
  void initState() {
    super.initState();
    _selected = {...widget.seed};
    _keptInitialItems = peopleIn(_selected);
  }

  @override
  Widget build(BuildContext context) {
    return ExampleCard(
      title: widget.title,
      persist: widget.persistLabel,
      difference: widget.difference,
      source: widget.source,
      sourceTag: widget.sourceTag,
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
          if (widget.hiddenItemsControl)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: SegmentedButton<HiddenItemsMode>(
                showSelectedIcon: false,
                style: const ButtonStyle(
                  visualDensity: VisualDensity.compact,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                segments: const [
                  ButtonSegment(
                    value: HiddenItemsMode.inList,
                    label: Text('In list'),
                  ),
                  ButtonSegment(
                    value: HiddenItemsMode.onlyIfSelected,
                    label: Text('If selected'),
                  ),
                  ButtonSegment(
                    value: HiddenItemsMode.section,
                    label: Text('Section'),
                  ),
                  ButtonSegment(
                    value: HiddenItemsMode.none,
                    label: Text('No'),
                  ),
                ],
                selected: {_hiddenMode},
                onSelectionChanged: (selection) {
                  setState(() => _hiddenMode = selection.first);
                },
              ),
            ),
          if (widget.warnHiddenChip)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Wrap(
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  Checkbox(
                    value: _warnHiddenChip,
                    onChanged: (value) =>
                        setState(() => _warnHiddenChip = value ?? false),
                  ),
                  const Text('Show warning on hidden chip'),
                ],
              ),
            ),
          SearchAnchorPicker<Person>(
            config: peopleConfig(
              title: widget.title,
              reloadKey: widget.hiddenItemsControl ? _hiddenMode : null,
              itemsLoader:
                  widget.failLoad ||
                      widget.includeSelectedInLoad ||
                      widget.emptyCatalog ||
                      widget.hiddenItemsControl ||
                      widget.itemsLoader != null
                  ? _load
                  : null,
              selectedFirst: widget.selectedFirst,
              relatedListItemStatusOf: widget.related == RelatedStatus.none
                  ? null
                  : (person) => relatedStatus(widget.related, person)!,
            ),
            initialSelectedIds: _selected.toList(),
            /*source:hidden-selected*/
            initialSelectedItemCache: /*bold=on*/ _passSelectedItemCache
                ? peopleIn(_selected)
                : null, /*bold=off*/
            /*source-end:hidden-selected*/
            selectionMode: widget.mode,
            itemBuilder: widget.richItemTile ? _richItemTile : null,
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
              onDeleted: _deleteChip,
              selectionMode: widget.mode,
              showChips: widget.showChips,
            ),
          ),
          if (widget.related == RelatedStatus.confirmMember) ...[
            const SizedBox(height: 8),
            Text(
              'Require confirmation: ${namesOf(knownDirectoryIds)}',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _deleteChip(int id) async {
    final person = people.where((item) => item.id == id).firstOrNull;
    if (person != null && widget.related != RelatedStatus.none) {
      final status = relatedStatus(widget.related, person)!;
      final allowed = await applyRelatedListUnselectPolicy(
        context,
        peopleConfig(
          relatedListItemStatusOf: (item) =>
              relatedStatus(widget.related, item)!,
        ),
        person,
        status.unselectPolicy,
      );
      if (!allowed || !mounted) return;
    }
    if (widget.warnHiddenChip && _warnHiddenChip && _isHiddenChip(id)) {
      final allowed = await _confirmHiddenChip(id);
      if (!allowed || !mounted) return;
    }
    setState(() => _selected.remove(id));
  }

  bool get _passSelectedItemCache {
    if (widget.hiddenItemsControl) {
      return _hiddenMode == HiddenItemsMode.section;
    }
    return widget.selectedItemCache;
  }

  bool _isHiddenChip(int id) {
    final visible = _visibleCatalogIds;
    if (visible == null) return false;
    return !visible.contains(id);
  }

  Set<int>? get _visibleCatalogIds {
    final page = widget.visibleCatalogIds;
    if (!widget.hiddenItemsControl || page == null) return page;
    final hiddenIds = {
      for (final person in _offPageInitialItems(page)) person.id,
    };
    return switch (_hiddenMode) {
      HiddenItemsMode.inList => {...page, ...hiddenIds},
      HiddenItemsMode.onlyIfSelected => {
        ...page,
        ...hiddenIds.where(_selected.contains),
      },
      HiddenItemsMode.section || HiddenItemsMode.none => page,
    };
  }

  Future<bool> _confirmHiddenChip(int id) async {
    final name = personName(id);
    final result = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Hidden selection'),
          content: Text(
            '$name is selected but not on this page. '
            'Remove the chip? You cannot pick $name again from this list.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Remove'),
            ),
          ],
        );
      },
    );
    return result ?? false;
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

  Widget _richItemTile(
    BuildContext context,
    Person person,
    bool selected,
    PickerRelatedListItemStatus status,
    PickerItemSource source,
    VoidCallback toggle,
  ) {
    /*source:hidden-selected*/
    final fromCache =
        source == PickerItemSource.initialSelectedItemCache ||
        _keptOffPageIds.contains(person.id);
    /*bold=on*/
    final keptIcon = fromCache ? Icons.bookmark_outline : Icons.person;
    /*bold=off*/
    /*source-end:hidden-selected*/
    return DefaultPickerItemTile(
      selected: selected,
      relatedListItemStatus: status,
      onToggle: (_) => toggle(),
      title: Text(person.name),
      subtitle: Text(
        fromCache ? '${person.team} · not from itemsLoader' : person.team,
      ),
      leading: Icon(keptIcon),
      tooltip: '${person.name} · ${person.team}',
      selectionMode: widget.mode,
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

  Future<List<Person>> _load(BuildContext context, String query) async {
    if (widget.failLoad) {
      await Future<void>.delayed(const Duration(milliseconds: 500));
      if (_fail) throw StateError('simulated search API failure');
    }
    if (widget.includeSelectedInLoad) return _selectedPlusCatalog();
    if (widget.emptyCatalog) return const <Person>[];
    if (widget.hiddenItemsControl) return _loadHiddenItems(context, query);
    if (widget.itemsLoader != null) {
      if (!context.mounted) return const <Person>[];
      return widget.itemsLoader!(context, query);
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

  Future<List<Person>> _loadHiddenItems(
    BuildContext context,
    String query,
  ) async {
    final page = widget.itemsLoader != null
        ? await widget.itemsLoader!(context, query)
        : people.take(4).toList();
    final pageIds = page.map((person) => person.id).toSet();
    final hidden = _offPageInitialItems(pageIds);
    /*source:hidden-selected*/
    /*bold=on*/
    return switch (_hiddenMode) {
      HiddenItemsMode.inList => [...page, ...hidden],
      HiddenItemsMode.onlyIfSelected => [
        ...page,
        for (final person in hidden)
          if (_selected.contains(person.id)) person,
      ],
      HiddenItemsMode.section || HiddenItemsMode.none => page,
    };
    /*bold=off*/
    /*source-end:hidden-selected*/
  }

  Set<int> get _keptOffPageIds {
    final page = widget.visibleCatalogIds ?? const <int>{};
    return {
      for (final person in _keptInitialItems)
        if (!page.contains(person.id)) person.id,
    };
  }

  /// Off-page people from the old initial selection. Unselect does not drop them.
  List<Person> _offPageInitialItems(Set<int> pageIds) {
    return [
      for (final person in _keptInitialItems)
        if (!pageIds.contains(person.id)) person,
    ];
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
