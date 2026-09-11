import 'package:flutter/material.dart';
import 'package:search_anchor_picker/search_anchor_picker.dart';

void main() {
  runApp(const RadioDemoApp());
}

class DemoItem {
  const DemoItem({required this.id, required this.label});

  final int id;
  final String label;

  @override
  String toString() => label;
}

class RadioDemoApp extends StatelessWidget {
  const RadioDemoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Radio Picker Demo',
      theme: ThemeData(useMaterial3: true),
      home: const RadioHome(),
    );
  }
}

class RadioHome extends StatefulWidget {
  const RadioHome({super.key});

  @override
  State<RadioHome> createState() => _RadioHomeState();
}

class _RadioHomeState extends State<RadioHome> {
  int? selectedId;

  int? _unifiedSelectedId;
  List<DemoItem> _extraItems = [];
  final _refreshNotifier = ValueNotifier<int>(0);

  @override
  void dispose() {
    _refreshNotifier.dispose();
    super.dispose();
  }

  final List<DemoItem> mainItems = [
    const DemoItem(id: 1, label: 'Main 1'),
    const DemoItem(id: 2, label: 'Main 2'),
    const DemoItem(id: 3, label: 'Main 3'),
  ];

  final List<DemoItem> subItems = [
    const DemoItem(id: 10, label: 'Sub 1'),
    const DemoItem(id: 11, label: 'Sub 2'),
  ];

  Map<int, DemoItem> get universe {
    final m = <int, DemoItem>{};
    for (final i in mainItems) {
      m[i.id] = i;
    }
    for (final i in subItems) {
      m[i.id] = i;
    }
    return m;
  }

  @override
  Widget build(BuildContext context) {
    final u = universe;

    return Scaffold(
      appBar: AppBar(title: const Text('Radio Demo')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: ListView(
          children: [
            const Text(
              'Radio Picker Demo:\nSingle selection mode with imperative control (tap again to deselect if radioToggle).',
            ),
            const SizedBox(height: 20),
            const Divider(),
            const SizedBox(height: 20),

            // Basic Radio Picker
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _SelectedChips(
                  title: 'Selected Main Item',
                  ids: selectedId == null ? {} : {selectedId!},
                  universe: u,
                  onClear: () => setState(() => selectedId = null),
                ),
                const SizedBox(height: 12),
                _CircleIconTrigger(
                  child: SearchAnchorPicker<DemoItem>(
                    config: PickerConfig<DemoItem>(
                      title: 'Radio Picker',
                      loadItems: (_) async => mainItems,
                      idOf: (it) => it.id,
                      labelOf: (it) => it.label,
                      searchTermsOf: (it) => [it.label],
                    ),
                    mode: PickerMode.radio,
                    initialSelectedIds: selectedId == null ? [] : [selectedId!],
                    onToggle: (item, next) async {
                      if (next) {
                        setState(() => selectedId = item.id);
                        return true;
                      }
                      return false; // Cannot deselect in standard radio mode
                    },
                    triggerBuilder: (_, open, version) {
                      final has = selectedId != null;
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
                  ),
                ),
              ],
            ),

            const SizedBox(height: 20),
            const Divider(),
            const SizedBox(height: 20),

            // Radio Picker with Sub-Picker
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _SelectedChips(
                  title: 'Selected Parent/Sub Item',
                  ids: _unifiedSelectedId == null ? {} : {_unifiedSelectedId!},
                  universe: u,
                  onClear: () => setState(() {
                    _unifiedSelectedId = null;
                    _extraItems.clear(); // Clear transient items on clear
                  }),
                ),
                const SizedBox(height: 12),
                _CircleIconTrigger(
                  child: SearchAnchorPicker<DemoItem>(
                    config: PickerConfig<DemoItem>(
                      title: 'Radio Parent',
                      loadItems: (_) async => [...mainItems, ..._extraItems],
                      idOf: (it) => it.id,
                      labelOf: (it) => it.label,
                      searchTermsOf: (it) => [it.label],
                      listenable: _refreshNotifier,
                    ),
                    mode: PickerMode.radio,
                    initialSelectedIds: _unifiedSelectedId == null
                        ? []
                        : [_unifiedSelectedId!],
                    onToggle: (item, next) async {
                      if (next) {
                        setState(() {
                          _unifiedSelectedId = item.id;
                          // If we picked a main item, clear any transient sub items
                          // (unless this item IS the transient item, but here we assume mainItems are distinct)
                          if (!subItems.contains(item)) {
                            _extraItems.clear();
                            _refreshNotifier.value++;
                          }
                        });
                        return true;
                      }
                      return false;
                    },
                    headerBuilder: (ctx, actions, _) => [
                      ListTile(
                        title: const Text('Open Sub Radio'),
                        leading: const Icon(Icons.subdirectory_arrow_right),
                        onTap: () {
                          // navigate or expand
                        },
                      ),
                      SearchAnchorPicker<DemoItem>(
                        config: PickerConfig<DemoItem>(
                          title: 'Radio Sub',
                          loadItems: (_) async => subItems,
                          idOf: (it) => it.id,
                          labelOf: (it) => it.label,
                          searchTermsOf: (it) => [it.label],
                        ),
                        mode: PickerMode.radio,
                        itemBuilder: (context, item, isSelected, onToggle) {
                          return CheckboxListTile(
                            value: isSelected,
                            onChanged: (v) => onToggle(),
                            title: Text(
                              item.label,
                              style: const TextStyle(color: Colors.blueAccent),
                            ),
                            subtitle: const Text('Custom Builder Item'),
                            checkboxShape: const CircleBorder(),
                          );
                        },
                        triggerChild: const ListTile(
                          title: Text('Sub Radio Trigger (Tile)'),
                          leading: Icon(Icons.touch_app),
                        ),
                        initialSelectedIds: _unifiedSelectedId == null
                            ? []
                            : [_unifiedSelectedId!],
                        onToggle: (item, next) async {
                          if (next) {
                            setState(() {
                              _unifiedSelectedId = item.id;
                              // Add to transient items so it shows in parent list
                              _extraItems = [item];
                              // Force parent picker to reload immediately so it shows this new item
                              _refreshNotifier.value++;
                            });
                            return true;
                          }
                          return false;
                        },
                      ),
                    ],
                    triggerBuilder: (_, open, version) {
                      final has = _unifiedSelectedId != null;
                      return IconButton(
                        tooltip: 'Open parent picker',
                        iconSize: 40,
                        onPressed: open,
                        icon: Icon(
                          has ? Icons.check_circle : Icons.check_circle_outline,
                          color: has ? Colors.green : null,
                        ),
                      );
                    },
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
    this.onClear,
  });

  final String title;
  final Set<int> ids;
  final Map<int, DemoItem> universe;
  final VoidCallback? onClear;

  @override
  Widget build(BuildContext context) {
    final list = ids.toList()..sort();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(title, style: Theme.of(context).textTheme.titleMedium),
                if (onClear != null && ids.isNotEmpty)
                  TextButton(onPressed: onClear, child: const Text('Clear')),
              ],
            ),
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
