import 'package:flutter/material.dart';
import 'package:search_anchor_picker/search_anchor_picker.dart';

import 'nested_card.dart';
import 'people.dart';
import 'simple_card.dart';

List<Widget> galleryCards() => [
  const SimpleCard(
    title: 'Close save, multi',
    persistLabel: 'onClose',
    difference:
        'Baseline. Field chips change only after the popup closes. Toggles inside the popup are not written yet.',
    source: r'''
SearchAnchorPicker<Person>(
  config: peopleConfig(title: 'Close save, multi'),
  initialSelectedIds: selected.toList(),
  onClose: (result) {
    selected
      ..clear()
      ..addAll(result.finalIds);
  },
);
''',
    seed: {1, 3},
  ),
  const SimpleCard(
    title: 'Change save, multi',
    persistLabel: 'onChange',
    difference:
        'Each accepted toggle writes immediately. Field chips update while the popup is still open.',
    source: r'''
SearchAnchorPicker<Person>(
  config: peopleConfig(title: 'Change save, multi'),
  initialSelectedIds: selected.toList(),
  onChange: (delta) {
    selected
      ..addAll(delta.added)
      ..removeAll(delta.removed);
  },
);
''',
    seed: {1, 3},
    persist: Persist.change,
  ),
  const SimpleCard(
    title: 'Inactive rows',
    persistLabel: 'onClose',
    difference:
        'Alan is locked, so his row is greyed out and cannot be tapped. A rule known up front reads as an inactive row instead of a checkbox that moves and springs back.',
    source: r'''
SearchAnchorPicker<Person>(
  config: peopleConfig(
    title: 'Inactive rows',
    relatedListItemStatusOf: (person) =>
        PickerRelatedListItemStatus(selectable: !person.locked),
  ),
  initialSelectedIds: selected.toList(),
  onClose: (result) {
    selected
      ..clear()
      ..addAll(result.finalIds);
  },
);
''',
    seed: {1, 2, 3},
    related: RelatedStatus.lockedInactive,
  ),
  const SimpleCard(
    title: 'Close save can fail',
    persistLabel: 'onClose throw',
    difference:
        'Turn on “Fail close”. The popup stays open, shows saving, then asks to update selection or close without saving.',
    source: r'''
SearchAnchorPicker<Person>(
  config: peopleConfig(title: 'Close save can fail'),
  initialSelectedIds: selected.toList(),
  onClose: (result) async {
    await Future<void>.delayed(const Duration(milliseconds: 700));
    if (failClose) throw StateError('simulated onClose failure');
    selected
      ..clear()
      ..addAll(result.finalIds);
  },
);
''',
    seed: {1},
    failClose: true,
    saveDelay: Duration(milliseconds: 700),
  ),
  const SimpleCard(
    title: 'Change save can fail',
    persistLabel: 'onChange throw',
    difference:
        'Turn on “Fail toggle”. The checkbox moves, then restores when onChange throws.',
    source: r'''
SearchAnchorPicker<Person>(
  config: peopleConfig(title: 'Change save can fail'),
  initialSelectedIds: selected.toList(),
  onChange: (delta) {
    if (failToggle) throw StateError('simulated onChange failure');
    selected
      ..addAll(delta.added)
      ..removeAll(delta.removed);
  },
);
''',
    seed: {1, 3},
    persist: Persist.change,
    failChange: true,
  ),
  const SimpleCard(
    title: 'Single required',
    persistLabel: 'onClose',
    difference:
        'At most one chip. Tapping another person replaces the selection. The selected row cannot be cleared.',
    source: r'''
SearchAnchorPicker<Person>(
  config: peopleConfig(title: 'Single required'),
  initialSelectedIds: selected.toList(),
  selectionMode: SelectionMode.single,
  onClose: (result) {
    selected
      ..clear()
      ..addAll(result.finalIds);
  },
);
''',
    seed: {4},
    mode: SelectionMode.single,
  ),
  const SimpleCard(
    title: 'Single optional',
    persistLabel: 'onClose',
    difference:
        'At most one chip. Tapping the selected row clears it. Different from Single required.',
    source: r'''
SearchAnchorPicker<Person>(
  config: peopleConfig(title: 'Single optional'),
  initialSelectedIds: selected.toList(),
  selectionMode: SelectionMode.singleOptional,
  onClose: (result) {
    selected
      ..clear()
      ..addAll(result.finalIds);
  },
);
''',
    seed: {4},
    mode: SelectionMode.singleOptional,
  ),
  const SimpleCard(
    title: 'Selected first',
    persistLabel: 'onClose',
    difference:
        'Default list order. Selected rows stay at the top, frozen when the popup opens.',
    source: r'''
SearchAnchorPicker<Person>(
  config: peopleConfig(title: 'Selected first', selectedFirst: true),
  initialSelectedIds: selected.toList(),
  onClose: (result) {
    selected
      ..clear()
      ..addAll(result.finalIds);
  },
);
''',
    seed: {8, 12},
  ),
  const SimpleCard(
    title: 'Catalog order',
    persistLabel: 'onClose',
    difference:
        'selectedFirst is false. Toggles do not move rows. Compare with Selected first.',
    source: r'''
SearchAnchorPicker<Person>(
  config: peopleConfig(title: 'Catalog order', selectedFirst: false),
  initialSelectedIds: selected.toList(),
  selectedFirst: false,
  onClose: (result) {
    selected
      ..clear()
      ..addAll(result.finalIds);
  },
);
''',
    seed: {8, 12},
    selectedFirst: false,
  ),
  const NestedCard(
    title: 'Nested directory, independent',
    persistLabel: 'onClose (both)',
    difference:
        'A SubPickerTile manages directory membership. Parent checkboxes do not follow directory add/remove.',
    source: r'''
SearchAnchorPicker<Person>(
  config: peopleConfig(title: 'People'),
  initialSelectedIds: selected.toList(),
  onClose: (result) { /* write selected */ },
  headerBuilder: (context, controller, items) => [
    SubPickerTile<Person>(
      title: 'Directory membership',
      config: directoryConfig,
      initialSelectedIds: directory.toList(),
      onClose: (result) { /* write directory */ },
    ),
  ],
);
''',
    effect: SubPickerParentSelectionEffect.none,
    childPersist: Persist.close,
  ),
  const NestedCard(
    title: 'Nested: check added',
    persistLabel: 'child onChange, parent onClose',
    difference:
        'selectAdded. Adding someone to the directory also checks them in the open parent. Field chips still wait for parent close.',
    source: r'''
SubPickerTile<Person>(
  title: 'Directory membership',
  config: directoryConfig,
  initialSelectedIds: directory.toList(),
  parentController: controller,
  parentSelectionEffect: SubPickerParentSelectionEffect.selectAdded,
  onChange: (delta) { /* write directory */ },
);
''',
    effect: SubPickerParentSelectionEffect.selectAdded,
  ),
  const NestedCard(
    title: 'Nested: uncheck removed',
    persistLabel: 'child onChange, parent onClose',
    difference:
        'deselectRemoved. Removing someone from the directory unchecks them in the open parent. Field chips still wait for parent close.',
    source: r'''
SubPickerTile<Person>(
  title: 'Directory membership',
  config: directoryConfig,
  initialSelectedIds: directory.toList(),
  parentController: controller,
  parentSelectionEffect: SubPickerParentSelectionEffect.deselectRemoved,
  onChange: (delta) { /* write directory */ },
);
''',
    effect: SubPickerParentSelectionEffect.deselectRemoved,
  ),
  const NestedCard(
    title: 'Nested: mirror both',
    persistLabel: 'child onChange, parent onClose',
    difference:
        'mirror. Parent checkboxes follow both sides of the directory delta. Field chips still wait for parent close.',
    source: r'''
SubPickerTile<Person>(
  title: 'Directory membership',
  config: directoryConfig,
  initialSelectedIds: directory.toList(),
  parentController: controller,
  parentSelectionEffect: SubPickerParentSelectionEffect.mirror,
  onChange: (delta) { /* write directory */ },
);
''',
    effect: SubPickerParentSelectionEffect.mirror,
  ),
  const NestedCard(
    title: 'Two sublists',
    persistLabel: 'onClose parent, onChange children',
    difference:
        'Directory and Watchlist are two independent SubPickerTiles. Neither changes parent checkboxes.',
    source: r'''
headerBuilder: (context, controller, items) => [
  SubPickerTile<Person>(
    title: 'Directory membership',
    config: directoryConfig,
    initialSelectedIds: directory.toList(),
    onChange: (delta) { /* write directory */ },
  ),
  SubPickerTile<Person>(
    title: 'Watchlist',
    config: watchlistConfig,
    initialSelectedIds: watchlist.toList(),
    onChange: (delta) { /* write watchlist */ },
  ),
],
''',
    secondSublist: true,
  ),
  const NestedCard(
    title: 'Sublist plus related-list icons',
    persistLabel: 'child onChange, parent onClose',
    difference:
        'Parent rows show directory membership icons. The nested directory still does not move parent checkboxes unless you set an effect.',
    source: r'''
SearchAnchorPicker<Person>(
  config: peopleConfig(
    relatedListItemStatusOf: (person) => PickerRelatedListItemStatus(
      auxiliaryMembership: directory.contains(person.id)
          ? PickerAuxiliaryMembership.member
          : PickerAuxiliaryMembership.notMember,
    ),
  ),
  headerBuilder: (context, controller, items) => [
    SubPickerTile<Person>(
      title: 'Directory membership',
      config: directoryConfig,
      initialSelectedIds: directory.toList(),
      onChange: (delta) { /* write directory */ },
    ),
  ],
);
''',
    relatedOnParent: true,
  ),
  const NestedCard(
    title: 'Nested child is single optional',
    persistLabel: 'child onChange, parent onClose',
    difference:
        'The directory sublist allows at most one member. Tapping that row clears it. The parent stays multi-select.',
    source: r'''
SubPickerTile<Person>(
  title: 'Directory membership',
  config: directoryConfig,
  initialSelectedIds: directory.toList(),
  selectionMode: SelectionMode.singleOptional,
  onChange: (delta) { /* write directory */ },
);
''',
    childMode: SelectionMode.singleOptional,
  ),
  const NestedCard(
    title: 'Nested child blocks in-use',
    persistLabel: 'child onChange, parent onClose',
    difference:
        'Alan and Margaret cannot be removed from the directory. The in-use policy runs in the child, not the parent.',
    source: r'''
SubPickerTile<Person>(
  title: 'Directory membership',
  config: peopleConfig(
    relatedListItemStatusOf: (person) => PickerRelatedListItemStatus(
      unselectPolicy: person.inUse
          ? PickerUnselectPolicy.blocked
          : PickerUnselectPolicy.allow,
    ),
  ),
  initialSelectedIds: directory.toList(),
  onChange: (delta) { /* write directory */ },
);
''',
    childUnselect: PickerUnselectPolicy.blocked,
  ),
  const NestedCard(
    title: 'Nested child confirms unselect',
    persistLabel: 'child onChange, parent onClose',
    difference:
        'Removing an in-use directory member asks for confirmation. Cancel leaves the child checkbox selected.',
    source: r'''
SubPickerTile<Person>(
  title: 'Directory membership',
  config: peopleConfig(
    relatedListItemStatusOf: (person) => PickerRelatedListItemStatus(
      unselectPolicy: person.inUse
          ? PickerUnselectPolicy.confirm
          : PickerUnselectPolicy.allow,
    ),
  ),
  initialSelectedIds: directory.toList(),
  onChange: (delta) { /* write directory */ },
);
''',
    childUnselect: PickerUnselectPolicy.confirm,
  ),
  const NestedCard(
    title: 'Nested child bulk commands',
    persistLabel: 'child onChange, parent onClose',
    difference:
        'The directory sublist has Select results / Clear results. Each command is one delta that the child saves immediately, and it does not parent-sync unless an effect is set.',
    source: r'''
SubPickerTile<Person>(
  title: 'Directory membership',
  config: directoryConfig,
  initialSelectedIds: directory.toList(),
  onChange: (delta) { /* write the whole delta once */ },
  headerBuilder: (context, controller, items) => [
    TextButton(
      onPressed: controller.selectFiltered,
      child: const Text('Select results'),
    ),
    TextButton(
      onPressed: controller.clearFiltered,
      child: const Text('Clear results'),
    ),
  ],
);
''',
    childBulk: true,
  ),
  const NestedCard(
    title: 'Nested child with inactive rows',
    persistLabel: 'child onChange, parent onClose',
    difference:
        'Locked people (Alan) are inactive inside the directory sublist only. The parent list still allows them.',
    source: r'''
SubPickerTile<Person>(
  title: 'Directory membership',
  config: peopleConfig(
    title: 'Directory',
    relatedListItemStatusOf: (person) =>
        PickerRelatedListItemStatus(selectable: !person.locked),
  ),
  initialSelectedIds: directory.toList(),
  onChange: (delta) { /* write directory */ },
);
''',
    childLockedInactive: true,
  ),
  const NestedCard(
    title: 'Nested directory inside directory',
    persistLabel: 'child onChange, grandchild onChange',
    difference:
        'Favorites is a SubPickerTile inside Directory. Three membership lists: people, directory, favorites.',
    source: r'''
SubPickerTile<Person>(
  title: 'Directory membership',
  config: directoryConfig,
  initialSelectedIds: directory.toList(),
  onChange: (delta) { /* write directory */ },
  headerBuilder: (context, directoryController, items) => [
    SubPickerTile<Person>(
      title: 'Favorites',
      config: favoritesConfig,
      initialSelectedIds: favorites.toList(),
      onChange: (delta) { /* write favorites */ },
    ),
  ],
);
''',
    deep: true,
  ),
  const NestedCard(
    title: 'Parent change, nested independent',
    persistLabel: 'parent onChange, child onChange',
    difference:
        'Parent field chips update on each parent toggle. Directory writes live too. No checkbox coupling.',
    source: r'''
SearchAnchorPicker<Person>(
  config: peopleConfig(title: 'People'),
  initialSelectedIds: selected.toList(),
  onChange: (delta) { /* write selected */ },
  headerBuilder: (context, controller, items) => [
    SubPickerTile<Person>(
      title: 'Directory membership',
      config: directoryConfig,
      initialSelectedIds: directory.toList(),
      onChange: (delta) { /* write directory */ },
    ),
  ],
);
''',
    parentPersist: Persist.change,
  ),
  const NestedCard(
    title: 'Mirror plus parent onChange',
    persistLabel: 'parent onChange, child onChange',
    difference:
        'Directory deltas mirror into open parent checkboxes. Parent row toggles also write the field immediately. Mirror still does not create a parent onChange delta.',
    source: r'''
SearchAnchorPicker<Person>(
  onChange: (delta) { /* parent row/bulk only */ },
  headerBuilder: (context, controller, items) => [
    SubPickerTile<Person>(
      parentController: controller,
      parentSelectionEffect: SubPickerParentSelectionEffect.mirror,
      onChange: (delta) { /* write directory */ },
      // title, config, initialSelectedIds...
    ),
  ],
);
''',
    effect: SubPickerParentSelectionEffect.mirror,
    parentPersist: Persist.change,
  ),
  const SimpleCard(
    title: 'Related-list icons',
    persistLabel: 'onClose',
    difference:
        'Rows show member / notMember from a fully known directory. That icon is not the parent checkbox.',
    source: r'''
PickerConfig<Person>(
  relatedListItemStatusOf: (person) => PickerRelatedListItemStatus(
    auxiliaryMembership: directory.contains(person.id)
        ? PickerAuxiliaryMembership.member
        : PickerAuxiliaryMembership.notMember,
  ),
  // loadItems, idOf, labelOf, searchTermsOf...
);
''',
    seed: {1, 4},
    related: RelatedStatus.knownDirectory,
  ),
  const SimpleCard(
    title: 'Related-list unknown',
    persistLabel: 'onClose',
    difference:
        'Directory page is partial. Absence is unknown, not notMember. Unselect is still allowed.',
    source: r'''
PickerConfig<Person>(
  relatedListItemStatusOf: (person) => PickerRelatedListItemStatus(
    auxiliaryMembership: pagedDirectory.contains(person.id)
        ? PickerAuxiliaryMembership.member
        : PickerAuxiliaryMembership.unknown,
  ),
);
''',
    seed: {1, 4},
    related: RelatedStatus.pagedDirectory,
  ),
  const SimpleCard(
    title: 'In-use blocked',
    persistLabel: 'onClose',
    difference:
        'Alan and Margaret are in use. Unselect is blocked and shows the in-use warning. Different from a rejected gate: the policy runs first.',
    source: r'''
PickerConfig<Person>(
  relatedListItemStatusOf: (person) => PickerRelatedListItemStatus(
    unselectPolicy: person.inUse
        ? PickerUnselectPolicy.blocked
        : PickerUnselectPolicy.allow,
  ),
);
''',
    seed: {1, 2, 5},
    related: RelatedStatus.blockedInUse,
  ),
  const SimpleCard(
    title: 'In-use confirm',
    persistLabel: 'onClose',
    difference:
        'Unchecking a directory member asks for confirmation. Cancel leaves the checkbox selected.',
    source: r'''
PickerConfig<Person>(
  relatedListItemStatusOf: (person) => PickerRelatedListItemStatus(
    unselectPolicy: directory.contains(person.id)
        ? PickerUnselectPolicy.confirm
        : PickerUnselectPolicy.allow,
  ),
);
''',
    seed: {1, 2, 5},
    related: RelatedStatus.confirmMember,
  ),
  SimpleCard(
    title: 'Hidden selected ID',
    persistLabel: 'onClose',
    difference:
        'loadItems returns only the first four people. Radia stays selected even though she is not on the loaded page.',
    source: r'''
PickerConfig<Person>(
  loadItems: (_) async => people.take(4).toList(),
  idOf: (person) => person.id,
  labelOf: (person) => person.name,
  searchTermsOf: (person) => [person.name],
);
''',
    seed: const {1, 12},
    loadItems: (_) async => people.take(4).toList(),
  ),
  const SimpleCard(
    title: 'Bulk header commands',
    persistLabel: 'onChange',
    difference:
        'Select results / Clear results take the same path as a row toggle and arrive as one delta over the loaded results. Save that delta as one write; a save that loops the ids would send one request per person. onClose avoids the question, since the session collapses into one net delta.',
    source: r'''
SearchAnchorPicker<Person>(
  onChange: (delta) async {
    // One write for the whole delta, not one per id.
    await api.updateMembers(added: delta.added, removed: delta.removed);
  },
  headerBuilder: (context, controller, items) => [
    TextButton(
      onPressed: controller.selectFiltered,
      child: const Text('Select results'),
    ),
    TextButton(
      onPressed: controller.clearFiltered,
      child: const Text('Clear results'),
    ),
  ],
);
''',
    seed: {1},
    persist: Persist.change,
    bulkHeader: true,
  ),
  const SimpleCard(
    title: 'Custom saving wrap',
    persistLabel: 'onClose (slow)',
    difference:
        'A slow onClose uses closeSavingBuilder instead of the default Saving… overlay.',
    source: r'''
SearchAnchorPicker<Person>(
  onClose: (result) async {
    await Future<void>.delayed(const Duration(milliseconds: 1200));
    // write selected
  },
  closeSavingBuilder: (context, child) => Stack(
    children: [
      child,
      const Align(
        alignment: Alignment.topCenter,
        child: Material(
          child: Text('Writing members…'),
        ),
      ),
    ],
  ),
);
''',
    seed: {1, 6},
    saveDelay: Duration(milliseconds: 1200),
    customSaving: true,
  ),
  const SimpleCard(
    title: 'Custom save-failed prompt',
    persistLabel: 'onClose throw',
    difference:
        'closeSaveFailedBuilder replaces the default dialog. This one always keeps the popup open.',
    source: r'''
SearchAnchorPicker<Person>(
  onClose: (result) {
    throw StateError('simulated onClose failure');
  },
  closeSaveFailedBuilder: (context, error, stackTrace) async {
    await showDialog<void>(/* custom dialog */);
    return CloseSaveFailedAction.updateSelection;
  },
);
''',
    seed: {1},
    failClose: true,
    customFail: true,
    saveDelay: Duration(milliseconds: 400),
  ),
  const SimpleCard(
    title: 'Full-screen popup',
    persistLabel: 'onClose',
    difference:
        'isFullScreen is true even on desktop. Close with the back control, not by tapping outside.',
    source: r'''
SearchAnchorPicker<Person>(
  config: peopleConfig(title: 'Full-screen popup'),
  initialSelectedIds: selected.toList(),
  isFullScreen: true,
  onClose: (result) { /* write selected */ },
);
''',
    seed: {3},
    fullScreen: true,
  ),
  const SimpleCard(
    title: 'Anchored popup',
    persistLabel: 'onClose',
    difference:
        'isFullScreen is false. The menu is anchored to + add. Tap outside to dismiss.',
    source: r'''
SearchAnchorPicker<Person>(
  config: peopleConfig(title: 'Anchored popup'),
  initialSelectedIds: selected.toList(),
  isFullScreen: false,
  viewConstraints: const BoxConstraints(
    minWidth: 320,
    maxWidth: 400,
    minHeight: 280,
    maxHeight: 480,
  ),
  onClose: (result) { /* write selected */ },
);
''',
    seed: {3},
    fullScreen: false,
  ),
  const SimpleCard(
    title: 'Custom empty copy',
    persistLabel: 'onClose',
    difference:
        'emptyText / noResultsText replace the localized defaults. Search for zzz to see no-results.',
    source: r'''
SearchAnchorPicker<Person>(
  emptyText: 'Nobody in this roster yet',
  noResultsText: 'No person matches that query',
  onClose: (result) { /* write selected */ },
);
''',
    emptyText: 'Nobody in this roster yet',
    noResultsText: 'No person matches that query',
  ),
  const SimpleCard(
    title: 'Inactive rows plus onChange',
    persistLabel: 'selectable + onChange',
    difference:
        'Locked people stay inactive and are skipped by bulk commands. Every other toggle saves immediately.',
    source: r'''
SearchAnchorPicker<Person>(
  config: peopleConfig(
    relatedListItemStatusOf: (person) =>
        PickerRelatedListItemStatus(selectable: !person.locked),
  ),
  onChange: (delta) { /* write selected */ },
);
''',
    seed: {1, 3},
    persist: Persist.change,
    related: RelatedStatus.lockedInactive,
  ),
  const SimpleCard(
    title: 'Multiline field',
    persistLabel: 'onClose',
    difference:
        'Same close-save behaviour as the baseline, but the field starts with many chips and grows past one line.',
    source: r'''
SearchAnchorPicker<Person>(
  initialSelectedIds: const [1, 3, 4, 6, 7, 8, 9, 10, 11, 12],
  onClose: (result) { /* write selected */ },
);
''',
    seed: {1, 3, 4, 6, 7, 8, 9, 10, 11, 12},
  ),
  const NestedCard(
    title: 'Parent close, child change',
    persistLabel: 'parent onClose, child onChange',
    difference:
        'Directory membership writes on each child toggle. Parent field chips wait until the parent popup closes. No parent checkbox coupling.',
    source: r'''
SearchAnchorPicker<Person>(
  onClose: (result) { /* write selected */ },
  headerBuilder: (context, controller, items) => [
    SubPickerTile<Person>(
      title: 'Directory membership',
      config: directoryConfig,
      initialSelectedIds: directory.toList(),
      onChange: (delta) { /* write directory */ },
    ),
  ],
);
''',
  ),
];
