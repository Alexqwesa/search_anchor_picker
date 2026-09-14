---
name: search-anchor-picker
description: Integrate SearchAnchorPicker into a Flutter app, including server-side search, delta persistence, nested pickers, bulk controls, and visual customization.
---

# Search Anchor Picker Consumer Skill

Use this guide when adding or changing `search_anchor_picker` in a consumer
application. Import the primary API with:

```dart
import 'package:search_anchor_picker/search_anchor_picker.dart';
```

## Choose persistence first

| Use case | API |
| --- | --- |
| Save changes when the popup closes | `onFinish(added:, removed:)` |
| Persist or validate every row click | `onToggle` |
| Nested sublist membership | `SubPickerTile` + `onFinish` |
| Bulk user intent in a custom header | Picker controller selection methods |
| Copy an already-persisted change into the open picker's checkboxes | `controller.syncPending(...)` |

There is no replace-all close callback. Apply explicit deltas to backend or
application state. Use `initialSelectedIds` only from an authoritative selected
ID source.

## Basic integration

```dart
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
);
```

After persistence succeeds, update the parent's selected-ID state. That state
becomes the seed for the next open.

## Selection safety

Follow these invariants:

- `loadItems` is the current display/search result. It may be complete, paged,
  filtered, stale, empty while loading, or empty after an error.
- Absence from `loadItems` never means an ID was unselected or deleted.
- `initialSelectedIds` is external selection state, not a loading placeholder.
- Do not temporarily replace `initialSelectedIds` with an empty list while its
  real value is loading. Keep the previous authoritative value instead.
- An external `initialSelectedIds` update may reseed an open picker, but it does
  not create `added` or `removed` intent.
- Hidden selected IDs remain selected during server-side search and pagination.

## Row persistence

Use `onFinish` when changes should be batched until close. It reports only net
explicit changes made during that open session.

Use `onToggle` when each row needs immediate validation or persistence:

- `OnToggleMode.awaitGate` waits for the callback before changing the checkbox.
- `OnToggleMode.optimistic` changes immediately and rolls back when the callback
  returns `false`.

Handle persistence errors in application code and return `false` from
`onToggle` when the requested change must not remain selected.

## Item reloads

Do not rely on replacing an inline `PickerConfig(...)` to reload data. Parent
rebuilds rebind the latest configuration but intentionally do not call
`loadItems`.

Use one explicit reload signal:

- `controller.refresh()` for a command initiated by popup UI.
- `config.listenable` for repository/notifier-driven invalidation. It is
  subscribed only while the picker is open.
- `config.reloadKey` for declarative revisions. Changing its value while open
  reloads once; rebuilding with an equal value does not.

Closed pickers do not reload. Opening always invokes the latest configured
`loadItems`, and stale request completions cannot overwrite a newer result.

## Header controller

`headerBuilder` receives a `GenericPickerController<T, K>` containing pending
state and popup commands:

```dart
headerBuilder: (context, controller, items) => [
  TextButton(
    onPressed: controller.selectFiltered,
    child: const Text('Select results'),
  ),
  TextButton(
    onPressed: controller.clearFiltered,
    child: const Text('Clear results'),
  ),
];
```

- `selectLoaded()` and `clearLoaded()` affect all IDs in the current loaded
  result and record explicit deltas.
- `selectFiltered()` and `clearFiltered()` affect loaded IDs matching the current
  query and record explicit deltas. With an empty query, filtered equals loaded.
- `setSelected(id, selected)` changes one ID and records an explicit delta.
- `pendingIds` is an immutable snapshot; `pendingIdsListenable` supports reactive
  custom header UI.
- `refresh()` reloads items and `close()` closes the current popup.
- `getKey(id)` creates a popup-lifetime key for stateful header children. Do not
  retain the controller or its keys after close.
- `syncPending(added:, removed:)` applies both sides of an externally persisted
  delta to this controller's currently open picker: it adds `added` IDs to the
  temporary pending set and removes `removed` IDs from that set. It does not
  mutate `initialSelectedIds` or any parent/application state. The caller must
  update that authoritative state separately. No `onFinish` delta is created
  because this method only mirrors a change that was already persisted. If the
  same ID is supplied in both arguments, removal wins as conflict resolution.

Loaded and filtered commands never touch hidden server-side selections.

## Nested picker

Use `SubPickerTile` when a parent picker contains a secondary membership list:

```dart
headerBuilder: (context, controller, items) => [
  SubPickerTile<Person>(
    title: 'Directory membership',
    config: directoryConfig,
    initialSelectedIds: directoryIds,
    parentController: controller,
    menuOffset: const Offset(30, 12),
    onFinish: ({required added, required removed}) async {
      await directoryApi.add(added);
      await directoryApi.remove(removed);
    },
  ),
];
```

With `parentController`, `SubPickerTile` intentionally calls
`syncPending(removed: removed)` only. Removing membership in the child therefore
unchecks the same ID in the open parent picker without creating a duplicate
parent delta. Child additions are not forwarded because adding an item to the
child sublist should not automatically select it in the parent main list. This
asymmetry belongs to `SubPickerTile`, not to `syncPending` itself.

Desktop submenus may use `menuOffset`. Mobile defaults to a full-screen view;
set `isFullScreen` explicitly only when the application intentionally differs
from SearchAnchor behavior.

Anchored views may close from an outside tap. Full-screen views have no outside
area and use the default localized back button. If you provide `viewLeading`,
keep a visible control that closes the picker. If you replace the complete
search field with `searchFieldBuilder`, wire the builder's `close` callback into
your custom UI.

## Visual customization

Prefer explicit SearchAnchor-style properties or `SearchViewTheme` before
replacing widgets. Resolution order is explicit property, theme, then default.

Focused builders replace only their own region:

- `triggerBuilder`, `headerBuilder`, `itemBuilder`
- `searchFieldBuilder`, `resultsBuilder`
- `loadingBuilder`, `emptyBuilder`, `errorBuilder`
- `viewBuilder`, `viewSurfaceBuilder`

The default empty view uses built-in locale-aware “No items” and “No results”
messages. Prefer `emptyText` and `noResultsText` for wording-only overrides; use
`emptyBuilder` when the application needs a different layout or behavior.
Retry and default unselect feedback use the same locale resolver. Back, clear,
search, and cancel labels come from Flutter `MaterialLocalizations`.

Core popup placement, focus, keyboard handling, loading, and selection lifecycle
remain active when a visual builder is supplied. Default and convenience widgets
are also exported from `package:search_anchor_picker/widgets.dart`.

## Integration check

Before finishing a consumer change, verify:

- Closing and reopening uses the latest authoritative selected IDs.
- A partial or empty server response does not remove hidden selections.
- `added` and `removed` update application state independently.
- Rejected optimistic and awaited toggles leave correct checkbox state.
- Nested removals synchronize once and additions follow the intended parent UX.
- Loading, empty, error/retry, Escape/back, and mobile full-screen behavior work.
