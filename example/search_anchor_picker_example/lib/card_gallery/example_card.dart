import 'package:flutter/material.dart';

import 'people.dart';

class ExampleCard extends StatelessWidget {
  const ExampleCard({
    required this.title,
    required this.persist,
    required this.difference,
    required this.source,
    required this.child,
    super.key,
    this.footer,
  });

  final String title;
  final String persist;
  final String difference;
  final String source;
  final Widget child;
  final Widget? footer;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(title, style: theme.textTheme.titleMedium),
                ),
                IconButton(
                  tooltip: 'Source',
                  icon: const Icon(Icons.code),
                  onPressed: () =>
                      showExampleSource(context, title: title, source: source),
                ),
              ],
            ),
            Text(persist, style: theme.textTheme.labelLarge),
            const SizedBox(height: 4),
            SelectableText(
              difference,
              style: theme.textTheme.bodyMedium?.copyWith(height: 1.4),
            ),
            const SizedBox(height: 12),
            child,
            if (footer != null) ...[const SizedBox(height: 8), footer!],
          ],
        ),
      ),
    );
  }
}

class ChipField extends StatelessWidget {
  const ChipField({
    required this.ids,
    required this.addButton,
    required this.onDeleted,
    super.key,
  });

  final Set<int> ids;
  final Widget addButton;
  final ValueChanged<int> onDeleted;

  static const _lineHeight = 40.0;

  @override
  Widget build(BuildContext context) {
    return InputDecorator(
      decoration: const InputDecoration(
        border: OutlineInputBorder(),
        isDense: true,
        alignLabelWithHint: true,
        contentPadding: EdgeInsets.fromLTRB(8, 8, 8, 8),
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: _lineHeight-8),
        child: Wrap(
          spacing: 8,
          runSpacing: 8,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            for (final id in ids)
              InputChip(
                label: Text(personName(id)),
                onDeleted: () => onDeleted(id),
              ),
            addButton,
          ],
        ),
      ),
    );
  }
}

Future<void> showExampleSource(
  BuildContext context, {
  required String title,
  required String source,
}) {
  return showDialog<void>(
    context: context,
    builder: (context) {
      return AlertDialog(
        title: Text(title),
        content: SizedBox(
          width: 560,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxHeight: 420),
            child: SingleChildScrollView(
              child: SelectableText(
                source,
                style: const TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 12,
                  height: 1.4,
                ),
              ),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      );
    },
  );
}
