import 'package:flutter/material.dart';
import 'package:search_anchor_picker/search_anchor_picker.dart';

import 'example_card.dart';
import 'people.dart';

/// Default search field reloads [PickerConfig.itemsLoader] with `query`.
class ServerSearchCard extends StatefulWidget {
  const ServerSearchCard({super.key});

  @override
  State<ServerSearchCard> createState() => _ServerSearchCardState();
}

class _ServerSearchCardState extends State<ServerSearchCard> {
  final Set<int> _selected = {1};
  String _lastRequest = 'GET /people?page=1';
  String _lastResult =
      'Ada Lovelace, Alan Turing, Grace Hopper, Katherine Johnson';

  @override
  Widget build(BuildContext context) {
    return ExampleCard(
      title: 'Server search, default search field',
      persist: 'onClose',
      difference:
          'searchMode: remote. itemsLoader is the search callback: the picker passes the box text as query and shows that page as-is. No second local filter, so a fuzzy or extra-field server hit is not hidden by searchTermsOf.\n\n'
          'Open: GET /people?page=1 → Ada … Katherine. Type lin:\n\n'
          'GET /people?q=lin\n'
          '→ Linus Torvalds\n\n'
          'Ada’s chip stays while she is missing from that page. initialSelectedItemCache also keeps her as a Selected row so you can uncheck her without clearing the query. The footer is the last request and the people the fake server returned.',
      // source:server-search-default-search-field
// final debounce = Debouncer();
// 
// Future<List<Person>> searchPeople(String query) {
//   if (query.isEmpty) return api.searchPeople(query);
//   return debounce.run(() => api.searchPeople(query));
// }
// 
// SearchAnchorPicker<Person>(
//   initialSelectedIds: selected.toList(),
//   initialSelectedItemCache: cachedPeople,
//   onClose: (result) { /* persist result.added / result.removed */ },
// );
// 
// PickerConfig(
//   searchMode: PickerSearchMode.remote,
//   itemsLoader: (context, query) => searchPeople(query),
// );
// source-end:server-search-default-search-field
        sourceTag: 'server-search-default-search-field',
      footer: Text(
        '$_lastRequest\n→ $_lastResult',
        style: Theme.of(
          context,
        ).textTheme.bodySmall?.copyWith(fontFamily: 'monospace', height: 1.4),
      ),
      child: SearchAnchorPicker<Person>(
        config: peopleConfig(
          title: 'Server search, default search field',
          itemsLoader: _loadPage,
          searchMode: PickerSearchMode.remote,
        ),
        initialSelectedIds: _selected.toList(),
        initialSelectedItemCache: peopleIn(_selected),
        isFullScreen: false,
        viewHintText: 'Search people',
        viewConstraints: popupConstraints,
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

  /// Fake GET /people. Invoked by the picker as [PickerConfig.itemsLoader]
  /// on open and whenever the default search field text changes.
  Future<List<Person>> _loadPage(BuildContext context, String query) async {
    final trimmed = query.trim();
    final request = trimmed.isEmpty
        ? 'GET /people?page=1'
        : 'GET /people?q=${Uri.encodeQueryComponent(trimmed)}';
    await Future<void>.delayed(const Duration(milliseconds: 250));
    final results = trimmed.isEmpty
        ? people.take(4).toList()
        : people.where((person) {
            final needle = trimmed.toLowerCase();
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
