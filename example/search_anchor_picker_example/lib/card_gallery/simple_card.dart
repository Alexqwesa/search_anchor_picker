import 'dart:async';

import 'package:flutter/material.dart';
import 'package:search_anchor_picker/search_anchor_picker.dart';

import 'example_card.dart';
import 'people.dart';

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
    this.customFail = false,
    this.customSaving = false,
    this.bulkHeader = false,
    this.saveDelay,
    this.loadItems,
    this.related = RelatedStatus.none,
    this.emptyText,
    this.noResultsText,
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
  final bool customFail;
  final bool customSaving;
  final bool bulkHeader;
  final Duration? saveDelay;
  final Future<List<Person>> Function(BuildContext context)? loadItems;
  final RelatedStatus related;
  final String? emptyText;
  final String? noResultsText;

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
          if (widget.failClose || widget.failChange)
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
                  Text(widget.failChange ? 'Fail toggle' : 'Fail close'),
                ],
              ),
            ),
          ChipField(
            ids: _selected,
            onDeleted: (id) => setState(() => _selected.remove(id)),
            addButton: SearchAnchorPicker<Person>(
              config: peopleConfig(
                title: widget.title,
                loadItems: widget.loadItems,
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
              viewConstraints: popupConstraints,
              onChange: widget.persist == Persist.change
                  ? (delta) async {
                      if (widget.failChange && _fail) {
                        throw StateError('simulated onChange failure');
                      }
                      setState(() => applyDelta(_selected, delta));
                    }
                  : null,
              onClose: widget.persist == Persist.close
                  ? (result) async {
                      final delay = widget.saveDelay;
                      if (delay != null) await Future<void>.delayed(delay);
                      if (widget.failClose && _fail) {
                        throw StateError('simulated onClose failure');
                      }
                      setState(() {
                        _selected
                          ..clear()
                          ..addAll(result.finalIds);
                      });
                    }
                  : null,
              closeSavingBuilder: widget.customSaving
                  ? (context, child) => Stack(
                      children: [
                        child,
                        Align(
                          alignment: Alignment.topCenter,
                          child: Material(
                            color: Colors.amber.shade200,
                            child: const Padding(
                              padding: EdgeInsets.all(8),
                              child: Text('Writing members…'),
                            ),
                          ),
                        ),
                      ],
                    )
                  : null,
              closeSaveFailedBuilder: widget.customFail
                  ? (context, error, stackTrace) async {
                      await showDialog<void>(
                        context: context,
                        builder: (context) => AlertDialog(
                          title: const Text('Could not write members'),
                          content: Text('$error'),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context),
                              child: const Text('Keep editing'),
                            ),
                          ],
                        ),
                      );
                      return CloseSaveFailedAction.updateSelection;
                    }
                  : null,
              headerBuilder: widget.bulkHeader
                  ? (context, controller, items) => [
                      TextButton(
                        onPressed: controller.selectFiltered,
                        child: const Text('Select results'),
                      ),
                      TextButton(
                        onPressed: controller.clearFiltered,
                        child: const Text('Clear results'),
                      ),
                    ]
                  : null,
              triggerBuilder: addTrigger,
            ),
          ),
        ],
      ),
    );
  }
}
