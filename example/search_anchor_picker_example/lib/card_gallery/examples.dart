import 'package:flutter/material.dart';
import 'package:search_anchor_picker/search_anchor_picker.dart';

import 'field_relation_card.dart';
import 'nested_card.dart';
import 'people.dart';
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
            'Select loaded / Clear loaded ignore the search box and act on the whole loadItems page. Search for Linus, then Select loaded: Ada … Radia all check, not just Linus. One delta.',
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
        title: 'Anchored popup',
        persistLabel: 'onClose',
        difference:
            'isFullScreen is false, so the menu is anchored to the field. Directory and Watchlist sit in the header; the main people list is below them. Open each sublist: they use different menuOffset and viewConstraints. Tap outside to dismiss.',
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
        secondSublist: true,
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
    title: 'Selected, main list, and sublist',
    caption:
        'How field chips, parent rows, and a nested directory share people. Extras can go to the field only, appear as main-list rows (checked or not), and leave the directory with or without leaving the field.',
    cards: [
      const SimpleCard(
        title: 'Selected stay in this open list',
        persistLabel: 'onClose',
        difference:
            'The field chips are the selection. The popup must keep showing those people so you can uncheck them, even when they are not in the searchable catalog.\n\n'
            'This catalog is Ada … Knuth. The field starts with Ada (in catalog), Linus, and Radia (outside it). Open: Linus and Radia are in the list because loadItems unions the current chips. Uncheck Radia: she stays in this open overlay — the loaded snapshot does not drop her mid-session. Close: her chip is gone. Open again: she is neither selected nor in the catalog, so she disappears. Linus still appears because he still has a chip.\n\n'
            'Compare with Hidden selected ID, which keeps a missing ID selected without putting a row in the list at all.',
        source: r'''
SearchAnchorPicker<Person>(
  config: peopleConfig(
    loadItems: (_) async {
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
        title: 'Nested: check added',
        persistLabel: 'child onChange, parent onClose',
        difference:
            'selectAdded. Adding someone to the directory also checks them in the open parent. This demo writes those IDs onto the field chips immediately — syncPending does not create a parent onClose delta.',
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
            'deselectRemoved. Removing someone from the directory unchecks them in the open parent. This demo also drops them from the field chips immediately — parent onClose would not see that remove.',
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
            'mirror. Parent checkboxes follow both sides of the directory delta. This demo writes the same delta onto the field chips. Parent onClose still only reports explicit parent row toggles.',
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
      const FieldRelationCard(
        title: 'Directory members on the field cannot leave',
        persistLabel: 'parent onClose, child onChange',
        difference:
            'The main popup lists everyone. Some of those rows are also directory members. The field starts with Ada and Katherine. Directory starts with Ada, Alan, and Margaret.\n\n'
            'Open Directory: those three are checked. Ada is also a field chip, so unselect is blocked — she must stay in the directory while she is on the main screen. Alan is directory-only, so you can remove him. Katherine is on the field but not in the directory, so she is not checked in the sublist.\n\n'
            'Parent rows show directory membership icons. Field chips still wait for parent close. The lock reads parent pending, so if you check Ada on the parent first, the directory row blocks immediately.',
        source: r'''
SubPickerTile<Person>(
  title: 'Directory membership',
  config: peopleConfig(
    relatedListItemStatusOf: (person) => PickerRelatedListItemStatus(
      unselectPolicy: parent.pendingIds.contains(person.id)
          ? PickerUnselectPolicy.blocked
          : PickerUnselectPolicy.allow,
    ),
    relatedListItemStatusListenable: parent.pendingIdsListenable,
  ),
  initialSelectedIds: directory.toList(),
  onChange: (delta) { /* write directory */ },
);
''',
        sublistUnselect: SublistFieldUnselect.blockIfOnField,
      ),
      const FieldRelationCard(
        title: 'On-field directory members confirm unselect',
        persistLabel: 'parent onClose, child onChange',
        difference:
            'Same overlap as “cannot leave”, but the directory asks before removing someone who is still on the field. Try Ada (on the field): confirm or cancel. Try Alan (directory only): he unchecks with no dialog.\n\n'
            'Use confirm when the person may leave the directory, but the user should notice that they are still a field value. Use blocked when the directory must keep every person who is shown on the main screen.',
        source: r'''
relatedListItemStatusOf: (person) => PickerRelatedListItemStatus(
  unselectPolicy: parent.pendingIds.contains(person.id)
      ? PickerUnselectPolicy.confirm
      : PickerUnselectPolicy.allow,
),
''',
        sublistUnselect: SublistFieldUnselect.confirmIfOnField,
      ),
      const FieldRelationCard(
        title: 'Sublist extra goes to the field only',
        persistLabel: 'parent onClose, child onChange, selectAdded',
        difference:
            'The parent list is the short catalog Ada … Knuth. Directory can still load everyone, including Linus and Radia, who are not parent rows.\n\n'
            'Add Linus in Directory (selectAdded). The open parent checks him even though he is not in loadItems, and this demo writes him onto the field chips immediately. Close and reopen: there is still no Linus row — a hidden selected ID. Directory still shows him checked.\n\n'
            'That is “directly to the screen field”. He never appears as a main-list checkbox. Remove him with the chip, or from Directory plus deselectRemoved (see the leave-field card). Compare with Hidden selected ID.',
        source: r'''
SearchAnchorPicker<Person>(
  config: peopleConfig(
    loadItems: (_) async => people.where((p) => p.id <= 6).toList(),
  ),
  headerBuilder: (context, controller, items) => [
    SubPickerTile<Person>(
      parentController: controller,
      parentSelectionEffect: SubPickerParentSelectionEffect.selectAdded,
      onChange: (delta) { /* write directory */ },
    ),
  ],
);
''',
        effect: SubPickerParentSelectionEffect.selectAdded,
        parentRows: ParentRowSet.mainCatalog,
      ),
      const FieldRelationCard(
        title: 'Field-only extra: leave directory, leave field',
        persistLabel: 'parent onClose, child onChange, mirror',
        difference:
            'Same short parent catalog as “Sublist extra goes to the field only”, but directory membership is mirrored onto the parent: add checks, remove unchecks.\n\n'
            'Add Linus in Directory. He is a field chip with no parent row. Uncheck Linus in Directory: the parent drops him even though he has no row, and this demo drops the chip immediately. Reopen: he is gone from the list.\n\n'
            'Ada is a catalog row on the field — removing her from Directory unchecks the parent row too. Membership drives the chip; the main list never shows the extra.',
        source: r'''
SearchAnchorPicker<Person>(
  config: peopleConfig(
    loadItems: (_) async => people.where((p) => p.id <= 6).toList(),
  ),
  headerBuilder: (context, controller, items) => [
    SubPickerTile<Person>(
      parentController: controller,
      parentSelectionEffect: SubPickerParentSelectionEffect.mirror,
      onChange: (delta) { /* write directory */ },
    ),
  ],
);
''',
        effect: SubPickerParentSelectionEffect.mirror,
        parentRows: ParentRowSet.mainCatalog,
      ),
      const FieldRelationCard(
        title: 'Sublist extra appears on main, unchecked',
        persistLabel: 'parent onClose, child onChange, no effect',
        difference:
            'The parent list loads everyone, so directory extras are ordinary parent rows. Adding to Directory does not check the parent (effect none).\n\n'
            'Add Linus in Directory: the footer updates, the parent Linus row stays unchecked, and the field chips do not change. He is now a directory member who is available on the main list but not selected.\n\n'
            'To put him on the field, check him on the parent (or use selectAdded in the next card). To drop only membership, uncheck him in Directory — he remains a main-list row because loadItems still returns everyone.',
        source: r'''
SubPickerTile<Person>(
  title: 'Directory membership',
  // parentController omitted — effect none
  onChange: (delta) { /* write directory */ },
);
''',
        effect: SubPickerParentSelectionEffect.none,
        parentRows: ParentRowSet.allPeople,
      ),
      const FieldRelationCard(
        title: 'Sublist extra appears on main, checked',
        persistLabel: 'parent onClose, child onChange, selectAdded',
        difference:
            'Same full parent list as the unchecked card, but selectAdded also checks the open parent.\n\n'
            'Add Linus in Directory: his parent checkbox turns on, and this demo writes him onto the field chips immediately. Directory still lists him as a member (icon on the parent row).\n\n'
            'Two ways to take him off the field afterwards: uncheck the parent row, or remove him from Directory with deselectRemoved (next cards). Removing him from Directory with effect none leaves the parent checkbox on.',
        source: r'''
SubPickerTile<Person>(
  parentController: controller,
  parentSelectionEffect: SubPickerParentSelectionEffect.selectAdded,
  onChange: (delta) { /* write directory */ },
);
''',
        effect: SubPickerParentSelectionEffect.selectAdded,
        parentRows: ParentRowSet.allPeople,
      ),
      const FieldRelationCard(
        title: 'Leave directory, stay on the field',
        persistLabel: 'parent onClose, child onChange, selectAdded',
        difference:
            'selectAdded only pushes directory adds onto the parent. It does not uncheck on directory remove.\n\n'
            'Ada starts as both a chip and a directory member. Open Directory and uncheck Ada: she leaves the directory (footer), but the parent checkbox and the field chip stay. Close the parent: Ada is still selected.\n\n'
            'Use this when directory membership is extra metadata and the field value has its own lifetime. Contrast with “Leave directory, also leave the field”.',
        source: r'''
SubPickerTile<Person>(
  parentController: controller,
  parentSelectionEffect: SubPickerParentSelectionEffect.selectAdded,
  onChange: (delta) { /* write directory */ },
);
''',
        effect: SubPickerParentSelectionEffect.selectAdded,
        parentRows: ParentRowSet.allPeople,
      ),
      const FieldRelationCard(
        title: 'Leave directory, also leave the field',
        persistLabel:
            'child onChange writes directory and field, deselectRemoved',
        difference:
            'deselectRemoved unchecks the open parent, but that is only pending. syncPending does not create a parent onClose delta, so this card also writes the child remove onto the field chips.\n\n'
            'Ada starts on the field and in the directory. Uncheck Ada in Directory: her chip leaves immediately, and the parent row unchecks. Close: she stays gone. Alan is directory-only, so removing him does not change chips. Katherine is field-only, so she is not checked in Directory and this effect never runs for her.\n\n'
            'Pair with selectAdded (mirror) if extras should join and leave the field together with the directory. This card is remove-only so you can see unselect without also auto-checking new members.',
        source: r'''
SubPickerTile<Person>(
  parentController: controller,
  parentSelectionEffect: SubPickerParentSelectionEffect.deselectRemoved,
  onChange: (delta) {
    directory
      ..addAll(delta.added)
      ..removeAll(delta.removed);
    // syncPending does not persist parent selection.
    selected.removeAll(delta.removed);
  },
);
''',
        effect: SubPickerParentSelectionEffect.deselectRemoved,
        parentRows: ParentRowSet.allPeople,
      ),
    ],
  ),
  GallerySection(
    title: 'Nested picker structure',
    caption:
        'One or more SubPickerTiles, child selection modes, and which callback writes. Coupling effects live in the previous section; these cards are about nesting itself.',
    cards: [
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
  onChange: (delta) { /* write directory */ },
);
''',
        childUnselect: PickerUnselectPolicy.blocked,
      ),
      const NestedCard(
        title: 'Nested child confirms unselect',
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
  onChange: (delta) { /* write directory */ },
);
''',
        childUnselect: PickerUnselectPolicy.confirm,
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
    ],
  ),
  GallerySection(
    title: 'Fail handling, partial load, and server search',
    caption:
        'Thrown saves, incomplete loadItems pages, and unknown related-list membership. Search in this picker filters the loaded page; a server API should return the current page from loadItems and never treat a missing row as unselected.',
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
        persistLabel: 'loadItems throw',
        difference:
            'Turn on “API fail search”. Open the popup: loadItems waits 0.5s then throws, so the list shows the load error (retry). Selected chips stay — a failed search page is not an empty selection. Turn the checkbox off and retry.',
        source: r'''
PickerConfig<Person>(
  loadItems: (_) async {
    await Future<void>.delayed(const Duration(milliseconds: 500));
    if (failSearch) throw StateError('simulated search API failure');
    return api.searchPeople();
  },
);
''',
        seed: {1, 3},
        failLoad: true,
      ),
      const SimpleCard(
        title: 'API fail close (custom dialog)',
        persistLabel: 'onClose throw',
        difference:
            'closeSaveFailedBuilder replaces the default dialog. Keep editing returns to the list. Close without saving dismisses. This example still runs onClose for an empty delta; it only throws when there is something to write.',
        source: r'''
SearchAnchorPicker<Person>(
  onClose: (result) {
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
    ],
  ),
];
