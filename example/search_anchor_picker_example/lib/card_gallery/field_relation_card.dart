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
    this.parentRows = ParentRowSet.allPeople,
    this.sublistUnselect = SublistFieldUnselect.allow,
    this.relatedOnParent = true,
    this.fieldSeed = const {1, 4},
    this.directorySeed = knownDirectoryIds,
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

  @override
  State<FieldRelationCard> createState() => _FieldRelationCardState();
}

class _FieldRelationCardState extends State<FieldRelationCard> {
  late final Set<int> _selected;
  late final Set<int> _directory;

  @override
  void initState() {
    super.initState();
    _selected = {...widget.fieldSeed};
    _directory = {...widget.directorySeed};
  }

  @override
  Widget build(BuildContext context) {
    return ExampleCard(
      title: widget.title,
      persist: widget.persistLabel,
      difference: widget.difference,
      source: widget.source,
      footer: Text(
        'Directory: ${namesOf(_directory)}',
        style: Theme.of(context).textTheme.bodySmall,
      ),
      child: SearchAnchorPicker<Person>(
        config: peopleConfig(
          title: widget.title,
          loadItems: widget.parentRows == ParentRowSet.mainCatalog
              ? (_) async => mainCatalogPeople()
              : null,
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
          _directoryTile(controller),
        ],
        triggerBuilder: (context, open, _) => peopleFieldTrigger(
          open,
          _selected,
          onDeleted: (id) => setState(() => _selected.remove(id)),
        ),
      ),
    );
  }

  Widget _directoryTile(GenericPickerController<Person, int> parent) {
    final lockToField = widget.sublistUnselect != SublistFieldUnselect.allow;
    return SubPickerTile<Person>(
      title: 'Directory membership',
      icon: Icons.folder_shared_outlined,
      config: peopleConfig(
        title: 'Directory',
        relatedListItemStatusOf: lockToField
            ? (person) => PickerRelatedListItemStatus(
                unselectPolicy: _directoryUnselectPolicy(parent, person.id),
              )
            : null,
        relatedListItemStatusListenable: lockToField
            ? parent.pendingIdsListenable
            : null,
      ),
      initialSelectedIds: _directory.toList(),
      parentController: widget.effect == SubPickerParentSelectionEffect.none
          ? null
          : parent,
      parentSelectionEffect: widget.effect,
      onChange: (delta) => setState(() {
        applyDelta(_directory, delta);
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
