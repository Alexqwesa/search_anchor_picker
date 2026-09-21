import 'package:flutter/material.dart';
import 'package:search_anchor_picker/search_anchor_picker.dart';

import 'example_card.dart';
import 'people.dart';

/// Default search field + [SearchAnchorPicker.viewOnChanged] + [GenericPickerController.refresh].
///
/// No custom [SearchAnchorPicker.searchFieldBuilder] or view. Typing still
/// locally filters the loaded page; [refresh] replaces that page from the
/// fake server using the stored query.
class ServerSearchCard extends StatefulWidget {
  const ServerSearchCard({super.key});

  @override
  State<ServerSearchCard> createState() => _ServerSearchCardState();
}

class _ServerSearchCardState extends State<ServerSearchCard> {
  final Set<int> _selected = {1};
  String _query = '';
  String _lastRequest = 'GET /people?page=1';
  String _lastResult =
      'Ada Lovelace, Alan Turing, Grace Hopper, Katherine Johnson';
  GenericPickerController<Person, int>? _controller;

  @override
  Widget build(BuildContext context) {
    return ExampleCard(
      title: 'Server search, default search field',
      persist: 'onClose',
      difference:
          'The default box only filters the current loadItems page. loadItems does not receive the query. This card keeps query state, listens with viewOnChanged, and calls controller.refresh() — no searchFieldBuilder or viewBuilder.\n\n'
          'Open: page 1 is Ada … Katherine. Type lin without refresh and the list would be empty. After refresh:\n\n'
          'GET /people?q=lin\n'
          '→ Linus Torvalds\n\n'
          'Ada’s chip stays while she is missing from that page. Clear the box for page 1 again. The footer shows the last request and the IDs the fake server returned.',
      source: r'''
String query = '';
GenericPickerController<Person, int>? controller;

SearchAnchorPicker<Person>(
  viewOnChanged: (text) {
    query = text;
    // Asks the open picker to call config.loadItems again.
    controller?.refresh();
  },
  headerBuilder: (context, actions, items) {
    controller = actions;
    return const [];
  },
  config: peopleConfig(
    // The picker calls this: on open, on refresh(), and on reloadKey.
    loadItems: (_) async {
      // GET /people?q=$query  →  matching people
      return api.searchPeople(query);
    },
  ),
);
''',
      footer: Text(
        '$_lastRequest\n→ $_lastResult',
        style: Theme.of(
          context,
        ).textTheme.bodySmall?.copyWith(fontFamily: 'monospace', height: 1.4),
      ),
      child: SearchAnchorPicker<Person>(
        config: peopleConfig(
          title: 'Server search, default search field',
          // Picker-invoked: open, refresh(), or reloadKey. Not called by typing.
          loadItems: _loadPage,
        ),
        initialSelectedIds: _selected.toList(),
        isFullScreen: false,
        viewHintText: 'Search people',
        viewConstraints: popupConstraints,
        viewOnChanged: (text) {
          _query = text;
          setState(() {
            final query = text.trim();
            _lastRequest = query.isEmpty
                ? 'GET /people?page=1'
                : 'GET /people?q=${Uri.encodeQueryComponent(query)}';
          });
          // refresh() → picker._reload() → config.loadItems(_loadPage).
          _controller?.refresh();
        },
        headerBuilder: (context, controller, items) {
          _controller = controller;
          return const <Widget>[];
        },
        onClose: (result) {
          setState(() => applyDelta(_selected, result));
        },
        triggerBuilder: (context, open, _) => peopleFieldTrigger(
          open,
          _selected,
          onDeleted: (id) => setState(() => _selected.remove(id)),
        ),
      ),
    );
  }

  /// Fake `GET /people`. Invoked only by the picker (`loadItems`), never
  /// directly from [viewOnChanged].
  Future<List<Person>> _loadPage(BuildContext context) async {
    final query = _query.trim();
    final request = query.isEmpty
        ? 'GET /people?page=1'
        : 'GET /people?q=${Uri.encodeQueryComponent(query)}';
    await Future<void>.delayed(const Duration(milliseconds: 250));
    final results = query.isEmpty
        ? people.take(4).toList()
        : people.where((person) {
            final needle = query.toLowerCase();
            return person.name.toLowerCase().contains(needle) ||
                person.team.toLowerCase().contains(needle);
          }).toList();
    final resultLabel = results.isEmpty
        ? '(empty)'
        : namesOf({for (final person in results) person.id});
    if (context.mounted) {
      setState(() {
        _lastRequest = request;
        _lastResult = resultLabel;
      });
    }
    return results;
  }
}
