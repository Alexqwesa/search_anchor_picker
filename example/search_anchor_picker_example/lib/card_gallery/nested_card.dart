import 'package:flutter/material.dart';
import 'package:search_anchor_picker/search_anchor_picker.dart';

import 'example_card.dart';
import 'people.dart';

/// How nested sublists relate to the parent picker / field.
enum NestedRelation {
  /// Sublist membership is independent. It shows in the card subtitle.
  unrelated,

  /// Sublist membership is independent and shares the parent field chips.
  /// It does not add parent rows and is not shown as a subtitle.
  unrelatedField,

  /// Parent list and field follow sublist checks. Uncheck in a sublist and
  /// the person leaves the parent.
  direct,

  /// Like [direct], but a person who is still checked on the parent stays.
  directStay,

  /// Checking the parent makes the person appear as a row in each sublist.
  reverseAppear,

  /// Checking the parent makes the person checkable in each sublist.
  reverseAvailable,
}

class NestedCard extends StatefulWidget {
  const NestedCard({
    required this.title,
    required this.persistLabel,
    required this.difference,
    required this.source,
    super.key,
    this.relation = NestedRelation.unrelated,
    this.effect = SubPickerParentSelectionEffect.none,
    this.childPersist = Persist.change,
    this.parentPersist = Persist.close,
    this.sublists = 2,
    this.deep = false,
    this.relatedOnParent = false,
    this.childMode = SelectionMode.multi,
    this.childBulk = false,
    this.childLockedInactive = false,
    this.childUnselect = PickerUnselectPolicy.allow,
    this.shortMainList = true,
    this.viewConstraints,
    this.directoryOffset,
    this.directoryConstraints,
    this.watchlistOffset,
    this.watchlistConstraints,
  });

  final String title;
  final String persistLabel;
  final String difference;
  final String source;
  final NestedRelation relation;
  final SubPickerParentSelectionEffect effect;
  final Persist childPersist;
  final Persist parentPersist;
  final int sublists;
  final bool deep;
  final bool relatedOnParent;
  final SelectionMode childMode;
  final bool childBulk;
  final bool childLockedInactive;
  final PickerUnselectPolicy childUnselect;
  final bool shortMainList;
  final BoxConstraints? viewConstraints;
  final Offset? directoryOffset;
  final BoxConstraints? directoryConstraints;
  final Offset? watchlistOffset;
  final BoxConstraints? watchlistConstraints;

  @override
  State<NestedCard> createState() => _NestedCardState();
}

class _NestedCardState extends State<NestedCard> {
  final Set<int> _selected = {1, 4};
  final Set<int> _directory = {...knownDirectoryIds};
  final Set<int> _watchlist = {...knownWatchlistIds};
  final Set<int> _team = {...knownTeamIds};
  final Set<int> _favorites = {1};
  Set<int>? _directStayOpenSeed;

  @override
  void initState() {
    super.initState();
    if (widget.relation == NestedRelation.direct) {
      _selected
        ..clear()
        ..addAll(_sublistUnion);
    }
  }

  bool get _hasWatchlist => widget.sublists >= 2;
  bool get _hasTeam => widget.sublists >= 3;

  Set<int> get _sublistUnion {
    final ids = {..._directory};
    if (_hasWatchlist) ids.addAll(_watchlist);
    if (_hasTeam) ids.addAll(_team);
    return ids;
  }

  SubPickerParentSelectionEffect get _effect {
    switch (widget.relation) {
      case NestedRelation.direct:
        return SubPickerParentSelectionEffect.mirror;
      case NestedRelation.directStay:
      case NestedRelation.unrelated:
      case NestedRelation.unrelatedField:
      case NestedRelation.reverseAppear:
      case NestedRelation.reverseAvailable:
        return widget.effect;
    }
  }

  @override
  Widget build(BuildContext context) {
    return ExampleCard(
      title: widget.title,
      persist: widget.persistLabel,
      difference: widget.difference,
      source: widget.source,
      footer: _showFooter
          ? Text(_footer, style: Theme.of(context).textTheme.bodySmall)
          : null,
      child: SearchAnchorPicker<Person>(
        config: peopleConfig(
          title: widget.title,
          loadItems: _parentLoad,
          reloadKey: _parentReloadKey,
          relatedListItemStatusOf: widget.relatedOnParent
              ? (person) => PickerRelatedListItemStatus(
                  auxiliaryMembership: _directory.contains(person.id)
                      ? PickerAuxiliaryMembership.member
                      : PickerAuxiliaryMembership.notMember,
                )
              : null,
        ),
        initialSelectedIds: _parentOpenIds.toList(),
        isFullScreen: false,
        viewHintText: 'Search people',
        viewConstraints: widget.viewConstraints ?? popupConstraints,
        onChange: widget.parentPersist == Persist.change
            ? (delta) => setState(() {
                applyDelta(_selected, delta);
                _directStayOpenSeed = null;
              })
            : null,
        onClose: widget.parentPersist == Persist.close
            ? (result) {
                setState(() {
                  applyDelta(_selected, result);
                  _directStayOpenSeed = null;
                });
              }
            : null,
        headerBuilder: (context, controller, items) => [
          _sublistTile(
            parent: controller,
            title: 'Directory',
            icon: Icons.folder_shared_outlined,
            ids: _directory,
            catalogIds: directoryCatalogIds,
            offset: widget.directoryOffset,
            constraints: widget.directoryConstraints,
            nestedHeader: widget.deep || widget.childBulk,
          ),
          if (_hasWatchlist)
            _sublistTile(
              parent: controller,
              title: 'Watchlist',
              icon: Icons.visibility_outlined,
              ids: _watchlist,
              catalogIds: watchlistCatalogIds,
              offset: widget.watchlistOffset,
              constraints: widget.watchlistConstraints,
            ),
          if (_hasTeam)
            _sublistTile(
              parent: controller,
              title: 'Team',
              icon: Icons.groups_outlined,
              ids: _team,
              catalogIds: teamCatalogIds,
            ),
        ],
        triggerBuilder: (context, open, _) => peopleFieldTrigger(
          open,
          _fieldChipIds,
          onDeleted: (id) => setState(() => _deleteChip(id)),
        ),
      ),
    );
  }

  Future<List<Person>> _parentLoad(BuildContext context) async {
    final ids = _parentRowIds();
    return people.where((person) => ids.contains(person.id)).toList();
  }

  Set<int> _parentRowIds() {
    switch (widget.relation) {
      case NestedRelation.direct:
        return _sublistUnion;
      case NestedRelation.directStay:
        return {...shortMainIds, ..._sublistUnion, ..._selected};
      case NestedRelation.unrelated:
      case NestedRelation.unrelatedField:
      case NestedRelation.reverseAppear:
      case NestedRelation.reverseAvailable:
        return widget.shortMainList
            ? shortMainIds
            : {for (final p in people) p.id};
    }
  }

  /// Checked rows in the open parent picker.
  Set<int> get _parentCheckedIds {
    switch (widget.relation) {
      case NestedRelation.direct:
      case NestedRelation.directStay:
        return {..._selected, ..._sublistUnion};
      case NestedRelation.unrelated:
      case NestedRelation.unrelatedField:
      case NestedRelation.reverseAppear:
      case NestedRelation.reverseAvailable:
        return {..._selected};
    }
  }

  /// Seed at open. Direct-stay freezes it so child writes cannot reseed
  /// live parent checkboxes back to field ∪ union.
  Set<int> get _parentOpenIds {
    if (widget.relation != NestedRelation.directStay) {
      return _parentCheckedIds;
    }
    return _directStayOpenSeed ??= {..._selected, ..._sublistUnion};
  }

  /// Chips on the field. Direct follows sublists; unrelated extras are a union.
  Set<int> get _fieldChipIds {
    switch (widget.relation) {
      case NestedRelation.direct:
        return {..._selected};
      case NestedRelation.unrelatedField:
        return {..._selected, ..._sublistUnion};
      case NestedRelation.directStay:
      case NestedRelation.unrelated:
      case NestedRelation.reverseAppear:
      case NestedRelation.reverseAvailable:
        return {..._selected};
    }
  }

  void _deleteChip(int id) {
    _selected.remove(id);
    if (widget.relation == NestedRelation.direct ||
        widget.relation == NestedRelation.unrelatedField) {
      final delta = PickerDelta<int>(added: const {}, removed: {id});
      for (final ids in [_directory, _watchlist, _team]) {
        if (ids.contains(id)) _persistSublist(ids, delta);
      }
    }
  }

  void _persistSublist(Set<int> ids, PickerDelta<int> delta) {
    applyDelta(ids, delta);
  }

  void _onChildDelta(
    GenericPickerController<Person, int> parent,
    Set<int> ids,
    PickerDelta<int> delta,
  ) {
    switch (widget.relation) {
      case NestedRelation.directStay:
        final unionBefore = {..._sublistUnion};
        final pendingNow = {...parent.pendingIds};
        _persistSublist(ids, delta);
        final stay = {
          for (final id in pendingNow)
            if (_selected.contains(id) || !unionBefore.contains(id)) id,
        };
        parent.syncPending(
          added: delta.added,
          removed: [
            for (final id in delta.removed)
              if (!stay.contains(id)) id,
          ],
        );
      case NestedRelation.direct:
        _persistSublist(ids, delta);
        applyEffectToSelection(
          _selected,
          SubPickerParentSelectionEffect.mirror,
          delta,
        );
      case NestedRelation.unrelated:
      case NestedRelation.unrelatedField:
      case NestedRelation.reverseAppear:
      case NestedRelation.reverseAvailable:
        _persistSublist(ids, delta);
        applyEffectToSelection(_selected, _effect, delta);
    }
  }

  Object? get _parentReloadKey {
    switch (widget.relation) {
      case NestedRelation.direct:
        return _sublistUnion;
      case NestedRelation.directStay:
        return {..._sublistUnion, ..._selected};
      case NestedRelation.unrelated:
      case NestedRelation.unrelatedField:
      case NestedRelation.reverseAppear:
      case NestedRelation.reverseAvailable:
        return widget.shortMainList ? shortMainIds : null;
    }
  }

  bool get _showFooter => widget.relation != NestedRelation.unrelatedField;

  String get _footer {
    final parts = <String>['Directory: ${namesOf(_directory)}'];
    if (_hasWatchlist) parts.add('Watchlist: ${namesOf(_watchlist)}');
    if (_hasTeam) parts.add('Team: ${namesOf(_team)}');
    if (widget.deep) parts.add('Favorites: ${namesOf(_favorites)}');
    return parts.join(' · ');
  }

  Widget _sublistTile({
    required GenericPickerController<Person, int> parent,
    required String title,
    required IconData icon,
    required Set<int> ids,
    required Set<int> catalogIds,
    Offset? offset,
    BoxConstraints? constraints,
    bool nestedHeader = false,
  }) {
    final effect = _effect;
    return SubPickerTile<Person>(
      title: title,
      icon: icon,
      config: _childConfig(title, parent, catalogIds),
      initialSelectedIds: ids.toList(),
      selectionMode: widget.childMode,
      parentController: effect == SubPickerParentSelectionEffect.none
          ? null
          : parent,
      parentSelectionEffect: effect,
      isFullScreen: offset != null || constraints != null ? false : null,
      menuOffset: offset ?? const Offset(30, 30),
      viewConstraints: constraints,
      onChange: widget.childPersist == Persist.change
          ? (delta) => setState(() => _onChildDelta(parent, ids, delta))
          : null,
      onClose: widget.childPersist == Persist.close
          ? (result) => setState(() => _onChildDelta(parent, ids, result))
          : null,
      headerBuilder: nestedHeader
          ? (context, directoryController, items) => [
              if (widget.childBulk) ...[
                TextButton(
                  onPressed: directoryController.selectFiltered,
                  child: const Text('Select results'),
                ),
                TextButton(
                  onPressed: directoryController.clearFiltered,
                  child: const Text('Clear results'),
                ),
              ],
              if (widget.deep) _favoritesTile(),
            ]
          : null,
    );
  }

  Widget _favoritesTile() {
    return SubPickerTile<Person>(
      title: 'Favorites',
      icon: Icons.star_outline,
      config: peopleConfig(
        title: 'Favorites',
        loadItems: (_) async => peopleIn(favoritesCatalogIds),
      ),
      initialSelectedIds: _favorites.toList(),
      onChange: (delta) => setState(() => applyDelta(_favorites, delta)),
    );
  }

  PickerConfig<Person> _childConfig(
    String title,
    GenericPickerController<Person, int> parent,
    Set<int> catalogIds,
  ) {
    Future<List<Person>> loadCatalog(BuildContext _) async =>
        peopleIn(catalogIds);
    if (widget.relation == NestedRelation.reverseAppear) {
      return peopleConfig(
        title: title,
        loadItems: (_) async => people
            .where(
              (person) =>
                  catalogIds.contains(person.id) &&
                  parent.pendingIds.contains(person.id),
            )
            .toList(),
        listenable: parent.pendingIdsListenable,
      );
    }
    final gateUnselect = widget.childUnselect != PickerUnselectPolicy.allow;
    final reverseAvailable = widget.relation == NestedRelation.reverseAvailable;
    if (!gateUnselect && !widget.childLockedInactive && !reverseAvailable) {
      return peopleConfig(title: title, loadItems: loadCatalog);
    }
    return peopleConfig(
      title: title,
      loadItems: loadCatalog,
      relatedListItemStatusOf: (person) {
        final usedByField = parent.pendingIds.contains(person.id);
        return PickerRelatedListItemStatus(
          selectable: reverseAvailable
              ? usedByField
              : !(widget.childLockedInactive && person.locked),
          unselectPolicy: person.inUse || usedByField
              ? widget.childUnselect
              : PickerUnselectPolicy.allow,
        );
      },
      relatedListItemStatusListenable: gateUnselect || reverseAvailable
          ? parent.pendingIdsListenable
          : null,
    );
  }
}
