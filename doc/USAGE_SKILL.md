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
| Nested sublist membership | `SubPickerTile` + `onChange` / `onClose` |
| Bulk user intent in a custom header | Picker controller selection methods |
| Copy an already-persisted change into the open picker's checkboxes | `controller.syncPending(...)` |

Both may be set. `onChange` does not consume session intent, so `onClose`
still reports the same net. Persist in only one of them. `onChange` fires on
every accepted mutation (select then deselect is two calls). `onClose` nets
against the seed captured at open (select then deselect is omitted; empty means
do not write). A later `initialSelectedIds` change reseeds checkboxes only.


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
  not create `added` or `removed` intent and does not change the close
  baseline (the seed at open).
- Hidden selected IDs remain selected during server-side search and pagination.
- Persist `added` and `removed` from `onClose`. 

## Observables

The picker notifies; it does not persist.

`onChange` is the immediate save, run on each accepted delta once the
checkboxes moved; a thrown error restores them. Toggling the same ID on and
off is two calls. `onClose` is the deferred save, run on the net of the
session versus the seed captured at open while the overlay stays open; select then
deselect is omitted, and an empty delta means do not write. A thrown error is
reported and the user is asked whether to update the selection or close
without saving. Override with `closeSavingBuilder` and
`closeSaveFailedBuilder`. Save from IDs, not from loaded items. `viewOnClose`
is the overlay lifecycle callback, not the selection result.

Both may be set. `onChange` does not consume session intent, so `onClose`
still reports the same net. If both persist, the API is called for each
mutation and again at close. Persist in only one of them.

Block or confirm unselect with `relatedListItemStatusOf` /
`PickerUnselectPolicy`. A blocked or cancelled unselect never moves the
checkbox and never runs `onChange`. Throw from `onChange` to restore a
checkbox after a failed write.

A bulk command is an ordinary mutation with a bigger delta. Save the delta in
one write: a save that loops the IDs turns one Select-all tap into a request
per ID.

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
- A bulk command reaches `onChange` as one delta over every affected ID, not
  one delta per row, so write it as a single request.
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
open parent checkboxes without a full reseed after each successful child
`onChange`, including bulk header commands. Rejected, blocked, cancelled, or
thrown-`onChange` changes never synchronize.

## Related-list status

**Default behaviour.** Rows do not show membership in another list. Unselect is
allowed. Membership never checks or unchecks the current picker.

**What you may need to change.** Show that an item is in a parent list or
auxiliary sub-list. Block or confirm unselect when it is still in use. Refresh
that status while open without reloading items. This does not fire `onChange`
or `onClose` on the related picker, so APIs you hooked there will not run. If
you need them, handle that here.

**How.** Supply `relatedListItemStatusOf` and, if the status can change while
open, `relatedListItemStatusListenable`.

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

- `auxiliaryMembership` is display only: `member`, `notMember`, or `unknown`.
- Absence from a partial result is `unknown`. An item flag can return
  `member` or `notMember` without loading the whole list. `unknown` is only
  the icon. `onChange` / `onClose` do not receive this status; re-check from
  IDs there if needed, then update the directory source so the listenable force widget to
  redraws.
- Default icons are filled, outlined, and search-marked person icons. `iconOf`
  takes precedence.
- `allow` unselects, `blocked` keeps selection and shows a warning, `confirm`
  asks first. Replace the default warning and confirmation UI with
  `unselectWarningBuilder` and `unselectConfirmationBuilder`.
- `relatedListItemStatusListenable` redraws while open and does not call
  `loadItems`. It is not subscribed while closed.

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

Omitting `triggerBuilder` keeps the compact search icon. For an outlined field
with selected chips, use `DefaultPickerFieldTrigger` from `triggerBuilder`.
Tapping the field, a chip, or Add / Change opens the picker. Chip delete calls
`onDeleted` and is not a picker-session delta; persist it yourself. Use
`showChips: false` to hide chips. Multi-select labels the button Add; single
modes label it Change.

```dart
triggerBuilder: (context, open, _) => DefaultPickerFieldTrigger<int>(
  selectedIds: selectedIds,
  labelOf: (id) => names[id] ?? '#$id',
  onOpen: open,
  onDeleted: selectedIds.remove,
),
```

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
