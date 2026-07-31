# Generic Search Selector

A Flutter Material 3 picker that feels like `SearchAnchor`, with multi-select,
radio selection, stable selected-first ordering, and optional nested menus.

[Open the web example](https://alexqwesa.github.io/generic_search_selector/)

## Features

- SearchAnchor-compatible popup styling and `SearchViewTheme` support.
- Anchored desktop popups and full-screen mobile views by default.
- Multi-select, radio, and radio-toggle modes.
- Nested `SubPickerTile` menus with optional animated offsets.
- Safe client-side and server-side search: missing loaded items are never
  interpreted as deleted selections.
- Delta persistence through `onFinish(added:, removed:)`.
- Optional builders for every visual region; built-in widgets are only defaults.
- No permanent trigger `GlobalKey`; popup resources are created on demand.

## Installation

```yaml
dependencies:
  generic_search_selector: ^0.0.3
```

To use the Git repository directly:

```yaml
dependencies:
  generic_search_selector:
    git:
      url: https://github.com/Alexqwesa/generic_search_selector.git
      ref: v0.0.3
```

## Basic picker

```dart
final selectedIds = <int>{};

SearchAnchorPicker<Person>(
  config: PickerConfig<Person>(
    title: 'Pick people',
    loadItems: (_) => api.searchPeople(),
    idOf: (person) => person.id,
    labelOf: (person) => person.name,
    searchTermsOf: (person) => [person.name, person.email],
  ),
  initialSelectedIds: selectedIds.toList(),
  onFinish: ({required added, required removed}) async {
    await api.addPeople(added);
    await api.removePeople(removed);
  },
  triggerBuilder: (context, open, version) => IconButton(
    tooltip: 'Pick people',
    onPressed: open,
    icon: const Icon(Icons.person_search),
  ),
);
```

`initialSelectedIds` is the external source of truth for the next open. While a
picker is open, explicit row toggles are tracked independently so `onFinish`
reports only actual user add/remove intent.

## SearchAnchor styling

The default view resolves values in the same order as Flutter `SearchAnchor`:

1. Explicit picker parameter.
2. `ThemeData.searchViewTheme` / `SearchViewTheme`.
3. Material 3 SearchAnchor defaults.

```dart
SearchAnchorPicker<Person>(
  config: config,
  initialSelectedIds: selectedIds,
  viewHintText: 'Search people',
  viewConstraints: const BoxConstraints(
    minWidth: 420,
    minHeight: 260,
    maxHeight: 560,
  ),
  viewShape: RoundedRectangleBorder(
    borderRadius: BorderRadius.circular(20),
  ),
  viewBackgroundColor: Theme.of(context).colorScheme.surfaceContainerHigh,
);
```

Supported SearchAnchor-style options include `isFullScreen`, `viewLeading`,
`viewTrailing`, `viewHintText`, surface colors, elevation, side, shape, bar
padding, header styles, divider color, constraints, view padding, `shrinkWrap`,
keyboard configuration, and open/close/change/submit callbacks.

On Android, iOS, and Fuchsia the default view is full screen. Desktop platforms
use an anchored popup. Set `isFullScreen` explicitly to override this behavior.
`menuOffset` only applies to anchored popups and is ignored in full-screen mode.

## Optional default widgets

The core owns search state, selection, popup placement, focus, keyboard handling,
and lifecycle. Visual defaults live under `lib/src/widgets/` and are exported by
both the main package and `package:generic_search_selector/widgets.dart`.

Use focused builders to replace only the region you own:

- `triggerBuilder`, `headerBuilder`, and `itemBuilder`
- `searchFieldBuilder` and `resultsBuilder`
- `loadingBuilder`, `emptyBuilder`, and `errorBuilder`
- `saveEmptyBuilder`, `viewBuilder`, and `viewSurfaceBuilder`

For example, a custom error region still uses the core retry lifecycle:

```dart
errorBuilder: (context, error, stackTrace, retry) => Center(
  child: FilledButton.icon(
    onPressed: retry,
    icon: const Icon(Icons.refresh),
    label: const Text('Try again'),
  ),
),
```

The default widgets are not built while the popup is closed.

## Nested pickers

`SubPickerTile` is an optional convenience widget for sublist membership:

```dart
headerBuilder: (context, actions, items) => [
  SubPickerTile<Person>(
    title: 'Manage directory membership',
    config: directoryConfig,
    parentActions: actions,
    initialSelectedIds: directoryIds,
    menuOffset: const Offset(30, 12),
    onFinish: ({required added, required removed}) async {
      await directoryApi.add(added);
      await directoryApi.remove(removed);
    },
  ),
],
```

Sub-picker removals are removed from the parent pending selection when
`parentActions` is provided. Additions enter the parent list unselected.

## Server-side search safety

`loadItems` is display/search data, not deletion truth. A selected ID that is
missing from the current result remains selected.

Use pending-only header helpers when changing only the in-popup state:

- `pendingClearLoaded()` / `pendingSelectLoaded()`
- `pendingClearFiltered()` / `pendingSelectFiltered()`

Use explicit delta helpers when a bulk action should be persisted as user intent:

- `clearLoadedAsDelta()` / `selectLoadedAsDelta()`
- `clearFilteredAsDelta()` / `selectFilteredAsDelta()`
- `toggleIdAsDelta(id, selected)`

Bulk helpers affect only the current loaded result. Hidden server-side selections
are untouched.

## Persistence APIs

Prefer `onFinish(added:, removed:)` for save-on-close APIs, or `onToggle` for
per-row persistence. `OnToggleMode.optimistic` updates a checkbox immediately and
rolls it back if the async callback returns `false`.

`onFinishReplaceAll(finalIds)` is deprecated. A full pending snapshot cannot prove
that IDs missing from a partial server result were deleted, so replacing backend
state wholesale can remove valid hidden selections. Existing callers continue to
work, and empty replacement still requires the explicit save-empty action.

## License

MIT
