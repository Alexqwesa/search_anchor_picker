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

void applyDelta(Set<int> ids, PickerDelta<int> delta) {
  ids
    ..addAll(delta.added)
    ..removeAll(delta.removed);
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
  Future<List<Person>> Function(BuildContext context)? loadItems,
  PickerRelatedListItemStatus Function(Person)? relatedListItemStatusOf,
  Listenable? relatedListItemStatusListenable,
  bool selectedFirst = true,
}) {
  return PickerConfig<Person>(
    title: title,
    loadItems: loadItems ?? (_) async => people,
    idOf: (person) => person.id,
    labelOf: (person) => person.name,
    searchTermsOf: (person) => [person.name, person.team, '${person.id}'],
    comparator: (a, b) => a.name.compareTo(b.name),
    selectedFirst: selectedFirst,
    relatedListItemStatusOf: relatedListItemStatusOf,
    relatedListItemStatusListenable: relatedListItemStatusListenable,
  );
}

Widget addTrigger(BuildContext context, VoidCallback open, int version) {
  return TextButton(onPressed: open, child: const Text('+ add'));
}
