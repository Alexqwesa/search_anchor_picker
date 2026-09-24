import 'package:flutter/material.dart';

import 'example_source.dart';
import 'example_sources.g.dart';

class ExampleCard extends StatelessWidget {
  const ExampleCard({
    required this.title,
    required this.persist,
    required this.difference,
    required this.child,
    super.key,
    this.source = '',
    this.sourceTag,
    this.footer,
  });

  final String title;
  final String persist;
  final String difference;
  /// Fallback when [sourceTag] is null. Prefer a generated [sourceTag].
  final String source;

  /// Key in [exampleSources], produced by example_source_builder.
  final String? sourceTag;
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
                  onPressed: () => showExampleSource(
                    context,
                    title: title,
                    source: _resolvedSource(),
                  ),
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

  String _resolvedSource() {
    final tag = sourceTag;
    if (tag == null) return source;
    final generated = exampleSources[tag];
    if (generated == null) {
      throw StateError('No generated source for /*source:$tag*/');
    }
    return generated;
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
              child: SelectableText.rich(
                TextSpan(
                  style: const TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 12,
                    height: 1.4,
                  ),
                  children: [
                    for (final run in exampleSourceRuns(source))
                      TextSpan(
                        text: run.text,
                        style: run.bold
                            ? const TextStyle(fontWeight: FontWeight.w700)
                            : null,
                      ),
                  ],
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
