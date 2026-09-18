import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:search_anchor_picker/search_anchor_picker.dart';

void main() {
  runApp(const ProviderScope(child: DemoApp()));
}

class DemoItem {
  const DemoItem({required this.id, required this.label, required this.group});

  final int id;
  final String label;
  final String group;

  @override
  String toString() => label;
}

// ========== Providers ==========

// Use Notifier and pass family arg via constructor for Riverpod 3 compatibility.
class ItemsNotifier extends Notifier<AsyncValue<List<DemoItem>>> {
  ItemsNotifier(this.arg);

  final String arg;

  @override
  AsyncValue<List<DemoItem>> build() {
    // Initial load simulation trigger
    // We return loading initially, and trigger the fetch.
    _init(arg);
    return const AsyncValue.loading();
  }

  Future<void> _init(String key) async {
    await Future.delayed(const Duration(milliseconds: 500));
    state = AsyncValue.data(_initialData(key));
  }

  Future<void> addAll(Iterable<DemoItem> items) async {
    final current = state.asData?.value ?? [];
    final next = [...current];
    for (final x in items) {
      if (!next.any((e) => e.id == x.id)) next.add(x);
    }
    state = AsyncValue.data(next);
  }

  Future<void> removeWhere(bool Function(DemoItem) test) async {
    final current = state.asData?.value ?? [];
    final next = current.where((x) => !test(x)).toList();
    state = AsyncValue.data(next);
  }

  Future<void> refreshWithDelay() async {
    state = const AsyncValue.loading();
    await Future.delayed(const Duration(milliseconds: 800));
    // Re-init
    state = AsyncValue.data(_initialData(arg));
  }

  List<DemoItem> _initialData(String key) {
    switch (key) {
      case 'listA':
        return [
          const DemoItem(
            id: 1,
            label: 'A: Alice (internal)',
            group: 'internal',
          ),
          const DemoItem(id: 2, label: 'A: Bob (internal)', group: 'internal'),
        ];
      case 'subA1':
        return [
          const DemoItem(
            id: 10,
            label: 'A1: Charlie (external)',
            group: 'external',
          ),
          const DemoItem(
            id: 11,
            label: 'A1: Diana (external)',
            group: 'external',
          ),
          const DemoItem(
            id: 12,
            label: 'A1: Overflow label test',
            group: 'external',
          ),
        ];
      case 'subA2':
        return [
          const DemoItem(
            id: 20,
            label: 'A2: Ethan (internal)',
            group: 'internal',
          ),
          const DemoItem(
            id: 21,
            label: 'A2: Fiona (internal)',
            group: 'internal',
          ),
        ];
      case 'listB':
        return [
          const DemoItem(
            id: 101,
            label: 'B: Igor (internal)',
            group: 'internal',
          ),
          const DemoItem(
            id: 102,
            label: 'B: Julia (internal)',
            group: 'internal',
          ),
        ];
      case 'subB1':
        return [
          const DemoItem(
            id: 110,
            label: 'B1: Ken (external)',
            group: 'external',
          ),
          const DemoItem(
            id: 111,
            label: 'B1: Lina (external)',
            group: 'external',
          ),
        ];
      case 'subB2':
        return [
          const DemoItem(
            id: 120,
            label: 'B2: Max (internal)',
            group: 'internal',
          ),
          const DemoItem(
            id: 121,
            label: 'B2: Nina (internal)',
            group: 'internal',
          ),
        ];
      default:
        return [];
    }
  }
}

final itemsProvider =
    NotifierProvider.family<ItemsNotifier, AsyncValue<List<DemoItem>>, String>(
      ItemsNotifier.new,
    );

class SetIntNotifier extends Notifier<Set<int>> {
  @override
  Set<int> build() => {};

  void set(Set<int> next) {
    state = next;
  }
}

final selectedScreenAProvider = NotifierProvider<SetIntNotifier, Set<int>>(
  SetIntNotifier.new,
);
final selectedScreenBProvider = NotifierProvider<SetIntNotifier, Set<int>>(
  SetIntNotifier.new,
);

class DemoApp extends StatelessWidget {
  const DemoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Async Riverpod Demo',
      theme: ThemeData(useMaterial3: true),
      home: const DemoHome(),
    );
  }
}

class DemoHome extends ConsumerStatefulWidget {
  const DemoHome({super.key});

  @override
  ConsumerState<DemoHome> createState() => _DemoHomeState();
}

class _DemoHomeState extends ConsumerState<DemoHome> {
  late final _RefListenable listAListener = _RefListenable(
    ref,
    itemsProvider('listA'),
  );
  late final _RefListenable subA1Listener = _RefListenable(
    ref,
    itemsProvider('subA1'),
  );
  late final _RefListenable subA2Listener = _RefListenable(
    ref,
    itemsProvider('subA2'),
  );
  late final _RefListenable listBListener = _RefListenable(
    ref,
    itemsProvider('listB'),
  );
  late final _RefListenable subB1Listener = _RefListenable(
    ref,
    itemsProvider('subB1'),
  );
  late final _RefListenable subB2Listener = _RefListenable(
    ref,
    itemsProvider('subB2'),
  );

  DemoItem? findById(List<DemoItem>? list, int id) {
    if (list == null) return null;
    for (final x in list) {
      if (x.id == id) return x;
    }
    return null;
  }

  Map<int, DemoItem> buildUniverse() {
    final all = <DemoItem>[];
    for (final key in ['listA', 'subA1', 'subA2', 'listB', 'subB1', 'subB2']) {
      final val = ref.watch(itemsProvider(key)).asData?.value;
      if (val != null) all.addAll(val);
    }

    final m = <int, DemoItem>{};
    for (final it in all) {
      m[it.id] = it;
    }
    return m;
  }

  PickerConfig<DemoItem> configFor(
    String key, {
    String? title,
    PickerRelatedListItemStatus Function(DemoItem)? relatedListItemStatusOf,
    required _RefListenable listenable,
  }) {
    return PickerConfig<DemoItem>(
      title: title,
      loadItems: (ctx) async {
        final val = ref.read(itemsProvider(key));
        if (val.isLoading) return val.asData?.value ?? [];
        return val.asData?.value ?? [];
      },
      listenable: listenable,
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

  List<int> _intersectionIds(List<DemoItem>? current, List<DemoItem>? allowed) {
    if (current == null || allowed == null) return [];
    final allowedIds = allowed.map((e) => e.id).toSet();
    final out = <int>[];
    for (final it in current) {
      if (allowedIds.contains(it.id)) out.add(it.id);
    }
    out.sort();
    return out;
  }

  @override
  Widget build(BuildContext context) {
    final universe = buildUniverse();
    final selectedOnScreenA = ref.watch(selectedScreenAProvider);
    // final selectedOnScreenB = ref.watch(selectedScreenBProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Async Riverpod Demo'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh List A',
            onPressed: () =>
                ref.read(itemsProvider('listA').notifier).refreshWithDelay(),
          ),
          IconButton(
            icon: const Icon(Icons.timer_off),
            tooltip: 'Invalidate SubA1',
            onPressed: () => ref.invalidate(itemsProvider('subA1')),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: ListView(
          children: [
            const Text(
              'Async Demo with Riverpod. Use top buttons to trigger refresh/delay.',
            ),
            const SizedBox(height: 10),

            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _SelectedChips(
                  title: 'Screen A',
                  ids: selectedOnScreenA,
                  universe: universe,
                ),
                const SizedBox(height: 12),
                _CircleIconTrigger(
                  child: SearchAnchorPicker<DemoItem>(
                    config: configFor(
                      'listA',
                      title: 'Main A',
                      listenable: listAListener,
                    ),
                    initialSelectedIds: _ids(selectedOnScreenA),
                    selectionMode: SelectionMode.multi,
                    onChange: (delta) {
                      final current = ref.read(selectedScreenAProvider);
                      final next = Set<int>.from(current)
                        ..addAll(delta.added)
                        ..removeAll(delta.removed);
                      ref.read(selectedScreenAProvider.notifier).set(next);
                    },
                    headerBuilder: (ctx, actions, allItems) {
                      final lA =
                          ref.watch(itemsProvider('listA')).asData?.value ?? [];
                      final sA1 =
                          ref.watch(itemsProvider('subA1')).asData?.value ?? [];

                      return [
                        _SubPickerTile(
                          key: actions.getKey('subA1'),
                          title: 'Sub A1 (Async)',
                          icon: Icons.cloud_download,
                          config: configFor(
                            'subA1',
                            title: 'Sub A1',
                            listenable: subA1Listener,
                            relatedListItemStatusOf: (item) =>
                                PickerRelatedListItemStatus(
                                  unselectPolicy:
                                      selectedOnScreenA.contains(item.id)
                                      ? PickerUnselectPolicy.confirm
                                      : PickerUnselectPolicy.allow,
                                ),
                          ),
                          seedIds: _intersectionIds(lA, sA1),
                          onClose: (result) async {
                            final addItems = result.added
                                .map((id) => findById(sA1, id))
                                .whereType<DemoItem>();
                            await ref
                                .read(itemsProvider('listA').notifier)
                                .addAll(addItems);

                            if (result.removed.isNotEmpty) {
                              await ref
                                  .read(itemsProvider('listA').notifier)
                                  .removeWhere(
                                    (item) => result.removed.contains(item.id),
                                  );
                            }

                            final validIds =
                                (ref
                                            .read(itemsProvider('listA'))
                                            .asData
                                            ?.value ??
                                        [])
                                    .map((item) => item.id)
                                    .toSet();
                            final currentScreen = Set<int>.from(
                              ref.read(selectedScreenAProvider),
                            );
                            currentScreen.removeWhere(
                              (id) => !validIds.contains(id),
                            );
                            ref
                                .read(selectedScreenAProvider.notifier)
                                .set(currentScreen);

                            actions.syncPending(removed: result.removed);
                          },
                        ),
                      ];
                    },
                    triggerBuilder: (_, open, version) {
                      final has = selectedOnScreenA.isNotEmpty;
                      final isLoading = ref
                          .watch(itemsProvider('listA'))
                          .isLoading;
                      return Stack(
                        alignment: Alignment.center,
                        children: [
                          IconButton(
                            iconSize: 40,
                            tooltip: 'Open picker A',
                            onPressed: open,
                            icon: Icon(
                              Icons.person_search,
                              color: has ? Colors.green : null,
                            ),
                          ),
                          if (isLoading)
                            const SizedBox(
                              width: 40,
                              height: 40,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                        ],
                      );
                    },
                    viewConstraints: const BoxConstraints(
                      minWidth: 300,
                      maxHeight: 400,
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
}

class _RefListenable extends ChangeNotifier {
  _RefListenable(this.ref, this.provider) {
    // Listen to changes
    _sub = ref.listenManual(provider, (prev, next) {
      notifyListeners();
    });
  }

  final WidgetRef ref;
  final dynamic provider;
  late final ProviderSubscription _sub;

  @override
  void dispose() {
    _sub.close();
    super.dispose();
  }
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

class _SubPickerTile extends StatelessWidget {
  const _SubPickerTile({
    super.key,
    required this.title,
    required this.icon,
    required this.config,
    required this.seedIds,
    required this.onClose,
  });

  final String title;
  final IconData icon;
  final PickerConfig<DemoItem> config;
  final List<int> seedIds;
  final Future<void> Function(PickerDelta<int> result) onClose;

  @override
  Widget build(BuildContext context) {
    return SearchAnchorPicker<DemoItem>(
      config: config,
      initialSelectedIds: seedIds,
      selectionMode: SelectionMode.multi,
      triggerChild: ListTile(leading: Icon(icon), title: Text(title)),
      onClose: onClose,
      viewConstraints: const BoxConstraints(minWidth: 300, maxHeight: 400),
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
        padding: const EdgeInsets.all(8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title),
            const SizedBox(height: 8),
            Wrap(
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
