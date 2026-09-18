import 'package:flutter/material.dart';
import 'package:search_anchor_picker/search_anchor_picker.dart';

import 'example_card.dart';
import 'people.dart';

class NestedCard extends StatefulWidget {
  const NestedCard({
    required this.title,
    required this.persistLabel,
    required this.difference,
    required this.source,
    super.key,
    this.effect = SubPickerParentSelectionEffect.none,
    this.childPersist = Persist.change,
    this.parentPersist = Persist.close,
    this.secondSublist = false,
    this.deep = false,
    this.relatedOnParent = false,
    this.childMode = SelectionMode.multi,
    this.childBulk = false,
    this.childLockedInactive = false,
    this.childUnselect = PickerUnselectPolicy.allow,
  });

  final String title;
  final String persistLabel;
  final String difference;
  final String source;
  final SubPickerParentSelectionEffect effect;
  final Persist childPersist;
  final Persist parentPersist;
  final bool secondSublist;
  final bool deep;
  final bool relatedOnParent;
  final SelectionMode childMode;
  final bool childBulk;
  final bool childLockedInactive;
  final PickerUnselectPolicy childUnselect;

  @override
  State<NestedCard> createState() => _NestedCardState();
}

class _NestedCardState extends State<NestedCard> {
  final Set<int> _selected = {1, 4};
  final Set<int> _directory = {...knownDirectoryIds};
  final Set<int> _watchlist = {...knownWatchlistIds};
  final Set<int> _favorites = {1};

  @override
  Widget build(BuildContext context) {
    return ExampleCard(
      title: widget.title,
      persist: widget.persistLabel,
      difference: widget.difference,
      source: widget.source,
      footer: Text(_footer, style: Theme.of(context).textTheme.bodySmall),
      child: ChipField(
        ids: _selected,
        onDeleted: (id) => setState(() => _selected.remove(id)),
        addButton: SearchAnchorPicker<Person>(
          config: peopleConfig(
            title: widget.title,
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
          onChange: widget.parentPersist == Persist.change
              ? (delta) => setState(() => applyDelta(_selected, delta))
              : null,
          onClose: widget.parentPersist == Persist.close
              ? (result) {
                  setState(() => applyDelta(_selected, result));
                }
              : null,
          headerBuilder: (context, controller, items) => [
            _directoryTile(controller),
            if (widget.secondSublist) _watchlistTile(),
          ],
          triggerBuilder: addTrigger,
        ),
      ),
    );
  }

  String get _footer {
    final parts = <String>['Directory: ${namesOf(_directory)}'];
    if (widget.secondSublist) parts.add('Watchlist: ${namesOf(_watchlist)}');
    if (widget.deep) parts.add('Favorites: ${namesOf(_favorites)}');
    return parts.join(' · ');
  }

  Widget _directoryTile(GenericPickerController<Person, int> parent) {
    return SubPickerTile<Person>(
      title: 'Directory membership',
      icon: Icons.folder_shared_outlined,
      config: _childConfig('Directory', parent),
      initialSelectedIds: _directory.toList(),
      selectionMode: widget.childMode,
      parentController: widget.effect == SubPickerParentSelectionEffect.none
          ? null
          : parent,
      parentSelectionEffect: widget.effect,
      onChange: widget.childPersist == Persist.change
          ? (delta) => setState(() {
              applyDelta(_directory, delta);
              applyEffectToSelection(_selected, widget.effect, delta);
            })
          : null,
      onClose: widget.childPersist == Persist.close
          ? (result) {
              setState(() {
                applyDelta(_directory, result);
                applyEffectToSelection(_selected, widget.effect, result);
              });
            }
          : null,
      headerBuilder: widget.deep || widget.childBulk
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

  Widget _watchlistTile() {
    return SubPickerTile<Person>(
      title: 'Watchlist',
      icon: Icons.visibility_outlined,
      config: peopleConfig(title: 'Watchlist'),
      initialSelectedIds: _watchlist.toList(),
      onChange: widget.childPersist == Persist.change
          ? (delta) => setState(() => applyDelta(_watchlist, delta))
          : null,
      onClose: widget.childPersist == Persist.close
          ? (result) {
              setState(() => applyDelta(_watchlist, result));
            }
          : null,
    );
  }

  Widget _favoritesTile() {
    return SubPickerTile<Person>(
      title: 'Favorites',
      icon: Icons.star_outline,
      config: peopleConfig(title: 'Favorites'),
      initialSelectedIds: _favorites.toList(),
      onChange: (delta) => setState(() => applyDelta(_favorites, delta)),
    );
  }

  PickerConfig<Person> _childConfig(
    String title,
    GenericPickerController<Person, int> parent,
  ) {
    final gateUnselect = widget.childUnselect != PickerUnselectPolicy.allow;
    if (!gateUnselect && !widget.childLockedInactive) {
      return peopleConfig(title: title);
    }
    return peopleConfig(
      title: title,
      relatedListItemStatusOf: (person) {
        final usedByField = parent.pendingIds.contains(person.id);
        return PickerRelatedListItemStatus(
          selectable: !(widget.childLockedInactive && person.locked),
          unselectPolicy: person.inUse || usedByField
              ? widget.childUnselect
              : PickerUnselectPolicy.allow,
        );
      },
      relatedListItemStatusListenable: gateUnselect
          ? parent.pendingIdsListenable
          : null,
    );
  }
}
