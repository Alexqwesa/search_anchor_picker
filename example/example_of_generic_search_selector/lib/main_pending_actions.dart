import 'package:flutter/material.dart';
import 'package:generic_search_selector/generic_search_selector.dart';

void main() {
  runApp(const PendingActionsDemoApp());
}

class PendingActionItem {
  const PendingActionItem(this.id, this.label, this.group);

  final int id;
  final String label;
  final String group;
}

const _items = <PendingActionItem>[
  PendingActionItem(1, 'Ada Lovelace', 'Engineering'),
  PendingActionItem(2, 'Grace Hopper', 'Engineering'),
  PendingActionItem(3, 'Katherine Johnson', 'Research'),
  PendingActionItem(4, 'Margaret Hamilton', 'Engineering'),
  PendingActionItem(5, 'Dorothy Vaughan', 'Research'),
  PendingActionItem(6, 'Mary Jackson', 'Research'),
];

class PendingActionsDemoApp extends StatelessWidget {
  const PendingActionsDemoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Pending header actions',
      theme: ThemeData(
        colorSchemeSeed: const Color(0xff006d77),
        useMaterial3: true,
      ),
      home: const PendingActionsDemoPage(),
    );
  }
}

class PendingActionsDemoPage extends StatefulWidget {
  const PendingActionsDemoPage({super.key});

  @override
  State<PendingActionsDemoPage> createState() => _PendingActionsDemoPageState();
}

class _PendingActionsDemoPageState extends State<PendingActionsDemoPage> {
  final Set<int> _selectedIds = <int>{1, 3};
  List<int> _lastAdded = const [];
  List<int> _lastRemoved = const [];

  late final PickerConfig<PendingActionItem> _config =
      PickerConfig<PendingActionItem>(
        title: 'Choose people',
        loadItems: (_) async => _items,
        idOf: (item) => item.id,
        labelOf: (item) => item.label,
        searchTermsOf: (item) => <String>[
          item.label,
          item.group,
          item.id.toString(),
        ],
        comparator: (a, b) => a.label.compareTo(b.label),
      );

  List<int> _sorted(Iterable<int> ids) => ids.toList()..sort();

  String _formatIds(Iterable<int> ids) {
    final sorted = _sorted(ids);
    return sorted.isEmpty ? 'none' : sorted.join(', ');
  }

  void _applyPending(Set<int> ids) {
    setState(() {
      _selectedIds
        ..clear()
        ..addAll(ids);
    });
  }

  Future<void> _finish({
    required List<int> added,
    required List<int> removed,
  }) async {
    setState(() {
      _selectedIds
        ..addAll(added)
        ..removeAll(removed);
      _lastAdded = _sorted(added);
      _lastRemoved = _sorted(removed);
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Header pending-only UI')),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          Text(
            'Pending actions update checkbox state without creating added or '
            'removed deltas.',
            style: theme.textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          const Text(
            'Search for "Research" to see the difference between loaded and '
            'filtered actions. Use Apply pending to parent when the header '
            'intentionally owns persistence.',
          ),
          const SizedBox(height: 24),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              SearchAnchorPicker<PendingActionItem>(
                config: _config,
                initialSelectedIds: _sorted(_selectedIds),
                onFinish: _finish,
                triggerBuilder: (context, open, selectedCount) {
                  return FilledButton.icon(
                    onPressed: open,
                    icon: const Icon(Icons.manage_accounts_outlined),
                    label: Text('Open picker ($selectedCount selected)'),
                  );
                },
                headerBuilder: (context, actions, allItems) => [
                  PendingActionsHeader(
                    actions: actions,
                    loadedCount: allItems.length,
                    onApplyPending: _applyPending,
                  ),
                ],
              ),
              Chip(
                avatar: const Icon(Icons.storage_outlined, size: 18),
                label: Text('Parent selected IDs: ${_formatIds(_selectedIds)}'),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Last onFinish delta',
                    style: theme.textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  Text('added: ${_formatIds(_lastAdded)}'),
                  Text('removed: ${_formatIds(_lastRemoved)}'),
                  const SizedBox(height: 8),
                  Text(
                    'The values stay empty after pending* actions. Toggling a '
                    'result row records a delta normally.',
                    style: theme.textTheme.bodySmall,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class PendingActionsHeader extends StatelessWidget {
  const PendingActionsHeader({
    super.key,
    required this.actions,
    required this.loadedCount,
    required this.onApplyPending,
  });

  final GenericPickerActions<PendingActionItem, int> actions;
  final int loadedCount;
  final ValueChanged<Set<int>> onApplyPending;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      child: ValueListenableBuilder<Set<int>>(
        valueListenable: actions.pendingN,
        builder: (context, pending, child) {
          final pendingIds = pending.toList()..sort();

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Header pending-only actions',
                style: theme.textTheme.titleMedium,
              ),
              const SizedBox(height: 4),
              Text(
                '$loadedCount loaded | pending IDs: '
                '${pendingIds.isEmpty ? 'none' : pendingIds.join(', ')}',
                style: theme.textTheme.bodySmall,
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  OutlinedButton(
                    onPressed: actions.pendingSelectLoaded,
                    child: const Text('Select loaded'),
                  ),
                  OutlinedButton(
                    onPressed: actions.pendingClearLoaded,
                    child: const Text('Clear loaded'),
                  ),
                  OutlinedButton(
                    onPressed: actions.pendingSelectFiltered,
                    child: const Text('Select filtered'),
                  ),
                  OutlinedButton(
                    onPressed: actions.pendingClearFiltered,
                    child: const Text('Clear filtered'),
                  ),
                  FilledButton.tonal(
                    onPressed: () => onApplyPending({...pending}),
                    child: const Text('Apply pending to parent'),
                  ),
                ],
              ),
            ],
          );
        },
      ),
    );
  }
}
