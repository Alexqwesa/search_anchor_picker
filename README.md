# Search Anchor Picker

A Flutter Material 3 picker that feels like `SearchAnchor`, with multi-select,
single selection, and optional nested menus.

[Open the web example](https://alexqwesa.github.io/search_anchor_picker/)

## Features

- SearchAnchor-compatible popup styling and `SearchViewTheme` support.
- Anchored desktop popups and full-screen mobile views by default.
- Multi, single, and single-optional selection modes.
- Nested `SubPickerTile` menus with optional animated offsets.
- Optional selected-first ordering, frozen at open so toggles do not reshuffle
  the list. Default is on (`selectedFirst: true`).
- Safe client-side and server-side search: missing loaded items are never
  interpreted as deleted selections.
- The picker notifies; it does not persist. Save from `onChange` (each accepted
  toggle) or `onClose` (whole delta of session).
- Optional `PickerUnselectPolicy` (allow / blocked / confirm) per row via
  `relatedListItemStatusOf`.
- Optional builders for every visual region; built-in widgets are only defaults.
- No permanent trigger `GlobalKey`; popup resources are created on demand.

## Installation

```yaml
dependencies:
  search_anchor_picker: ^0.2.0
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
  onClose: (result) async {
    await api.addPeople(result.added);
    await api.removePeople(result.removed);
  },
  triggerBuilder: (context, open, version) => IconButton(
    tooltip: 'Pick people',
    onPressed: open,
    icon: const Icon(Icons.person_search),
  ),
);
```

`initialSelectedIds` is the external source of truth for the next open. While a
picker is open, explicit row toggles are tracked independently so `onClose`
observes only actual user add/remove intent. If `onClose` throws, the popup
stays open: a localized saving wrap is shown, then a prompt offers update
selection or close without saving.

## Reloading items

Creating a new inline `PickerConfig(...)` during a parent rebuild does not
reload an open picker. Configuration changes are rebound without treating object
identity as a data revision.

Reload deliberately through one of these paths:

- Call `controller.refresh()` from custom popup UI.
- Provide `config.listenable`; notifications reload only while the popup is open.
- Change `config.reloadKey` for declarative revision-based reloads.

```dart
PickerConfig<Person>(
  reloadKey: resultsRevision,
  listenable: repository.changes,
  loadItems: (_) => repository.search(),
  idOf: (person) => person.id,
  labelOf: (person) => person.name,
  searchTermsOf: (person) => [person.name],
);
```

A closed picker never subscribes or reloads. Its next open always calls the
latest `loadItems` once.

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
Anchored popups close when the user taps outside; a full-screen view has no
outside area, so its default search field always provides a localized back
button. Supplying `viewLeading` replaces that button, and a custom
`searchFieldBuilder` replaces the whole field; custom versions must expose the
provided `close` callback when users otherwise have no visible way to leave.

## Optional default widgets

The core owns search state, selection, popup placement, focus, keyboard handling,
and lifecycle. Visual defaults are exported by both the main package and
`package:search_anchor_picker/widgets.dart`.

Use focused builders to replace only the region you own:

- `triggerBuilder`, `headerBuilder`, and `itemBuilder`
- `searchFieldBuilder` and `resultsBuilder`
- `loadingBuilder`, `emptyBuilder`, and `errorBuilder`
- `viewBuilder` and `viewSurfaceBuilder`

Omitting `triggerBuilder` keeps the compact search icon. For a Material text
field with selected chips, pass `DefaultPickerFieldTrigger`:

```dart
SearchAnchorPicker<Person>(
  config: config,
  initialSelectedIds: selectedIds.toList(),
  onClose: (result) async {
    await api.addPeople(result.added);
    await api.removePeople(result.removed);
  },
  triggerBuilder: (context, open, _) => DefaultPickerFieldTrigger<int>(
    selectedIds: selectedIds,
    labelOf: (id) => names[id] ?? '#$id',
    onOpen: open,
    onDeleted: (id) => selectedIds.remove(id),
    selectionMode: SelectionMode.multi,
  ),
);
```

Tapping the field, a chip, or Add / Change opens the picker. Add is used for
multi-select; Change is used for `single` and `singleOptional`. Chip delete
icons call `onDeleted` and do not open the popup. That write is outside the
picker session, so persist it yourself if you also save from `onChange` or
`onClose`. Set `showChips: false` to keep the outlined field and button without
listing selected IDs.

`itemBuilder` receives `(context, item, isSelected, relatedListItemStatus, toggle)`.
The `relatedListItemStatus` comes from `config.relatedListItemStatusOf`, so custom rows
can use both `auxiliaryMembership` and `unselectPolicy` without recomputing them.
Calling `toggle` still uses the picker's unselect policy and selection logic.

The default empty view localizes “No items” and “No results” for several common
languages using the app's current locale. Set `emptyText` / `noResultsText` to
provide application wording, or use `emptyBuilder` to replace the region.
Default retry and unselect warning/confirmation text uses the same locale set;
Flutter `MaterialLocalizations` supplies back, clear, search, and cancel labels.

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

The default popup widgets are not built while the popup is closed.

## Related-list status and sub-list membership

**Default behaviour.** Rows do not show membership in another list. Unselect is
allowed. The checkbox is only this picker's selection: a checked item is not
assumed to belong to a directory or parent list, and membership never checks
or unchecks the row.

**What you may need to change.** Show that an item is in another list. Block or
confirm unselect when it is still in use. Keep that status current while the
popup is open, without reloading search results. This does not fire `onChange`
or `onClose` on the related picker, so APIs you hooked there will not run. If
you need them, handle that here.

**How.** Return a `PickerRelatedListItemStatus` from `relatedListItemStatusOf`.
`auxiliaryMembership` is display only: `member`, `notMember`, or `unknown`.
The default row uses a filled, outlined, or search-marked person icon. A
custom `iconOf` replaces those icons. `unselectPolicy` is `allow`, `blocked`
(keep selected, show an in-use warning), or `confirm`. Replace the default
warning and confirmation UI with `unselectWarningBuilder` and
`unselectConfirmationBuilder`.

Use `unknown` when a paged or filtered result cannot prove absence. If the
item has an authoritative flag such as `isInDirectory`, return `member` or
`notMember` even when the list is paginated. Missing from one page is not
`notMember`. `unknown` is only the icon; it does not block unselect.
`onChange` / `onClose` do not receive this status. If you need a fresh
membership or in-use check, do it there from the IDs, then update the
directory source so `relatedListItemStatusListenable` redraws.

`relatedListItemStatusListenable` redraws this status while the popup is open
and does not call `loadItems`. Parent checkbox coupling is a separate
`SubPickerParentSelectionEffect` on `SubPickerTile`.

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
  // loadItems, idOf, labelOf, and searchTermsOf...
),
```

## Nested pickers

`SubPickerTile` is an optional convenience widget for sublist membership:

```dart
headerBuilder: (context, controller, items) => [
  SubPickerTile<Person>(
    title: 'Manage directory membership',
    config: directoryConfig,
    initialSelectedIds: directoryIds,
    menuOffset: const Offset(30, 12),
    onClose: (result) async {
      await directoryApi.add(result.added);
      await directoryApi.remove(result.removed);
    },
  ),
],
```

Sub-list membership does not change parent selection by default. Opt in when
child changes should update the open parent's checkboxes:

```dart
SubPickerTile<Person>(
  parentController: controller,
  parentSelectionEffect: SubPickerParentSelectionEffect.deselectRemoved,
  // title, config, initialSelectedIds, and onChange/onClose...
)
```

Choose `selectAdded` to check added items, `deselectRemoved` to uncheck removed
items, or `mirror` for both. `none` is the default.
These effects **only update the open parent's checkboxes**. They do not save
parent selection, update the parent's `initialSelectedIds`, or include those
changes in the parent's `onChange` / `onClose` deltas.
If your backend stores parent selection separately from sub-list membership,
the child's `onChange` or `onClose` callback must also call the appropriate
parent API and update the authoritative parent IDs for the next open. Parent
checkbox updates do not require reseeding the whole parent picker.

The picker notifies; it does not persist. Save from `onChange` (each accepted
toggle) or `onClose` (whole delta of session). Parent checkboxes follow accepted
child selection changes, including bulk header commands.

```dart
onChange: (delta) async {
  await directoryApi.add(delta.added);
  await directoryApi.remove(delta.removed);
},
onClose: (result) {
  // Optional: whole delta of the session.
},
```

Blocked, cancelled, or thrown-`onChange` changes never update the parent.
Closing waits for in-flight `onChange` work to settle.
`viewOnClose` remains the overlay-lifecycle callback.

## Server-side search safety

`loadItems` is display/search data, not deletion truth. A selected ID that is
missing from the current result remains selected.

Header selection helpers record explicit persistence intent:

- `clearLoaded()` / `selectLoaded()`
- `clearFiltered()` / `selectFiltered()`
- `setSelected(id, selected)`

Bulk helpers affect only the current loaded result. Hidden server-side selections
are untouched. Each command reports one delta, the same way a row toggle
reports one.

Use `syncPending(added:, removed:)` to apply an already-persisted external delta
to the currently open picker's temporary pending set. It processes additions
and removals symmetrically, but does not mutate `initialSelectedIds` or caller
state and does not report the change again through `onChange` or `onClose`. The caller must
update its authoritative selected IDs separately.

## Persistence

The picker notifies; it does not persist.

`onChange` is the immediate save: each accepted delta, right after the
checkboxes move. A thrown `onChange` error restores them. Toggling the same
ID on and off is two `onChange` calls. `onClose` is the deferred save: the
net of the session versus the seed captured at open, saved while the overlay stays
open. Select then deselect the same ID any number of times and it is omitted;
an empty delta means do not write. A thrown `onClose` error is reported and
the user is asked whether to update the selection or close without saving.
Default strings are localized; override the saving wrap with
`closeSavingBuilder`, the prompt with `closeSaveFailedBuilder`.

Both may be set. `onChange` does not consume session intent, so `onClose`
still reports the same net. If both persist, the API is called for each
mutation and again at close. Persist in only one of them. A later
`initialSelectedIds` update reseeds checkboxes; it does not change the close
baseline.

Block or confirm unselect with `relatedListItemStatusOf` /
`PickerUnselectPolicy`. A blocked or cancelled unselect never moves the
checkbox and never runs `onChange`. Throw from `onChange` to restore a
checkbox after a failed write.

Bulk header commands are ordinary mutations: one delta.
Save that delta as a single write. A save that loops the IDs turns one
Select-all tap into a request per person, which is a property of the save, not
of the command. `onClose` avoids the question, because a whole session
collapses into one net delta.

Persist `added` and `removed`, applied to the seed you already hold. A load
error or empty search is not a deletion.
`initialSelectedIds` is only the seed for the next open, from your selected
IDs.

## License

MIT
