# Search Anchor Picker

A Flutter Material 3 picker that feels like `SearchAnchor`, with multi-select,
single selection, stable selected-first ordering, and optional nested menus.

[Open the web example](https://alexqwesa.github.io/search_anchor_picker/)

## Features

- SearchAnchor-compatible popup styling and `SearchViewTheme` support.
- Anchored desktop popups and full-screen mobile views by default.
- Multi, single, and single-optional selection modes.
- Nested `SubPickerTile` menus with optional animated offsets.
- Safe client-side and server-side search: missing loaded items are never
  interpreted as deleted selections.
- Selection observables `onChange` and `onClose`; the app owns persistence.
- Optional builders for every visual region; built-in widgets are only defaults.
- No permanent trigger `GlobalKey`; popup resources are created on demand.

## Installation

```yaml
dependencies:
  search_anchor_picker: ^0.1.2
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
observes only actual user add/remove intent.

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

The default widgets are not built while the popup is closed.

## Related-list status and sub-list membership

`relatedListItemStatusOf` returns a `PickerRelatedListItemStatus` for each item. The
related list may be a parent list that uses the item or an auxiliary sub-list.
Its `auxiliaryMembership` describes membership, and its `unselectPolicy`
controls whether removing the selection is allowed, blocked, or confirmed.

Selection and auxiliary-list membership are separate. A checked parent item can
still be a non-member of a sub-list, and a partial server response may leave
membership unknown:

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

`member`, `notMember`, and `unknown` describe only the auxiliary list; they
never check or uncheck the item. The default row uses a filled, outlined, or
search-marked person icon respectively. A custom `iconOf` overrides these
icons. `unknown` is appropriate when a paged or filtered server result cannot
prove membership. If each item has an authoritative `isInDirectory` flag, use
that to return `member` or `notMember` even when the directory is paginated.
Only infer `unknown` from absence when the full membership set is not known;
finishing one page does not make that set complete.

`PickerUnselectPolicy.blocked` keeps the checkbox selected and shows a localized
in-use warning. `confirm` asks for localized confirmation, while `allow`
unselects normally. Use `unselectWarningBuilder` and
`unselectConfirmationBuilder` for application-specific feedback.

`relatedListItemStatusListenable` redraws related-list status without calling
`loadItems`. Its listener is attached only while the popup is open.
`SubPickerParentSelectionEffect` separately controls whether an accepted child
selection change also updates the open parent's checkboxes.

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
canChangeSelection: (change) async {
  return change.removedItems.every((person) => !person.isLocked);
},
onChange: (delta) async {
  await directoryApi.add(delta.added);
  await directoryApi.remove(delta.removed);
},
onClose: (result) {
  // Optional: whole delta of the session.
},
```

Rejected, blocked, or cancelled changes never update the parent.
Closing waits for in-flight `canChangeSelection` / `onChange` work to settle.
`canChangeSelection` is only a gate: its presence does not change `onChange`
or `onClose`. `viewOnClose` remains the overlay-lifecycle callback.

## Server-side search safety

`loadItems` is display/search data, not deletion truth. A selected ID that is
missing from the current result remains selected.

Header selection helpers record explicit persistence intent:

- `clearLoaded()` / `selectLoaded()`
- `clearFiltered()` / `selectFiltered()`
- `setSelected(id, selected)`

Bulk helpers affect only the current loaded result. Hidden server-side selections
are untouched.

Use `syncPending(added:, removed:)` to apply an already-persisted external delta
to the currently open picker's temporary pending set. It processes additions
and removals symmetrically, but does not mutate `initialSelectedIds` or caller
state and does not report the change again through `onChange` or `onClose`. The caller must
update its authoritative selected IDs separately.

## Persistence

The picker notifies; it does not persist. Save from `onChange` (each accepted
toggle) or `onClose` (whole delta of session). `canChangeSelection` only
accepts or rejects a proposed change. Checkboxes update after the gate
succeeds. A thrown `onChange` / `onClose` error is reported and does not roll
back selection.

There is no replace-all close callback. Persist `added` and `removed`.
`initialSelectedIds` is only the seed for the next open, from your selected
IDs.

## License

MIT
