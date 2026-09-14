# Technical Overview: Search Anchor Picker

## Architecture

The package is split between core behavior and optional visual defaults.

- `GenericSearchAnchorPicker<T, K>` owns popup placement, focus, search loading,
  animation, keyboard handling, and callback lifecycle.
- `PickerSelectionSession<K>` owns the open snapshot, current pending IDs, and
  explicit add/remove intent.
- `OverlayBody<T, K>` coordinates filtering and row toggles without choosing the
  surrounding popup surface or list layout.
- `GenericPickerController<T, K>` exposes pending selection state, explicit-delta
  bulk operations, and
  pending synchronization to header code.
- `lib/src/widgets/` contains default view widgets, tooltip helpers, feedback UI,
  and the optional `SubPickerTile` convenience widget.

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
- Desktop placement uses SearchAnchor's left/right and bottom-edge fallback,
  then applies `menuOffset` only on axes with enough screen space.
- The opening animation uses the emphasized SearchAnchor curve and duration.

Flutter's private SearchAnchor default class cannot be reused directly, so the
small public-value resolver is kept in `DefaultPickerView` support code. Parity
tests compare theme resolution, constraints, platform behavior, and placement.

## Loading and lifecycle

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

Row toggles, `setSelected`, and loaded/filtered bulk controller commands record
only IDs they actually change as `added` or `removed`. Parent updates to
`initialSelectedIds` may reseed pending state. `syncPending` symmetrically applies
an external add/remove delta to only the currently open picker's pending IDs; it
does not mutate the external seed. Neither operation creates a new persistence
delta. Reopening starts a new selection session from the latest external seed
and clears old intent.

There is no replace-all close callback. Consumers apply explicit deltas, while a
parent with a complete authoritative snapshot can reseed `initialSelectedIds`.

## Nested menus

`SubPickerTile` forwards all focused visual builders and SearchAnchor-style view
options. When `parentController` is supplied, explicit sub-picker removals are also
removed from the parent pending set. Sub-picker additions are not selected in the
parent automatically.

Nested overlays use no follower layers or permanent trigger keys. This avoids the
paint-transform failures that can occur when editing a search field under a
`CompositedTransformFollower`, and it keeps large closed widget lists inexpensive.
