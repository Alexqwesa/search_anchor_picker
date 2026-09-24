import 'package:flutter/material.dart';
import 'package:search_anchor_picker/search_anchor_picker.dart';

import 'field_relation_card.dart';
import 'nested_card.dart';
import 'people.dart';
import 'server_search_card.dart';
import 'simple_card.dart';

class GallerySection {
  const GallerySection({
    required this.title,
    required this.caption,
    required this.cards,
  });

  final String title;
  final String caption;
  final List<Widget> cards;
}

List<GallerySection> gallerySections() => [
  GallerySection(
    title: 'Simple parameter variances',
    caption:
        'Persist timing, selection mode, list order, and per-row related-list flags. Behaviour is otherwise the baseline picker.',
    cards: [
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
      ..addAll(result.added)
      ..removeAll(result.removed);
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
      ..addAll(result.added)
      ..removeAll(result.removed);
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
      ..addAll(result.added)
      ..removeAll(result.removed);
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
      ..addAll(result.added)
      ..removeAll(result.removed);
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
      ..addAll(result.added)
      ..removeAll(result.removed);
  },
);
''',
        seed: {8, 12},
        selectedFirst: false,
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
      ..addAll(result.added)
      ..removeAll(result.removed);
  },
);
''',
        seed: {1, 2, 3},
        related: RelatedStatus.lockedInactive,
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
        title: 'Related-list icons',
        persistLabel: 'onClose',
        difference:
            'DefaultPickerItemTile uses title (name) and subtitle (team). Rows also show member / notMember from a fully known directory. That icon is not the parent checkbox.',
        source: r'''
itemBuilder: (context, person, selected, status, source, toggle) {
  return DefaultPickerItemTile(
    selected: selected,
    relatedListItemStatus: status,
    onToggle: (_) => toggle(),
    title: Text(person.name),
    subtitle: Text(person.team),
    selectionMode: SelectionMode.multi,
  );
}
''',
        seed: {1, 4},
        related: RelatedStatus.knownDirectory,
        richItemTile: true,
      ),
      const SimpleCard(
        title: 'In-use confirm',
        persistLabel: 'onClose',
        difference:
            'Unchecking a directory member in the list or from a field chip asks for confirmation. Cancel leaves them selected. Katherine is not in the directory and can leave without a prompt.',
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
    ],
  ),
  GallerySection(
    title: 'Bulk operations',
    caption:
        'Header buttons call selectFiltered / clearFiltered (current search hits) or selectLoaded / clearLoaded (the whole loaded page). Each command is one PickerDelta. Inactive rows are skipped. Persist it as one write; a loop over ids is what floods the API.',
    cards: [
      const SimpleCard(
        title: 'Bulk: select / clear search results',
        persistLabel: 'onChange',
        difference:
            'Select results / Clear results apply to the current search hits. With an empty query that is everyone loaded. Type a name to shrink the set, then Select results — one onChange delta, not one call per person. Field chips update immediately.',
        source: r'''
SearchAnchorPicker<Person>(
  onChange: (delta) async {
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
        bulk: BulkCommands.filtered,
      ),
      const SimpleCard(
        title: 'Bulk: select / clear all loaded(not just filtered)',
        persistLabel: 'onChange',
        difference:
            'Select loaded / Clear loaded ignore the search box and act on the whole itemsLoader page. Search for Linus, then Select loaded: Ada … Radia all check, not just Linus. One delta.',
        source: r'''
headerBuilder: (context, controller, items) => [
  TextButton(
    onPressed: controller.selectLoaded,
    child: const Text('Select loaded'),
  ),
  TextButton(
    onPressed: controller.clearLoaded,
    child: const Text('Clear loaded'),
  ),
],
''',
        seed: {1},
        persist: Persist.change,
        bulk: BulkCommands.loaded,
      ),
      const SimpleCard(
        title: 'Bulk + onClose',
        persistLabel: 'onClose',
        difference:
            'Wide popup with a 4-across header: Select / Clear results (current search hits) and Select / Clear loaded (the whole page). Those four are the bulk commands on the controller. Field chips wait until close; onClose is one net delta.',
        source: r'''
SearchAnchorPicker<Person>(
  viewConstraints: const BoxConstraints(
    minWidth: 560,
    maxWidth: 640,
    minHeight: 320,
    maxHeight: 520,
  ),
  onClose: (result) { /* one net write */ },
  headerBuilder: (context, controller, items) => [
    GridView.count(
      crossAxisCount: 4,
      shrinkWrap: true,
      children: [
        OutlinedButton(
          onPressed: controller.selectFiltered,
          child: const Text('Select results'),
        ),
        OutlinedButton(
          onPressed: controller.clearFiltered,
          child: const Text('Clear results'),
        ),
        OutlinedButton(
          onPressed: controller.selectLoaded,
          child: const Text('Select loaded'),
        ),
        OutlinedButton(
          onPressed: controller.clearLoaded,
          child: const Text('Clear loaded'),
        ),
      ],
    ),
  ],
);
''',
        seed: {1},
        wide: true,
        bulk: BulkCommands.all,
        viewConstraints: widePopupConstraints,
      ),
      const SimpleCard(
        title: 'Bulk skips inactive rows',
        persistLabel: 'onChange',
        difference:
            'Alan is locked. Select results / Select loaded skip him. He stays unchecked and grey. Bulk is not a way around selectable: false.',
        source: r'''
SearchAnchorPicker<Person>(
  config: peopleConfig(
    relatedListItemStatusOf: (person) =>
        PickerRelatedListItemStatus(selectable: !person.locked),
  ),
  onChange: (delta) { /* write selected */ },
  headerBuilder: (context, controller, items) => [
    TextButton(
      onPressed: controller.selectFiltered,
      child: const Text('Select results'),
    ),
    TextButton(
      onPressed: controller.selectLoaded,
      child: const Text('Select loaded'),
    ),
  ],
);
''',
        seed: {1, 3},
        persist: Persist.change,
        related: RelatedStatus.lockedInactive,
        bulk: BulkCommands.all,
      ),
      const NestedCard(
        title: 'Unrelated: child bulk commands',
        persistLabel: 'child onChange, parent onClose',
        difference:
            'Directory has Select results / Clear results. Each command is one delta that the child saves immediately. Sublists do not move parent checkboxes.',
        source: r'''
SubPickerTile<Person>(
  title: 'Directory',
  onChange: (delta, notifyParent) { /* write the whole delta once */ },
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
        sublists: 2,
      ),
    ],
  ),
  GallerySection(
    title: 'Styling',
    caption:
        'Popup chrome, field layout, empty copy, and the saving overlay. Selection behaviour is the baseline close-save unless the card says otherwise.',
    cards: [
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
      const NestedCard(
        title: 'Unrelated: anchored nested popups',
        persistLabel: 'onClose',
        difference:
            'isFullScreen is false, so the menu is anchored to the field. Directory and Watchlist sit in the header; the short main people list is below them. Open each sublist: they use different menuOffset and viewConstraints. Tap outside to dismiss.',
        source: r'''
SearchAnchorPicker<Person>(
  isFullScreen: false,
  viewConstraints: const BoxConstraints(
    minWidth: 360,
    maxWidth: 420,
    minHeight: 320,
    maxHeight: 480,
  ),
  headerBuilder: (context, controller, items) => [
    SubPickerTile<Person>(
      title: 'Directory membership',
      menuOffset: const Offset(24, 36),
      viewConstraints: const BoxConstraints(
        minWidth: 240,
        maxWidth: 280,
        minHeight: 200,
        maxHeight: 280,
      ),
    ),
    SubPickerTile<Person>(
      title: 'Watchlist',
      menuOffset: const Offset(56, 12),
      viewConstraints: const BoxConstraints(
        minWidth: 360,
        maxWidth: 440,
        minHeight: 300,
        maxHeight: 420,
      ),
    ),
  ],
);
''',
        sublists: 2,
        viewConstraints: BoxConstraints(
          minWidth: 360,
          maxWidth: 420,
          minHeight: 320,
          maxHeight: 480,
        ),
        directoryOffset: Offset(24, 36),
        directoryConstraints: BoxConstraints(
          minWidth: 240,
          maxWidth: 280,
          minHeight: 200,
          maxHeight: 280,
        ),
        watchlistOffset: Offset(56, 12),
        watchlistConstraints: BoxConstraints(
          minWidth: 360,
          maxWidth: 440,
          minHeight: 300,
          maxHeight: 420,
        ),
      ),
      const SimpleCard(
        title: 'Custom empty copy',
        persistLabel: 'onClose',
        difference:
            'emptyText / noResultsText replace the localized defaults. Open shows Custom: No items. Search for zzz to see Custom: No results.',
        source: r'''
SearchAnchorPicker<Person>(
  emptyText: 'Custom: No items',
  noResultsText: 'Custom: No results',
  onClose: (result) { /* write selected */ },
);
''',
        emptyText: 'Custom: No items',
        noResultsText: 'Custom: No results',
        emptyCatalog: true,
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
      const SimpleCard(
        title: 'Field without chips',
        persistLabel: 'onClose',
        difference:
            'DefaultPickerFieldTrigger with showChips: false. Tapping the outlined field or Add still opens the picker. Selected people are not shown on the field.',
        source: r'''
SearchAnchorPicker<Person>(
  triggerBuilder: (context, open, _) => DefaultPickerFieldTrigger<int>(
    selectedIds: selected,
    labelOf: (id) => names[id] ?? '#$id',
    onOpen: open,
    onDeleted: selected.remove,
    showChips: false,
  ),
  onClose: (result) { /* write selected */ },
);
''',
        seed: {1, 3},
        showChips: false,
      ),
      const SimpleCard(
        title: 'Custom saving wrap',
        persistLabel: 'onClose (slow)',
        difference:
            'A slow onClose uses closeSavingBuilder: dimmed popup, circular progress, and Writing members… instead of the default Saving… overlay.',
        source: r'''
SearchAnchorPicker<Person>(
  onClose: (result) async {
    await Future<void>.delayed(const Duration(milliseconds: 1200));
    // write selected
  },
  closeSavingBuilder: (context, child) => Stack(
    children: [
      IgnorePointer(child: child),
      const Positioned.fill(
        child: ColoredBox(color: Color(0x73000000)),
      ),
      const Center(
        child: Material(
          child: Padding(
            padding: EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 16),
                Text('Writing members…'),
              ],
            ),
          ),
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
    ],
  ),
  GallerySection(
    title: 'Nested list logic',
    caption:
        'Direct: the parent shows sublist members; uncheck in a sublist and they leave the parent unless parent-checked stays. Reverse: checking the parent makes people appear or become checkable in sublists. Unrelated: sublist membership is separate — the card subtitle, or a shared field of extra chips (not the main list, not a subtitle).',
    cards: [
      const SimpleCard(
        title: 'Selected stay in this open list',
        persistLabel: 'onClose',
        difference:
            'The field chips are the selection. The popup must keep showing those people so you can uncheck them, even when they are not in the searchable catalog.\n\n'
            'This catalog is Ada … Knuth. The field starts with Ada (in catalog), Linus, and Radia (outside it). Open: Linus and Radia are in the list because itemsLoader unions the current chips. Uncheck Radia: she stays in this open overlay — the loaded snapshot does not drop her mid-session. Close: her chip is gone. Open again: she is neither selected nor in the catalog, so she disappears. Linus still appears because he still has a chip.\n\n'
            'Compare with Hidden selected ID: without a cache that card used to keep Radia selected with no row. It now passes initialSelectedItemCache so she appears under Selected.',
        source: r'''
SearchAnchorPicker<Person>(
  config: peopleConfig(
    itemsLoader: (_, _) async {
      final catalog = people.where((p) => p.id <= 6).toList();
      final extra = people.where(
        (p) => selected.contains(p.id) && p.id > 6,
      );
      return [...extra, ...catalog];
    },
  ),
  initialSelectedIds: selected.toList(),
  onClose: (result) {
    selected
      ..addAll(result.added)
      ..removeAll(result.removed);
  },
);
''',
        seed: {1, 8, 12},
        includeSelectedInLoad: true,
      ),
      const NestedCard(
        title: 'Direct: sublist uncheck leaves the parent',
        persistLabel: 'child onChange, parent onClose',
        difference:
            'Direct logic. Each sublist is a different 3–7 person catalog (Directory Ada…Guido, Watchlist Grace…Anders, Team Katherine…Radia). The parent list is the union of their checked rows (about 7). Uncheck someone in a sublist: they uncheck on the parent, leave the list, and drop from the field chips.\n\n'
            'Try Alan in Directory, Linus in Watchlist, or Knuth in Team.',
        source: r'''
SearchAnchorPicker<Person>(
  config: peopleConfig(
    itemsLoader: (_, _) async =>
        people.where((p) => sublistUnion.contains(p.id)).toList(),
    reloadKey: {...sublistUnion},
  ),
  headerBuilder: (context, controller, items) => [
    SubPickerTile<Person>(
      title: 'Directory',
      parentController: controller,
      parentSelectionEffect: SubPickerParentSelectionEffect.mirror,
    ),
    SubPickerTile<Person>(title: 'Watchlist', /* same effect */),
    SubPickerTile<Person>(title: 'Team', /* same effect */),
  ],
);
''',
        relation: NestedRelation.direct,
        sublists: 3,
      ),
      const NestedCard(
        title: 'Direct: parent-checked stays',
        persistLabel: 'child onChange, parent onClose',
        difference:
            'Direct logic with a stay rule. Stay is whoever is currently checked on the parent, including in-session parent toggles — not a rebuild from field chips ∪ every sublist member.\n\n'
            'Uncheck Ada in Directory: she is parent-checked, so her parent checkbox and field chip stay. Uncheck Linus in Watchlist: he is only a sublist extra, so he leaves the parent list and is not added as a chip. Uncheck Ada on the parent first, then in Directory: she is no longer parent-checked and does not get checked again.',
        source: r'''
onChange: (delta) {
  final unionBefore = {...sublistUnion};
  final pendingNow = {...parent.pendingIds};
  writeSublist(delta);
  final stay = {
    for (final id in pendingNow)
      if (fieldSelected.contains(id) || !unionBefore.contains(id)) id,
  };
  parent.syncPending(
    added: delta.added,
    removed: delta.removed.where((id) => !stay.contains(id)),
  );
},
''',
        relation: NestedRelation.directStay,
        sublists: 3,
      ),
      const NestedCard(
        title: 'Reverse: parent check appears in sublists',
        persistLabel: 'parent onClose, child onChange',
        difference:
            'Reverse logic. The main list is Ada … Margaret (5). Each sublist only loads people from its own catalog who are currently checked on the parent.\n\n'
            'The field starts with Ada and Katherine: Directory opens with Ada, Team with Katherine, Watchlist is empty (neither is in that catalog). Check Grace on the parent: she appears in Watchlist only.',
        source: r'''
SubPickerTile<Person>(
  config: peopleConfig(
    itemsLoader: (_, _) async => people
        .where((p) =>
            catalog.contains(p.id) && parent.pendingIds.contains(p.id))
        .toList(),
    listenable: parent.pendingIdsListenable,
  ),
);
''',
        relation: NestedRelation.reverseAppear,
        sublists: 3,
      ),
      const NestedCard(
        title: 'Reverse: parent check unlocks sublists',
        persistLabel: 'parent onClose, child onChange',
        difference:
            'Reverse logic. Each sublist lists its own 3–7 people. A row is checkable only after that person is selected on the parent. Ada starts unlocked in Directory, Katherine in Team. Alan is grey in Directory until you check him on the parent. Grace is grey in Watchlist until you check her.',
        source: r'''
SubPickerTile<Person>(
  config: peopleConfig(
    relatedListItemStatusOf: (person) => PickerRelatedListItemStatus(
      selectable: parent.pendingIds.contains(person.id),
    ),
    relatedListItemStatusListenable: parent.pendingIdsListenable,
  ),
);
''',
        relation: NestedRelation.reverseAvailable,
        sublists: 3,
      ),
      const NestedCard(
        title: 'Unrelated: sublists in the card subtitle',
        persistLabel: 'parent onClose, child onChange',
        difference:
            'Unrelated logic. The short main list (Ada … Margaret) does not follow sublist checks. Directory, Watchlist, and Team are different 3–7 person catalogs; membership only updates the card subtitle. Field chips are the parent selection only.',
        source: r'''
headerBuilder: (context, controller, items) => [
  SubPickerTile<Person>(
    title: 'Directory',
    onChange: (delta, notifyParent) { writeDirectory(delta); },
  ),
  SubPickerTile<Person>(
    title: 'Watchlist',
    onChange: (delta, notifyParent) { writeWatchlist(delta); },
  ),
  SubPickerTile<Person>(
    title: 'Team',
    onChange: (delta, notifyParent) { writeTeam(delta); },
  ),
];
''',
        relation: NestedRelation.unrelated,
        sublists: 3,
      ),
      const NestedCard(
        title: 'Unrelated: shared field',
        persistLabel: 'child onChange, parent onClose',
        difference:
            'Unrelated logic, shared field. Directory, Watchlist, and Team are different 3–7 person catalogs. They do not change the main list (Ada … Margaret stays) and there is no Directory subtitle. Checking Linus in Watchlist only adds a field chip alongside Ada and Katherine. Uncheck him in Watchlist, or tap the chip X: both use the same sublist write, so the extra chip is gone. The parent popup still has no Linus row.',
        source: r'''
void writeSublist(Set<int> ids, PickerDelta<int> delta) {
  applyDelta(ids, delta); // same persist as the child onChange
}

SubPickerTile<Person>(
  onChange: (delta, notifyParent) => writeSublist(watchlist, delta),
);
// Chip X:
writeSublist(watchlist, PickerDelta(removed: {id}));
''',
        relation: NestedRelation.unrelatedField,
        sublists: 3,
      ),
      const FieldRelationCard(
        title: 'Unrelated: block unselect while on parent',
        persistLabel: 'parent onClose, child onChange',
        difference:
            'Unrelated membership, with a guard: Directory cannot drop someone who is still checked on the parent. Ada starts on the field, so her Directory unselect is blocked. Alan is directory-only and can leave.\n\n'
            'Watchlist and Team are independent and have no guard.',
        source: r'''
relatedListItemStatusOf: (person) => PickerRelatedListItemStatus(
  unselectPolicy: parent.pendingIds.contains(person.id)
      ? PickerUnselectPolicy.blocked
      : PickerUnselectPolicy.allow,
),
''',
        sublistUnselect: SublistFieldUnselect.blockIfOnField,
      ),
      const FieldRelationCard(
        title: 'Unrelated: confirm unselect while on parent',
        persistLabel: 'parent onClose, child onChange',
        difference:
            'Unrelated membership, with a confirm guard. Removing Ada from Directory asks first because she is on the field. Alan (directory only) unchecks with no dialog.',
        source: r'''
unselectPolicy: parent.pendingIds.contains(person.id)
    ? PickerUnselectPolicy.confirm
    : PickerUnselectPolicy.allow,
''',
        sublistUnselect: SublistFieldUnselect.confirmIfOnField,
      ),
    ],
  ),
  GallerySection(
    title: 'Nested picker structure',
    caption:
        'Unrelated nesting: sibling and nested SubPickerTiles, child selection modes, and which callback writes. Parent/sublist coupling lives in Nested list logic.',
    cards: [
      const NestedCard(
        title: 'Unrelated: nested directory',
        persistLabel: 'onClose (both)',
        difference:
            'A Directory and Watchlist SubPickerTile manage membership. Parent checkboxes do not follow sublist add/remove.',
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
        title: 'Unrelated: sibling sublists',
        persistLabel: 'onClose parent, onChange children',
        difference:
            'Directory, Watchlist, and Team are independent SubPickerTiles with different people. None of them changes parent checkboxes.',
        source: r'''
headerBuilder: (context, controller, items) => [
  SubPickerTile<Person>(
    title: 'Directory membership',
    config: directoryConfig,
    initialSelectedIds: directory.toList(),
    onChange: (delta, notifyParent) { /* write directory */ },
  ),
  SubPickerTile<Person>(
    title: 'Watchlist',
    config: watchlistConfig,
    initialSelectedIds: watchlist.toList(),
    onChange: (delta, notifyParent) { /* write watchlist */ },
  ),
],
''',
        sublists: 3,
      ),
      const NestedCard(
        title: 'Unrelated: nested sublist inside sublist',
        persistLabel: 'child onChange, grandchild onChange',
        difference:
            'Favorites is a SubPickerTile inside Directory. Membership lists: people, Directory, Watchlist, and Favorites.',
        source: r'''
SubPickerTile<Person>(
  title: 'Directory membership',
  config: directoryConfig,
  initialSelectedIds: directory.toList(),
  onChange: (delta, notifyParent) { /* write directory */ },
  headerBuilder: (context, directoryController, items) => [
    SubPickerTile<Person>(
      title: 'Favorites',
      config: favoritesConfig,
      initialSelectedIds: favorites.toList(),
      onChange: (delta, notifyParent) { /* write favorites */ },
    ),
  ],
);
''',
        deep: true,
      ),
      const NestedCard(
        title: 'Unrelated: child is single optional',
        persistLabel: 'child onChange, parent onClose',
        difference:
            'The directory sublist allows at most one member. Tapping that row clears it. The parent stays multi-select.',
        source: r'''
SubPickerTile<Person>(
  title: 'Directory membership',
  config: directoryConfig,
  initialSelectedIds: directory.toList(),
  selectionMode: SelectionMode.singleOptional,
  onChange: (delta, notifyParent) { /* write directory */ },
);
''',
        childMode: SelectionMode.singleOptional,
      ),
      const NestedCard(
        title: 'Unrelated: child blocks in-use',
        persistLabel: 'child onChange, parent onClose',
        difference:
            'Directory unselect is blocked when the person is in use: Alan and Margaret have the in-use flag, and Ada is on the field (both lists). Grace can still be added and removed. The policy runs in the child; the parent list stays tappable.',
        source: r'''
SubPickerTile<Person>(
  title: 'Directory membership',
  config: peopleConfig(
    relatedListItemStatusOf: (person) => PickerRelatedListItemStatus(
      unselectPolicy: person.inUse || parent.pendingIds.contains(person.id)
          ? PickerUnselectPolicy.blocked
          : PickerUnselectPolicy.allow,
    ),
    relatedListItemStatusListenable: parent.pendingIdsListenable,
  ),
  initialSelectedIds: directory.toList(),
  onChange: (delta, notifyParent) { /* write directory */ },
);
''',
        childUnselect: PickerUnselectPolicy.blocked,
      ),
      const NestedCard(
        title: 'Unrelated: child confirms unselect',
        persistLabel: 'child onChange, parent onClose',
        difference:
            'Removing a directory member who is in use or still on the field asks for confirmation. Try Ada (chip) or Alan (in-use). Cancel leaves the child checkbox selected. Grace has no prompt.',
        source: r'''
SubPickerTile<Person>(
  title: 'Directory membership',
  config: peopleConfig(
    relatedListItemStatusOf: (person) => PickerRelatedListItemStatus(
      unselectPolicy: person.inUse || parent.pendingIds.contains(person.id)
          ? PickerUnselectPolicy.confirm
          : PickerUnselectPolicy.allow,
    ),
    relatedListItemStatusListenable: parent.pendingIdsListenable,
  ),
  initialSelectedIds: directory.toList(),
  onChange: (delta, notifyParent) { /* write directory */ },
);
''',
        childUnselect: PickerUnselectPolicy.confirm,
      ),
      const NestedCard(
        title: 'Unrelated: child with inactive rows',
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
  onChange: (delta, notifyParent) { /* write directory */ },
);
''',
        childLockedInactive: true,
      ),
      const NestedCard(
        title: 'Unrelated: sublist plus related-list icons',
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
      onChange: (delta, notifyParent) { /* write directory */ },
    ),
  ],
);
''',
        relatedOnParent: true,
      ),
      const NestedCard(
        title: 'Unrelated: parent close, child change',
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
      onChange: (delta, notifyParent) { /* write directory */ },
    ),
  ],
);
''',
      ),
      const NestedCard(
        title: 'Unrelated: parent change, nested independent',
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
      onChange: (delta, notifyParent) { /* write directory */ },
    ),
  ],
);
''',
        parentPersist: Persist.change,
      ),
      const NestedCard(
        title: 'Direct: mirror plus parent onChange',
        persistLabel: 'parent onChange, child onChange',
        difference:
            'Direct logic. Sublist deltas mirror into open parent checkboxes and the parent list reloads. Parent row toggles also write the field immediately. Mirror still does not create a parent onChange delta.',
        source: r'''
SearchAnchorPicker<Person>(
  onChange: (delta) { /* parent row/bulk only */ },
  headerBuilder: (context, controller, items) => [
    SubPickerTile<Person>(
      parentController: controller,
      parentSelectionEffect: SubPickerParentSelectionEffect.mirror,
      onChange: (delta, notifyParent) {
        /* write directory */
        notifyParent();
      },
    ),
  ],
);
''',
        relation: NestedRelation.direct,
        parentPersist: Persist.change,
        sublists: 3,
      ),
    ],
  ),
  GallerySection(
    title: 'Fail handling, partial load, and server search',
    caption:
        'Thrown saves and incomplete itemsLoader pages. searchMode defaults to local: load once, filter the snapshot. remote reloads with query and trusts the page. hybrid does both. Missing selected IDs stay selected; pass initialSelectedItemCache to give them a Selected row, including when the loader throws.',
    cards: [
      const SimpleCard(
        title: 'API fail close',
        persistLabel: 'onClose throw',
        difference:
            'Turn on “API fail close”, then change a row and close. This example does not throw on an empty delta — check result.isEmpty in onClose if there is nothing to write. After a failed save, Keep editing returns to the list; Close without saving dismisses the popup.',
        source: r'''
SearchAnchorPicker<Person>(
  config: peopleConfig(title: 'API fail close'),
  initialSelectedIds: selected.toList(),
  onClose: (result) async {
    await Future<void>.delayed(const Duration(milliseconds: 700));
    if (result.isEmpty) return;
    if (failClose) throw StateError('simulated onClose failure');
    selected
      ..addAll(result.added)
      ..removeAll(result.removed);
  },
);
''',
        seed: {1},
        failClose: true,
        saveDelay: Duration(milliseconds: 700),
      ),
      const SimpleCard(
        title: 'API fail change',
        persistLabel: 'onChange throw',
        difference:
            'Turn on “API fail change”. The checkbox moves, the save waits 0.5s, then a snackbar reports the failure and the checkbox restores (unchecks again if you had selected someone).',
        source: r'''
SearchAnchorPicker<Person>(
  config: peopleConfig(title: 'API fail change'),
  initialSelectedIds: selected.toList(),
  onChange: (delta) async {
    await Future<void>.delayed(const Duration(milliseconds: 500));
    if (failChange) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('API fail change')),
      );
      throw StateError('simulated onChange failure');
    }
    selected
      ..addAll(delta.added)
      ..removeAll(delta.removed);
  },
);
''',
        seed: {1, 3},
        persist: Persist.change,
        failChange: true,
        failSnackbar: true,
        saveDelay: Duration(milliseconds: 500),
      ),
      const SimpleCard(
        title: 'API fail search',
        persistLabel: 'itemsLoader throw',
        difference:
            'Turn on “API fail search”. Open the popup: itemsLoader waits 0.5s then throws. The retry error stays on top, and Ada and Grace still appear under Selected because initialSelectedItemCache already resolved them. A failed search page is not an empty selection. Turn the checkbox off and retry to load the catalog.',
        source: r'''
SearchAnchorPicker<Person>(
  initialSelectedIds: selected.toList(),
  initialSelectedItemCache: cachedPeople,
  onClose: (result) { /* persist result.added / result.removed */ },
);

PickerConfig<Person>(
  itemsLoader: (_, query) async {
    await Future<void>.delayed(const Duration(milliseconds: 500));
    if (failSearch) throw StateError('simulated search API failure');
    return api.searchPeople(query);
  },
);
''',
        seed: {1, 3},
        failLoad: true,
        selectedItemCache: true,
      ),
      const SimpleCard(
        title: 'API fail close (custom dialog)',
        persistLabel: 'onClose throw',
        difference:
            'closeSaveFailedBuilder replaces the default dialog. Keep editing returns to the list. Close without saving dismisses. This example still runs onClose for an empty delta; it only throws when there is something to write.',
        source: r'''
SearchAnchorPicker<Person>(
  onClose: (result) {
    if (result.isEmpty) return;
    throw StateError('simulated onClose failure');
  },
  closeSaveFailedBuilder: (context, error, stackTrace) async {
    // Overlay prompt with Keep editing / Close without saving
    return CloseSaveFailedAction.updateSelection;
  },
);
''',
        seed: {1},
        failClose: true,
        customFail: true,
        saveDelay: Duration(milliseconds: 400),
      ),
      SimpleCard(
        title: 'Hidden selected ID',
        persistLabel: 'onClose',
        difference:
            'searchMode is local (the default): itemsLoader returns the first four people once. Typing filters Results only — Linus will not appear. Radia is selected but not on that page, so initialSelectedItemCache puts her in a Selected section. Uncheck her: the row stays until close so you can undo. Search does not hide Selected.\n\n'
            'Rows use DefaultPickerItemTile with title, subtitle (team), and “not on this page” when source is the cache.\n\n'
            'Leave “Show warning on hidden chip” on and tap Radia’s chip X: she is not on this page, so a warning asks before the field drops her. Ada’s chip has no prompt — she is on the loaded page. Turn the checkbox off to remove a hidden chip immediately.',
        source: r'''
SearchAnchorPicker<Person>(
  initialSelectedIds: selected.toList(),
  initialSelectedItemCache: cachedPeople,
  itemBuilder: (context, person, selected, status, source, toggle) {
    return DefaultPickerItemTile(
      selected: selected,
      relatedListItemStatus: status,
      onToggle: (_) => toggle(),
      title: Text(person.name),
      subtitle: Text(
        source == PickerItemSource.initialSelectedItemCache
            ? '${person.team} · not on this page'
            : person.team,
      ),
      selectionMode: SelectionMode.multi,
    );
  },
  onClose: (result) { /* persist result.added / result.removed */ },
);
''',
        seed: const {1, 12},
        itemsLoader: (_, _) async => people.take(4).toList(),
        warnHiddenChip: true,
        visibleCatalogIds: {for (final person in people.take(4)) person.id},
        selectedItemCache: true,
        richItemTile: true,
      ),
      const ServerSearchCard(),
      const NestedCard(
        title: 'Related-list + unknown',
        persistLabel: 'child onClose, parent onClose',
        difference:
            'The main list does not have a full directory. A filled person icon means the Directory sublist has already seen that person (Ada, Margaret). Everyone else is unknown (search icon) — not “not a member”. Unselect is still allowed.\n\n'
            'The main list does not have a full directory. A filled person icon means Directory already contains that person (Ada, Margaret). Everyone else is unknown (search icon), not “not a member”. Those people can appear as rows; membership is not a parent checkbox.\n\n'
            'Close Directory writes only IDs you added in that session onto the field and parent checks. An empty close does not select Margaret or put Ada back. Add Alan in Directory, then close: he is checked and becomes a known member.',
        source: r'''
SearchAnchorPicker<Person>(
  config: peopleConfig(
    relatedListItemStatusOf: (person) => PickerRelatedListItemStatus(
      auxiliaryMembership: directory.contains(person.id)
          ? PickerAuxiliaryMembership.member
          : PickerAuxiliaryMembership.unknown,
    ),
  ),
  headerBuilder: (context, controller, items) => [
    SubPickerTile<Person>(
      title: 'Directory',
      initialSelectedIds: directory.toList(),
      onClose: (result) {
        writeDirectory(result);
        selected.addAll(result.added);
        controller.syncPending(added: result.added);
      },
    ),
  ],
);
''',
        relatedOnParent: true,
        relatedUnknown: true,
        addChildSelectionToParent: true,
        childPersist: Persist.close,
        directorySeed: pagedDirectoryIds,
        sublists: 1,
      ),
    ],
  ),
];
