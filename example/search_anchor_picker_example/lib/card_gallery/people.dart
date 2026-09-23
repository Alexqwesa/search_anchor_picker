import 'package:flutter/material.dart';
import 'package:search_anchor_picker/search_anchor_picker.dart';

class Person {
  const Person({
    required this.id,
    required this.name,
    required this.team,
    this.locked = false,
    this.inUse = false,
  });

  final int id;
  final String name;
  final String team;
  final bool locked;
  final bool inUse;
}

const people = <Person>[
  Person(id: 1, name: 'Ada Lovelace', team: 'Math'),
  Person(id: 2, name: 'Alan Turing', team: 'Crypto', locked: true, inUse: true),
  Person(id: 3, name: 'Grace Hopper', team: 'Cobol'),
  Person(id: 4, name: 'Katherine Johnson', team: 'NASA'),
  Person(id: 5, name: 'Margaret Hamilton', team: 'Apollo', inUse: true),
  Person(id: 6, name: 'Donald Knuth', team: 'Art'),
  Person(id: 7, name: 'Barbara Liskov', team: 'MIT'),
  Person(id: 8, name: 'Linus Torvalds', team: 'Kernel'),
  Person(id: 9, name: 'Guido van Rossum', team: 'Python'),
  Person(id: 10, name: 'Bjarne Stroustrup', team: 'C++'),
  Person(id: 11, name: 'Anders Hejlsberg', team: 'C#'),
  Person(id: 12, name: 'Radia Perlman', team: 'Networking'),
];

const knownDirectoryIds = {1, 2, 5};
const pagedDirectoryIds = {1, 5};
const knownWatchlistIds = {3, 8};

const knownTeamIds = {4, 6};

/// Disjoint 3–7 row catalogs so nested sublists do not share people.
const directoryCatalogIds = {1, 2, 5, 7, 9};
const watchlistCatalogIds = {3, 8, 10, 11};
const teamCatalogIds = {4, 6, 12};
const favoritesCatalogIds = {1, 7, 9};

/// Short parent catalog (Ada … Margaret). Nested demos keep 3–7 main rows.
const shortMainIds = {1, 2, 3, 4, 5};

List<Person> peopleIn(Set<int> ids) =>
    people.where((person) => ids.contains(person.id)).toList();

/// Short parent catalog used by field/sublist demos (Ada … Knuth).
const mainCatalogIds = {1, 2, 3, 4, 5, 6};

List<Person> mainCatalogPeople() =>
    people.where((person) => mainCatalogIds.contains(person.id)).toList();

const popupConstraints = BoxConstraints(
  minWidth: 320,
  maxWidth: 400,
  minHeight: 280,
  maxHeight: 480,
);

const widePopupConstraints = BoxConstraints(
  minWidth: 560,
  maxWidth: 640,
  minHeight: 320,
  maxHeight: 520,
);

enum Persist { close, change }

String personName(int id) {
  for (final person in people) {
    if (person.id == id) return person.name;
  }
  return '#$id';
}

String namesOf(Set<int> ids) {
  if (ids.isEmpty) return 'empty';
  return (ids.toList()..sort()).map(personName).join(', ');
}

/// Footer like **Directory:** Ada, Alan · **Watchlist:** Grace.
Widget namedSetFooter(
  BuildContext context,
  List<(String, Set<int>)> parts,
) {
  final style = Theme.of(context).textTheme.bodySmall;
  final labelStyle = style?.copyWith(fontWeight: FontWeight.bold);
  return Text.rich(
    TextSpan(
      style: style,
      children: [
        for (var i = 0; i < parts.length; i++) ...[
          if (i > 0) const TextSpan(text: ' · '),
          TextSpan(text: '${parts[i].$1}: ', style: labelStyle),
          TextSpan(text: namesOf(parts[i].$2)),
        ],
      ],
    ),
  );
}

void applyDelta(Set<int> ids, PickerDelta<int> delta) {
  ids
    ..addAll(delta.added)
    ..removeAll(delta.removed);
}

/// Persist only explicit child-session adds onto the parent field.
///
/// An empty close does not write. Directory membership is not a selection.
void persistExplicitChildAdds(
  Set<int> selected,
  PickerDelta<int> delta, {
  void Function(Iterable<int> added)? syncParent,
}) {
  if (delta.added.isEmpty) return;
  selected.addAll(delta.added);
  syncParent?.call(delta.added);
}

/// Writes field chips for a nested parent-selection effect.
///
/// `syncPending` only moves parent checkboxes. It does not create a parent
/// `onChange` / `onClose` delta, so the app must persist the field itself.
void applyEffectToSelection(
  Set<int> selected,
  SubPickerParentSelectionEffect effect,
  PickerDelta<int> delta,
) {
  switch (effect) {
    case SubPickerParentSelectionEffect.none:
      break;
    case SubPickerParentSelectionEffect.selectAdded:
      selected.addAll(delta.added);
    case SubPickerParentSelectionEffect.deselectRemoved:
      selected.removeAll(delta.removed);
    case SubPickerParentSelectionEffect.mirror:
      applyDelta(selected, delta);
  }
}

PickerConfig<Person> peopleConfig({
  String? title,
  LoadItems<Person>? loadItems,
  PickerRelatedListItemStatus Function(Person)? relatedListItemStatusOf,
  Listenable? relatedListItemStatusListenable,
  Listenable? listenable,
  bool selectedFirst = true,
  Object? reloadKey,
}) {
  return PickerConfig<Person>(
    title: title,
    loadItems: loadItems ?? (_, _) async => people,
    idOf: (person) => person.id,
    labelOf: (person) => person.name,
    searchTermsOf: (person) => [person.name, person.team, '${person.id}'],
    comparator: (a, b) => a.name.compareTo(b.name),
    selectedFirst: selectedFirst,
    relatedListItemStatusOf: relatedListItemStatusOf,
    relatedListItemStatusListenable: relatedListItemStatusListenable,
    listenable: listenable,
    reloadKey: reloadKey,
  );
}

Widget peopleFieldTrigger(
  VoidCallback open,
  Set<int> selected, {
  required ValueChanged<int> onDeleted,
  SelectionMode selectionMode = SelectionMode.multi,
  bool showChips = true,
}) {
  return DefaultPickerFieldTrigger<int>(
    selectedIds: selected,
    labelOf: personName,
    onOpen: open,
    onDeleted: onDeleted,
    selectionMode: selectionMode,
    showChips: showChips,
  );
}
