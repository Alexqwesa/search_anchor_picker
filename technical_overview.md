# Technical Overview: Search Anchor Picker

## Architecture

The package is split between core behavior and optional visual defaults.

- `GenericSearchAnchorPicker<T, K>` owns popup placement, focus, search loading,
  animation, keyboard handling, related-list status, and callback lifecycle.
- `PickerSelectionSession<K>` owns the open snapshot, current pending IDs, and
  explicit add/remove intent.
- `OverlayBody<T, K>` coordinates filtering and row toggles without choosing the
  surrounding popup surface or list layout.
- `GenericPickerController<T, K>` exposes pending selection state, explicit-delta
  bulk operations, and
  pending synchronization to header code.
- `SubPickerTile` is the optional nested-picker convenience widget, including
  parent-selection effects.
- Default view widgets, tooltip helpers, and feedback UI are exported by
  `package:search_anchor_picker/widgets.dart`.

Never-opened pickers allocate no search, animation, selection-notifier, dynamic
key, or data-listener resources. Popup widgets, overlay entries, dynamic header
keys, and data subscriptions are released on close.

## SearchAnchor parity

The package uses its own `OverlayEntry` because Flutter `SearchAnchor` does not
support nested popup offsets. The view still follows SearchAnchor behavior:

- Explicit view properties override `SearchViewTheme`, which overrides copied
  Material 3 SearchAnchor fallback values.
- Mobile platforms default to full-screen; desktop platforms use an anchored
  popup sized from the anchor and effective view constraints.
- Full-screen mode ignores menu offsets, outer view padding, and popup sides.
- Anchored views support outside-tap closure. Full-screen views have no outside
  region and use the default search field's localized back button instead.
- Desktop placement uses SearchAnchor's left/right and bottom-edge fallback,
  then applies `menuOffset` only on axes with enough screen space.
- The opening animation uses the emphasized SearchAnchor curve and duration.
- The default empty region resolves compact built-in translations from the
  current locale, while text overrides and `emptyBuilder` remain optional.

Flutter's private SearchAnchor default class cannot be reused directly, so the
small public-value resolver is kept in `DefaultPickerView` support code. Parity
tests compare theme resolution, constraints, platform behavior, and placement.

## Loading and lifecycle

Configuration identity and data revision are intentionally separate. Replacing
`PickerConfig` rebinds its control callbacks and, when necessary, its open-only
`Listenable` subscription without loading. Loads occur only on open, explicit
controller refresh, a configured `Listenable` notification, or a changed
`reloadKey` while open. Same-frame `reloadKey` changes are coalesced, and the
next open always uses the latest loader.

Each load receives a generation number. Only the newest generation may publish
items or errors, so a slow previous request cannot overwrite a newer server page.
Closing or disposing increments the generation and removes the overlay
synchronously. Loading, error-with-retry, and empty states are explicit and each
has an optional builder.

Close is idempotent. The selection result and callback references are captured
once, the overlay is removed, and persistence callbacks run after the frame.
Callback failures are reported through `FlutterError` while cleanup still
completes, leaving the picker reusable.

## Selection rules

`loadItems` is a display result, never deletion truth. Pending IDs are not
intersected with loaded IDs.

`PickerRelatedListItemStatus`, supplied by `relatedListItemStatusOf`, describes
auxiliary-list membership and unselect policy based on related-list usage.
`member`, `notMember`, and `unknown` do not alter pending
IDs. `unknown` preserves uncertainty when an item is absent from a partial
page; an authoritative per-item flag can establish membership without loading
the whole auxiliary list. The optional `relatedListItemStatusListenable`
subscription exists only while open and repaints rows without loading data.

Row toggles, `setSelected`, and loaded/filtered bulk controller commands record
only IDs they actually change as `added` or `removed`. A bulk command is one
delta over every loaded or filtered ID and takes the row-toggle pipeline
unchanged: gate, pending update, `onChange`, and the session's `onClose`. The
per-ID request risk lives in the application's `onChange`, which is where it
is documented. Parent updates to
`initialSelectedIds` may reseed pending state. `syncPending` symmetrically applies
an external add/remove delta to only the currently open picker's pending IDs; it
does not mutate the external seed. Neither operation creates a new persistence
delta. Reopening starts a new selection session from the latest external seed
and clears old intent.

There is no replace-all close callback and no final snapshot on `onClose`.
Persist `added` and `removed`. A failed or empty `loadItems` is not "the list
is empty".
`initialSelectedIds` is only the seed for the next open.

## Nested menus

`SubPickerTile` forwards all focused visual builders and SearchAnchor-style view
options. Parent selection and sub-list membership are independent by default.
`SubPickerParentSelectionEffect` defaults to `none`. Its opt-in `selectAdded`,
`deselectRemoved`, and `mirror` values apply either or
both sides of an accepted child delta into the open parent's pending set.
`syncPending` applies the update on the next frame. These effects do not persist
parent selection, update the external parent seed, or create a parent
`onChange` / `onClose` delta. Consumers with separate parent-selection
persistence must save that change in `onChange` or `onClose` and handle failures.

`SubPickerTile` forwards `canChangeSelection`, `onChange` (`PickerDelta`),
`onClose`, `closeSavingBuilder`, `closeSaveFailedBuilder`, and `headerBuilder`.
Accepted deltas share one apply pipeline for rows and bulk commands. The picker
notifies; the application persists. Policies run before gates. A thrown
`onChange` restores the checkbox and skips parent sync. A rejected gate never
applies. Close waits for `onClose`; a thrown `onClose` keeps the overlay open
and asks whether to keep editing. Pending work defers close. Deferred
controller updates are session-guarded so late child callbacks cannot mutate a
closed or reopened parent.

Nested overlays use no follower layers or permanent trigger keys. This avoids the
paint-transform failures that can occur when editing a search field under a
`CompositedTransformFollower`, and it keeps large closed widget lists inexpensive.
