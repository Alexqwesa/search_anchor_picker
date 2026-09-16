import 'dart:async';

import 'package:flutter/material.dart';
import 'package:search_anchor_picker/search_anchor_picker.dart';

void main() {
  runApp(const DemoApp());
}

/// Simple item model.
class DemoItem {
  const DemoItem({required this.id, required this.label, required this.group});

  final int id;
  final String label;
  final String group;

  @override
  String toString() => label;
}

/// “Provider-like” repository: holds a list and can mutate it.
/// (We keep 6 of these: listA, subA1, subA2, listB, subB1, subB2)
class ItemsRepo<T> extends ChangeNotifier {
  ItemsRepo(this._items);

  List<T> _items;

  List<T> get items => List.unmodifiable(_items);

  Future<List<T>> load() async => items;

  void setAll(List<T> next) {
    _items = List<T>.from(next);
    notifyListeners();
  }

  void addAll(Iterable<T> add, bool Function(T a, T b) same) {
    final out = List<T>.from(_items);
    for (final x in add) {
      if (!out.any((e) => same(e, x))) out.add(x);
    }
    _items = out;
    notifyListeners();
  }

  void removeWhere(bool Function(T x) test) {
    _items = _items.where((x) => !test(x)).toList();
    notifyListeners();
  }
}

class DemoApp extends StatelessWidget {
  const DemoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SearchAnchorPicker Demo',
      theme: ThemeData(useMaterial3: true),
      home: const DemoHome(),
    );
  }
}

class DemoHome extends StatefulWidget {
  const DemoHome({super.key});

  @override
  State<DemoHome> createState() => _DemoHomeState();
}

class _DemoHomeState extends State<DemoHome> {
  // ========== 6 “providers” ==========
  late final ItemsRepo<DemoItem> listA = ItemsRepo<DemoItem>(_initialListA());
  late final ItemsRepo<DemoItem> subA1 = ItemsRepo<DemoItem>(_initialSubA1());
  late final ItemsRepo<DemoItem> subA2 = ItemsRepo<DemoItem>(_initialSubA2());

  late final ItemsRepo<DemoItem> listB = ItemsRepo<DemoItem>(_initialListB());
  late final ItemsRepo<DemoItem> subB1 = ItemsRepo<DemoItem>(_initialSubB1());
  late final ItemsRepo<DemoItem> subB2 = ItemsRepo<DemoItem>(_initialSubB2());

  int? selectedRadioId;

  // Screen selections (not counted as “providers”).
  final Set<int> selectedOnScreenA = <int>{};
  final Set<int> selectedOnScreenB = <int>{};

  bool same(DemoItem a, DemoItem b) => a.id == b.id;

  DemoItem? findById(Iterable<DemoItem> xs, int id) {
    for (final x in xs) {
      if (x.id == id) return x;
    }
    return null;
  }

  /// Build a global resolver map for chips (so chips show names, not just ids).
  Map<int, DemoItem> buildUniverse() {
    final all = <DemoItem>[
      ...listA.items,
      ...subA1.items,
      ...subA2.items,
      ...listB.items,
      ...subB1.items,
      ...subB2.items,
    ];

    final m = <int, DemoItem>{};
    for (final it in all) {
      m[it.id] = it;
    }
    return m;
  }

  PickerConfig<DemoItem> configForRepo(
    ItemsRepo<DemoItem> repo, {
    String? title,
    PickerRelatedListItemStatus Function(DemoItem)? relatedListItemStatusOf,
  }) {
    return PickerConfig<DemoItem>(
      title: title,
      loadItems: (_) => repo.load(),
      listenable: repo,
      idOf: (it) => it.id,
      labelOf: (it) => it.label,
      searchTermsOf: (it) => [it.label, it.group, it.id.toString()],
      iconOf: (it) => Icon(
        it.group.contains('external') ? Icons.public : Icons.person,
        color: it.group.contains('external') ? null : Colors.grey,
      ),
      comparator: (a, b) => a.label.compareTo(b.label),
      selectedFirst: true,
      relatedListItemStatusOf: relatedListItemStatusOf,
    );
  }

  List<int> _ids(Set<int> s) => s.toList()..sort();

  List<int> _intersectionIds(
    Iterable<DemoItem> current,
    Iterable<DemoItem> allowed,
  ) {
    final allowedIds = allowed.map((e) => e.id).toSet();
    final out = <int>[];
    for (final it in current) {
      if (allowedIds.contains(it.id)) out.add(it.id);
    }
    out.sort();
    return out;
  }

  @override
  void dispose() {
    listA.dispose();
    subA1.dispose();
    subA2.dispose();
    listB.dispose();
    subB1.dispose();
    subB2.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final universe = buildUniverse();

    final mainAConfig = configForRepo(listA, title: 'Icon #1 main list');
    final subA1Config = configForRepo(
      subA1,
      title: 'Sub A1',
      relatedListItemStatusOf: (item) => PickerRelatedListItemStatus(
        unselectPolicy: selectedOnScreenA.contains(item.id)
            ? PickerUnselectPolicy.confirm
            : PickerUnselectPolicy.allow,
      ),
    );
    final subA2Config = configForRepo(subA2, title: 'Sub A2');

    final mainBConfig = configForRepo(listB, title: 'Icon #2 main list');
    final subB1Config = configForRepo(subB1, title: 'Sub B1');
    final subB2Config = configForRepo(subB2, title: 'Sub B2');

    return Scaffold(
      appBar: AppBar(title: const Text('SearchAnchorPicker Example')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: ListView(
          children: [
            const Text(
              'Icon #1:\n'
              '- Sub pickers add/remove items into main list A\n'
              '- Selecting items in main list A toggles chips on screen',
            ),
            const SizedBox(height: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _SelectedChips(
                  title: 'Selected on screen A',
                  ids: selectedOnScreenA,
                  universe: universe,
                ),
                const SizedBox(height: 12),
                _CircleIconTrigger(
                  child: SearchAnchorPicker<DemoItem>(
                    config: mainAConfig,
                    initialSelectedIds: _ids(selectedOnScreenA),
                    selectionMode: SelectionMode.multi,

                    // Selecting in MAIN list => affects screen selection
                    persistence: PickerPersistence.immediate(
                      persist: (delta) async {
                        setState(() {
                          selectedOnScreenA
                            ..addAll(delta.added)
                            ..removeAll(delta.removed);
                        });
                      },
                    ),

                    // Header has two sub pickers that modify listA contents
                    headerBuilder: (ctx, actions, allItems) {
                      return [
                        SubPickerTile<DemoItem>(
                          parentController: actions,
                          parentSelectionEffect:
                              SubPickerParentSelectionEffect.deselectRemoved,
                          key: actions.getKey('subA1'),
                          title: 'Add/remove from Sub A1',
                          icon: Icons.playlist_add,
                          config: subA1Config,
                          menuOffset: Offset(40, 40),
                          initialSelectedIds: _intersectionIds(
                            listA.items,
                            subA1.items,
                          ),
                          // Save per row; parent removal sync follows persistence.
                          persistence: PickerPersistence.immediate(
                            persist: (delta) async {
                              setState(() {
                                listA.addAll(
                                  delta.added
                                      .map((id) => findById(subA1.items, id))
                                      .whereType<DemoItem>(),
                                  same,
                                );
                                listA.removeWhere(
                                  (item) => delta.removed.contains(item.id),
                                );
                              });
                            },
                          ),
                        ),
                        SubPickerTile<DemoItem>(
                          parentController: actions,
                          parentSelectionEffect:
                              SubPickerParentSelectionEffect.deselectRemoved,
                          key: actions.getKey('subA2'),
                          title: 'Add/remove from Sub A2',
                          icon: Icons.playlist_add_check,
                          config: subA2Config,
                          initialSelectedIds: _intersectionIds(
                            listA.items,
                            subA2.items,
                          ),
                          persistence: PickerPersistence.onClose(
                            persist: (delta) async {
                              final addItems = delta.added
                                  .map((id) => findById(subA2.items, id))
                                  .whereType<DemoItem>()
                                  .toList();

                              setState(() {
                                listA.addAll(addItems, same);
                                listA.removeWhere(
                                  (item) => delta.removed.contains(item.id),
                                );
                              });
                            },
                          ),
                        ),
                        const Divider(height: 1),
                        ListTile(
                          leading: const Icon(Icons.clear_all),
                          title: const Text('Clear screen selection A'),
                          onTap: () {
                            // 1) clear screen state
                            setState(() => selectedOnScreenA.clear());

                            // 2) clear overlay pending selection NOW (immediate checkbox repaint)
                            actions.syncPending(removed: actions.pendingIds);
                          },
                        ),
                        const Divider(height: 1),
                      ];
                    },

                    // Trigger builder: icon only (circle ripple)
                    triggerBuilder: (_, open, version) {
                      final has = selectedOnScreenA.isNotEmpty;
                      return IconButton(
                        tooltip: 'Open picker A',
                        iconSize: 40,
                        onPressed: open,
                        icon: Icon(
                          has
                              ? Icons.person_search
                              : Icons.person_search_outlined,
                          color: has ? Colors.green : null,
                        ),
                      );
                    },

                    viewConstraints: BoxConstraints(
                      minWidth: 520,
                      maxHeight: MediaQuery.sizeOf(context).height * 2 / 3,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 28),
            const Divider(),
            const SizedBox(height: 28),

            const Text(
              'Icon #2:\n'
              '- Sub pickers toggle chips on screen B (do NOT change main list B)\n'
              '- Selecting items in main list B also toggles chips on screen',
            ),
            const SizedBox(height: 8),

            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _SelectedChips(
                  title: 'Selected on screen B',
                  ids: selectedOnScreenB,
                  universe: universe,
                ),
                const SizedBox(height: 12),
                _CircleIconTrigger(
                  child: SearchAnchorPicker<DemoItem>(
                    config: mainBConfig,
                    initialSelectedIds: _ids(selectedOnScreenB),
                    selectionMode: SelectionMode.multi,

                    // Selecting in MAIN list => affects screen selection
                    persistence: PickerPersistence.immediate(
                      persist: (delta) async {
                        setState(() {
                          selectedOnScreenB
                            ..addAll(delta.added)
                            ..removeAll(delta.removed);
                        });
                      },
                    ),

                    headerBuilder: (ctx, actions, allItems) {
                      return [
                        SubPickerTile<DemoItem>(
                          parentController: actions,
                          parentSelectionEffect:
                              SubPickerParentSelectionEffect.mirror,
                          key: actions.getKey('subB1'),
                          title: 'Select from Sub B1 (to screen)',
                          icon: Icons.person_add_alt_1,
                          config: subB1Config,
                          initialSelectedIds: _ids(selectedOnScreenB),
                          persistence: PickerPersistence.onClose(
                            persist: (delta) async {
                              setState(() {
                                selectedOnScreenB
                                  ..addAll(delta.added)
                                  ..removeAll(delta.removed);
                              });
                            },
                          ),
                        ),
                        SubPickerTile<DemoItem>(
                          parentController: actions,
                          parentSelectionEffect:
                              SubPickerParentSelectionEffect.mirror,
                          key: actions.getKey('subB2'),
                          title: 'Select from Sub B2 (to screen)',
                          icon: Icons.person_add_alt,
                          config: subB2Config,
                          initialSelectedIds: _ids(selectedOnScreenB),
                          persistence: PickerPersistence.onClose(
                            persist: (delta) async {
                              setState(() {
                                selectedOnScreenB
                                  ..addAll(delta.added)
                                  ..removeAll(delta.removed);
                              });
                            },
                          ),
                        ),
                        const Divider(height: 1),
                        ListTile(
                          leading: const Icon(Icons.clear_all),
                          title: const Text('Clear screen selection B'),
                          onTap: () {
                            setState(() => selectedOnScreenB.clear());
                            actions.syncPending(removed: actions.pendingIds);
                          },
                        ),
                        const Divider(height: 1),
                      ];
                    },

                    triggerBuilder: (_, open, version) {
                      final has = selectedOnScreenB.isNotEmpty;
                      return IconButton(
                        tooltip: 'Open picker B',
                        iconSize: 40,
                        onPressed: open,
                        icon: Icon(
                          has ? Icons.group_add : Icons.group_add_outlined,
                          color: has ? Colors.green : null,
                        ),
                      );
                    },

                    viewConstraints: BoxConstraints(
                      minWidth: 520,
                      maxHeight: MediaQuery.sizeOf(context).height * 2 / 3,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 28),
            const Divider(),
            const SizedBox(height: 28),

            const Text(
              'Icon #3 (radio mode):\n'
              '- Single select\n'
              '- Click selects one item and closes the popup immediately',
            ),
            const SizedBox(height: 8),

            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Selected radio item',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 8),
                        if (selectedRadioId == null)
                          const Text('No selection')
                        else
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              Chip(
                                label: Text(
                                  universe[selectedRadioId!]?.label ??
                                      '#$selectedRadioId',
                                ),
                              ),
                              TextButton(
                                onPressed: () =>
                                    setState(() => selectedRadioId = null),
                                child: const Text('Clear'),
                              ),
                            ],
                          ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                _CircleIconTrigger(
                  child: SearchAnchorPicker<DemoItem>(
                    config: configForRepo(listA, title: 'Radio picker demo'),
                    selectionMode: SelectionMode.single,

                    // Seed selection for radio (0 or 1 item).
                    initialSelectedIds: selectedRadioId == null
                        ? const []
                        : [selectedRadioId!],

                    persistence: PickerPersistence.immediate(
                      persist: (delta) async {
                        if (delta.added.isEmpty) return;
                        setState(() => selectedRadioId = delta.added.first);
                      },
                    ),

                    triggerBuilder: (_, open, version) {
                      final has = selectedRadioId != null;
                      return IconButton(
                        tooltip: 'Open radio picker',
                        iconSize: 40,
                        onPressed: open,
                        icon: Icon(
                          has
                              ? Icons.radio_button_checked
                              : Icons.radio_button_unchecked,
                          color: has ? Colors.green : null,
                        ),
                      );
                    },

                    viewConstraints: BoxConstraints(
                      minWidth: 520,
                      maxHeight: MediaQuery.sizeOf(context).height * 2 / 3,
                    ),
                  ),
                ),
              ],
            ),
            SizedBox.square(dimension: 600),
          ],
        ),
      ),
    );
  }

  // ===== demo data =====

  List<DemoItem> _initialListA() => const [
    DemoItem(id: 1, label: 'A: Alice (internal)', group: 'internal'),
    DemoItem(id: 2, label: 'A: Bob (internal)', group: 'internal'),
  ];

  List<DemoItem> _initialSubA1() => const [
    DemoItem(id: 10, label: 'A1: Charlie (external)', group: 'external'),
    DemoItem(id: 11, label: 'A1: Diana (external)', group: 'external'),
    DemoItem(
      id: 12,
      label: 'A1: This label is very very long to force ellipsis tooltip',
      group: 'external',
    ),
  ];

  List<DemoItem> _initialSubA2() => const [
    DemoItem(id: 20, label: 'A2: Ethan (internal)', group: 'internal'),
    DemoItem(id: 21, label: 'A2: Fiona (internal)', group: 'internal'),
  ];

  List<DemoItem> _initialListB() => const [
    DemoItem(id: 101, label: 'B: Igor (internal)', group: 'internal'),
    DemoItem(id: 102, label: 'B: Julia (internal)', group: 'internal'),
  ];

  List<DemoItem> _initialSubB1() => const [
    DemoItem(id: 110, label: 'B1: Ken (external)', group: 'external'),
    DemoItem(id: 111, label: 'B1: Lina (external)', group: 'external'),
  ];

  List<DemoItem> _initialSubB2() => const [
    DemoItem(id: 120, label: 'B2: Max (internal)', group: 'internal'),
    DemoItem(id: 121, label: 'B2: Nina (internal)', group: 'internal'),
  ];
}

class _CircleIconTrigger extends StatelessWidget {
  const _CircleIconTrigger({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Material(
      type: MaterialType.transparency,
      child: InkResponse(
        radius: 28,
        containedInkWell: true,
        highlightShape: BoxShape.circle,
        child: ClipOval(child: child),
      ),
    );
  }
}

class _SelectedChips extends StatelessWidget {
  const _SelectedChips({
    required this.title,
    required this.ids,
    required this.universe,
  });

  final String title;
  final Set<int> ids;
  final Map<int, DemoItem> universe;

  @override
  Widget build(BuildContext context) {
    final list = ids.toList()..sort();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            if (list.isEmpty)
              const Text('No selection')
            else
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final id in list)
                    Chip(label: Text(universe[id]?.label ?? '#$id')),
                ],
              ),
          ],
        ),
      ),
    );
  }
}
