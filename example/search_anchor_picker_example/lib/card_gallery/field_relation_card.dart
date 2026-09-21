import 'package:flutter/material.dart';
import 'package:search_anchor_picker/search_anchor_picker.dart';

import 'example_card.dart';
import 'people.dart';

/// Which rows the parent popup loads.
enum ParentRowSet {
  /// Every person. Sublist extras are visible as parent checkboxes.
  allPeople,

  /// Ada … Knuth only. Sublist extras can become hidden selected chips.
  mainCatalog,

  /// Ada … Margaret (5 rows).
  shortMain,
}

/// How the directory sublist treats people who are already on the field.
enum SublistFieldUnselect {
  /// Directory unselect is always allowed.
  allow,

  /// Directory unselect is blocked while the person is pending on the parent.
  blockIfOnField,

  /// Directory unselect asks for confirmation while the person is on the parent.
  confirmIfOnField,
}

/// Nested picker whose parent rows, field chips, and directory extras interact.
class FieldRelationCard extends StatefulWidget {
  const FieldRelationCard({
    required this.title,
    required this.persistLabel,
    required this.difference,
    required this.source,
    super.key,
    this.effect = SubPickerParentSelectionEffect.none,
    this.parentRows = ParentRowSet.shortMain,
    this.sublistUnselect = SublistFieldUnselect.allow,
    this.relatedOnParent = true,
    this.fieldSeed = const {1, 4},
    this.directorySeed = knownDirectoryIds,
    this.sublists = 3,
  });

  final String title;
  final String persistLabel;
  final String difference;
  final String source;
  final SubPickerParentSelectionEffect effect;
  final ParentRowSet parentRows;
  final SublistFieldUnselect sublistUnselect;
  final bool relatedOnParent;
  final Set<int> fieldSeed;
  final Set<int> directorySeed;
  final int sublists;

  @override
  State<FieldRelationCard> createState() => _FieldRelationCardState();
}

class _FieldRelationCardState extends State<FieldRelationCard> {
  late final Set<int> _selected;
  late final Set<int> _directory;
  late final Set<int> _watchlist;
  late final Set<int> _team;

  @override
  void initState() {
    super.initState();
    _selected = {...widget.fieldSeed};
    _directory = {...widget.directorySeed};
    _watchlist = {...knownWatchlistIds};
    _team = {...knownTeamIds};
  }

  @override
  Widget build(BuildContext context) {
    final parts = <String>['Directory: ${namesOf(_directory)}'];
    if (widget.sublists >= 2) {
      parts.add('Watchlist: ${namesOf(_watchlist)}');
    }
    if (widget.sublists >= 3) {
      parts.add('Team: ${namesOf(_team)}');
    }
    return ExampleCard(
      title: widget.title,
      persist: widget.persistLabel,
      difference: widget.difference,
      source: widget.source,
      footer: Text(
        parts.join(' · '),
        style: Theme.of(context).textTheme.bodySmall,
      ),
      child: SearchAnchorPicker<Person>(
        config: peopleConfig(
          title: widget.title,
          loadItems: switch (widget.parentRows) {
            ParentRowSet.allPeople => null,
            ParentRowSet.mainCatalog => (_) async => mainCatalogPeople(),
            ParentRowSet.shortMain =>
              (_) async => people
                  .where((person) => shortMainIds.contains(person.id))
                  .toList(),
          },
          relatedListItemStatusOf: widget.relatedOnParent
              ? (person) => PickerRelatedListItemStatus(
                  auxiliaryMembership: _directory.contains(person.id)
                      ? PickerAuxiliaryMembership.member
                      : PickerAuxiliaryMembership.notMember,
                )
              : null,
        ),
        initialSelectedIds: _selected.toList(),
        isFullScreen: false,
        viewHintText: 'Search people',
        viewConstraints: popupConstraints,
        onClose: (result) {
          setState(() => applyDelta(_selected, result));
        },
        headerBuilder: (context, controller, items) => [
          _sublistTile(
            parent: controller,
            title: 'Directory',
            icon: Icons.folder_shared_outlined,
            ids: _directory,
            catalogIds: directoryCatalogIds,
            lockToField: widget.sublistUnselect != SublistFieldUnselect.allow,
          ),
          if (widget.sublists >= 2)
            _sublistTile(
              parent: controller,
              title: 'Watchlist',
              icon: Icons.visibility_outlined,
              ids: _watchlist,
              catalogIds: watchlistCatalogIds,
              lockToField: false,
            ),
          if (widget.sublists >= 3)
            _sublistTile(
              parent: controller,
              title: 'Team',
              icon: Icons.groups_outlined,
              ids: _team,
              catalogIds: teamCatalogIds,
              lockToField: false,
            ),
        ],
        triggerBuilder: (context, open, _) => peopleFieldTrigger(
          open,
          _selected,
          onDeleted: (id) => setState(() => _selected.remove(id)),
        ),
      ),
    );
  }

  Widget _sublistTile({
    required GenericPickerController<Person, int> parent,
    required String title,
    required IconData icon,
    required Set<int> ids,
    required Set<int> catalogIds,
    required bool lockToField,
  }) {
    return SubPickerTile<Person>(
      title: title,
      icon: icon,
      config: peopleConfig(
        title: title,
        loadItems: (_) async => peopleIn(catalogIds),
        relatedListItemStatusOf: lockToField
            ? (person) => PickerRelatedListItemStatus(
                unselectPolicy: _directoryUnselectPolicy(parent, person.id),
              )
            : null,
        relatedListItemStatusListenable: lockToField
            ? parent.pendingIdsListenable
            : null,
      ),
      initialSelectedIds: ids.toList(),
      parentController: widget.effect == SubPickerParentSelectionEffect.none
          ? null
          : parent,
      parentSelectionEffect: widget.effect,
      onChange: (delta) => setState(() {
        applyDelta(ids, delta);
        applyEffectToSelection(_selected, widget.effect, delta);
      }),
    );
  }

  PickerUnselectPolicy _directoryUnselectPolicy(
    GenericPickerController<Person, int> parent,
    int id,
  ) {
    final onField = parent.pendingIds.contains(id);
    if (!onField) return PickerUnselectPolicy.allow;
    return switch (widget.sublistUnselect) {
      SublistFieldUnselect.allow => PickerUnselectPolicy.allow,
      SublistFieldUnselect.blockIfOnField => PickerUnselectPolicy.blocked,
      SublistFieldUnselect.confirmIfOnField => PickerUnselectPolicy.confirm,
    };
  }
}
