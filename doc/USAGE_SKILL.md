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

## Choose when to persist

| Use case | API |
| --- | --- |
| Save the whole session delta when the popup closes | `onClose` |
| Save each accepted delta as it happens | `onChange` |
| Validate a proposed change | `canChangeSelection` |
| Nested sublist membership | `SubPickerTile` + `onChange` / `onClose` |
| Bulk user intent in a custom header | Picker controller selection methods |
| Copy an already-persisted change into the open picker's checkboxes | `controller.syncPending(...)` |

There is no replace-all close callback. Persist `added` and `removed`.
`initialSelectedIds` is only the seed for the next open, from your selected
IDs.

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
  onClose: (result) async {
    await api.addPeople(result.added);
    await api.removePeople(result.removed);
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

## Observables

The picker notifies; it does not persist. Save from `onChange` (each accepted
toggle) or `onClose` (whole delta of session). Bulk header commands also go
through `onChange`.

`canChangeSelection` only accepts or rejects a proposed change. Checkboxes
update after that gate succeeds. Persist from IDs, not from loaded items.
Presence of `canChangeSelection` does not change `onChange` or `onClose`.
Handle persistence errors in application code; a thrown observer does not
roll back selection. `viewOnClose` is the overlay lifecycle callback, not
the selection result.

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
  update that authoritative state separately. No `onChange` or `onClose` delta
  is created because this method only mirrors a change that was already persisted. If the
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
    menuOffset: const Offset(30, 12),
    onClose: (result) async {
      await directoryApi.add(result.added);
      await directoryApi.remove(result.removed);
    },
  ),
];
```

Sub-list membership and parent selection are independent by default. Supplying
`parentController` alone does not change that. Opt in when child changes should
update the open parent's checkboxes:

```dart
SubPickerTile<Person>(
  parentController: controller,
  parentSelectionEffect: SubPickerParentSelectionEffect.deselectRemoved,
  // title, config, initialSelectedIds, and onChange/onClose...
)
```

Choose `selectAdded` to check additions, `deselectRemoved` to uncheck removals,
or `mirror` to do both. `none` is the default. These effects only change the
open parent's pending checkboxes. They do not persist parent selection, change
the parent's `initialSelectedIds`, or create a parent `onChange` / `onClose`
delta. If parent selection and sub-list membership are separate backend
records, the child's `onChange` or `onClose` callback must save both changes
and update the authoritative parent IDs for the next open. The package updates
open parent checkboxes without a full reseed after each accepted child
selection change, including bulk header commands. `canChangeSelection` is only
a gate. Rejected, blocked, or cancelled changes never synchronize.

## Related-list status

`PickerRelatedListItemStatus` describes related-list membership and unselect policy
without changing selection. The related list may be a parent or an auxiliary
sub-list. Use `relatedListItemStatusOf` to supply it and
`relatedListItemStatusListenable` to refresh it while open.

```dart
PickerConfig<Person>(
  relatedListItemStatusListenable: directoryMembership,
  relatedListItemStatusOf: (person) => PickerRelatedListItemStatus(
    auxiliaryMembership: directoryMembership.value.contains(person.id)
        ? PickerAuxiliaryMembership.member
        : allDirectoryMembershipIdsLoaded
            ? PickerAuxiliaryMembership.notMember
            : PickerAuxiliaryMembership.unknown,
    unselectPolicy: person.isInUse
        ? PickerUnselectPolicy.blocked
        : PickerUnselectPolicy.allow,
  ),
  // data adapters...
)
```

- `auxiliaryMembership` describes another list, never the current checkbox.
- `member` means known present, `notMember` means known absent, and `unknown`
  means the available server data cannot determine membership.
- An authoritative per-item membership flag can return `member` or `notMember`
  without loading the whole list. Absence from a partial result is unknown;
  finishing one page does not prove absence from the entire list.
- The default icons are filled, outlined, and search-marked person icons. A
  configured `iconOf` takes precedence.
- `allow` permits unselection, `blocked` keeps selection and shows a localized
  warning, and `confirm` asks for localized confirmation.
- `relatedListItemStatusListenable` redraws an open picker without reloading items.
  It is not subscribed while the picker is closed.
- Custom warning and confirmation UX belongs in `unselectWarningBuilder` and
  `unselectConfirmationBuilder`.

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

`itemBuilder` receives `(context, item, isSelected, relatedListItemStatus, toggle)`.
Read `relatedListItemStatus.auxiliaryMembership` and `relatedListItemStatus.unselectPolicy`
to customize the row; do not call `relatedListItemStatusOf` again. The supplied
`toggle` retains the core unselect policy.

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
