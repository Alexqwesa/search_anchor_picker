# Generic Search Selector

A small Flutter library that turns Material 3 `SearchAnchor` into a reusable
picker widget with selection state, optional nested “sub-pickers”, and a clean
configuration surface.

It is designed for cases where you need:

- A searchable list picker (multi or radio selection)
- “Selected first” ordering and stable ordering
- Custom header content (actions, nested pickers, filters, etc.)
- A simple API that hides overlay / lifecycle gotchas

Online demo:
- Example app (web): https://alexqwesa.github.io/generic_search_selector/

Technical deep dive:
- See `technical_overview.md` for architecture, lifecycle edge cases,
  and why some fixes exist (dynamic keys, PostFrameCallback, etc.).

Agents & integrators:
- See [`docs/AGENTS.md`](docs/AGENTS.md) for pattern choice (sublist vs main list),
  async pitfalls, and `initialSelectedIds` behavior.
- Changelog: [`CHANGELOG.md`](CHANGELOG.md)

## Features

- `SearchAnchorPicker<T>`: drop-in picker built on Flutter Material 3
- Two selection modes:
  - `PickerMode.multi` (checkbox style)
  - `PickerMode.radio` (single select)
- Fully generic item type `T` via `PickerConfig<T>`
- Header builder with `PickerActions` for advanced scenarios:
  - Clear selection
  - Sync selection with external state
  - Nested sub-pickers (optional)
- Works with any state management approach:
  - `setState`
  - `ValueNotifier`
  - Riverpod, Provider, BLoC, etc.


## Installation

**pub.dev** (after first publish):

```yaml
dependencies:
  generic_search_selector: ^0.0.3
```

**Git** (pin a semver tag — prefer `v0.0.x`, not bare `v15`):

```yaml
dependencies:
  generic_search_selector:
    git:
      url: https://github.com/Alexqwesa/generic_search_selector.git
      ref: v0.0.3
```

Publishing: push a tag that matches `pubspec.yaml` `version` (e.g. `0.0.3` → `v0.0.3`). See `.github/workflows/publish.yml`.


## Quick example

Minimal multi-select with local state.
(Works the same with Riverpod/Bloc/etc — just update your state in onToggle.)

Use `triggerBuilder` for opening the picker so the trigger can react to picker version changes.

```dart
import 'package:flutter/material.dart';
import 'package:generic_search_selector/generic_search_selector.dart';

class Person {
  Person(this.id, this.name);
  final int id;
  final String name;
}

class PeoplePickerDemo extends StatefulWidget {
  const PeoplePickerDemo({super.key});

  @override
  State<PeoplePickerDemo> createState() => _PeoplePickerDemoState();
}

class _PeoplePickerDemoState extends State<PeoplePickerDemo> {
  final _items = <Person>[
    Person(1, 'Alice'),
    Person(2, 'Bob'),
    Person(3, 'Charlie'),
  ];

  final _selectedIds = <int>{};

  late final PickerConfig<Person> _config = PickerConfig<Person>(
    title: 'Pick people',
    loadItems: (_) async => _items,
    idOf: (p) => p.id,
    labelOf: (p) => p.name,
    searchTermsOf: (p) => [p.name, p.id.toString()],
    selectedFirst: true,
  );

  @override
  Widget build(BuildContext context) {
    return SearchAnchorPicker<Person>(
      config: _config,
      mode: PickerMode.multi,
      initialSelectedIds: _selectedIds.toList()..sort(),
      onToggle: (item, next) async {
        setState(() {
          next ? _selectedIds.add(item.id) : _selectedIds.remove(item.id);
        });
        return true;
      },
      triggerBuilder: (_, open, __) => IconButton(
        tooltip: 'Open picker',
        onPressed: open,
        icon: const Icon(Icons.person_search),
      ),
      maxHeight: 420,
      minWidth: 320,
    );
  }
}
```

## Nested Pickers

You can use your own `SearchAnchorPicker` for nested pickers, or use the `SubPickerTile` helper in `headerBuilder` to create them easily (e.g., for filtering or adding items from another source).

It handles synchronization with the parent picker:
*   **Removals**: If items are removed in the sub-picker, they are automatically removed from the parent's pending selection.
*   **Additions**: Added items are **NOT** automatically selected in the parent (defaulting to "unselected"), giving you control.
*   **Popup positioning**: Use `menuOffset` to shift the nested popup relative to its trigger, and `menuOffsetAnimationDuration` to control how quickly that offset animates in.
*   **Scalability**: Closed pickers do not keep a permanent trigger `GlobalKey`; popup-only keys are created on demand and cleared when the popup closes.

```dart
SubPickerTile<MyItem>(
  title: 'Add from Sub-list',
  config: subConfig,
  parentActions: actions, // Pass parent actions to automate removal cleanup
  initialSelectedIds: currentSubIds,
  menuOffset: const Offset(40, 12), // from trigger position
  menuOffsetAnimationDuration: const Duration(milliseconds: 120),
  onFinish: ({required added, required removed}) async {
      // 1. Update your data model (e.g. repository) — save-on-close
      await myRepo.add(added);
      await myRepo.remove(removed);
      
      // 2. Pending selection cleanup (removals) is handled automatically!
  }
)
```

**Save-on-close (default):** `SubPickerTile` updates checkboxes while the sub-popup is open and calls `onFinish` once when it closes. That is the library-intended flow for sublist membership.

**Save-on-each-click:** not the default for `SubPickerTile`. Use a nested `SearchAnchorPicker` with `onToggle` (see below) or `OnToggleMode.optimistic`.

## Save-on-close APIs

There are two close callbacks:

```dart
SearchAnchorPicker<Person>(
  config: config,
  initialSelectedIds: selectedIds,

  // Delta save: only user row check/uncheck actions.
  onFinish: ({required added, required removed}) async {
    await api.addMemberships(added);
    await api.removeMemberships(removed);
  },

  // Replace-all save: the full final selection.
  onFinishReplaceAll: (finalIds) async {
    await api.replaceSelection(finalIds);
  },
);
```

Use `onFinish` for normal add/remove APIs. Use `onFinishReplaceAll` only when your backend expects the whole final selection.

If `onFinishReplaceAll` is configured and the final selection is empty, the picker does not save empty on close by default. It shows a confirmation button labeled `Save empty`; customize it with `saveEmptyLabel`, or disable empty replace-all saves with `showSaveEmptyButton: false`.

## Async `onToggle`

By default (`OnToggleMode.awaitGate`), the picker **waits** for `onToggle` before moving the checkbox. A slow `await` (network, DB) freezes the UI until the future completes.

Use **`OnToggleMode.optimistic`** when you want immediate checkbox feedback and background persistence (failed saves revert the toggle):

```dart
SearchAnchorPicker<Person>(
  config: config,
  initialSelectedIds: selectedIds,
  onToggleMode: OnToggleMode.optimistic,
  onToggle: (person, next) async {
    try {
      await api.setSelected(person.id, next);
      return true;
    } catch (_) {
      return false; // reverts checkbox
    }
  },
  triggerBuilder: (_, open, __) => IconButton(onPressed: open, icon: const Icon(Icons.people)),
);
```

| Mode | Checkbox | `onToggle` |
|------|----------|------------|
| `awaitGate` (default) | After `onToggle` returns `true` | Awaited first; return `false` to reject |
| `optimistic` | Immediately (multi mode) | Runs in background; `false` reverts |

For **validation** (max items, permissions), keep **`awaitGate`** and return `false` to block the change.

Use `SubPickerTile` for nested sublist membership and `onToggle` or root `onFinish` for main-list assignment. `initialSelectedIds` is the caller-owned selection state, independent from the current search page. Server-side filtering is supported: a selected ID missing from `loadItems` is preserved, and `onFinish` only reports IDs the user checked or unchecked from item rows. Safe bulk header actions like `actions.pendingClearLoaded()` update pending selection without producing add/delete deltas; use `*AsDelta()` helpers for explicit bulk add/remove intent.

## Client-side vs server-side item loading

`loadItems` is display/search data, not deletion truth. If a selected ID is missing from the current result, the picker keeps it selected.

This makes both full client-side lists and server-side search/pagination safe by default:

```dart
PickerConfig<Person>(
  loadItems: (_) => api.searchPeople(...), // full list or current page
  idOf: (p) => p.id,
  labelOf: (p) => p.name,
  searchTermsOf: (p) => [p.name],
);
```

Use `pendingClearLoaded()` / `pendingSelectLoaded()` for the current loaded result and `pendingClearFiltered()` / `pendingSelectFiltered()` for rows matching the current search query. These pending-only helpers do not populate `added` / `removed`, and hidden server-side selections stay pending unless they are in the current loaded result.

Use explicit delta helpers when a header button is meant to behave like add/remove intent: `clearLoadedAsDelta()`, `selectLoadedAsDelta()`, `clearFilteredAsDelta()`, `selectFilteredAsDelta()`, or `toggleIdAsDelta(id, next)`. Use `onFinishReplaceAll(finalIds)` when you want to save the whole selection as-is. Bulk helpers do not run row-level `unselectBehavior`; add your own confirmation in the header if bulk removal needs warnings.

Ideas backlog: [`docs/TODO.md`](docs/TODO.md)

## MIT License
