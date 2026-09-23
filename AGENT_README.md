# Search Anchor Picker Maintenance Guide

This is the agent-facing guide for maintaining this package. It is not a
consumer integration guide. For application usage, see
[`doc/USAGE_SKILL.md`](doc/USAGE_SKILL.md).

## Maintenance goals

Preserve these properties across every change:

- The default experience should feel like Flutter `SearchAnchor`, with nested
  popup support and optional desktop offsets.
- A closed picker must stay lightweight. Search controllers, focus nodes,
  animation controllers, overlays, dynamic keys, item snapshots, and source
  subscriptions are created only after opening and released on close.
- `loadItems` is display/search data, never deletion truth. Missing IDs must not
  be removed from selection.
- Only row interactions and explicit controller selection commands create
  `added` or `removed` deltas. External reseeds and `syncPending` do not.
- Item selection and auxiliary-list membership are independent. Unknown
  membership from a partial result must never be treated as non-membership or
  as an instruction to change selection.
- Async loads are generation guarded. Stale or post-disposal completions must
  not update an overlay.
- Config identity is not a reload signal. Rebind configuration on replacement,
  but fetch only on open, `controller.refresh()`, a configured `Listenable`
  notification, a changed `reloadKey` while open, or default search-field
  text when `searchMode` is `remote` or `hybrid`.
- Escape and back close only the topmost picker. Outside taps close anchored
  popups; full-screen views instead retain a visible close/back affordance.
  Close callbacks run at most once per session.
- Search remains editable after opening and after clearing the query.

## Repository map

- `lib/src/search_anchor_picker.dart`: public picker wrapper: related-list
  status, membership icons, and unselect policy on top of core overlay
  behavior.
- `lib/src/picker_config.dart`: public configuration and picker controller API.
- `lib/src/picker_status.dart`: `PickerRelatedListItemStatus` and related
  membership/unselect types.
- `lib/src/widgets/sub_picker_tile.dart`: nested `SubPickerTile` and
  `SubPickerParentSelectionEffect`.
- `lib/src/widgets/picker_defaults.dart`: public default row with related-list
  membership icons wrapping `RawDefaultPickerItemTile`.
- `lib/src/raw/widgets/default_picker_field_trigger.dart`: outlined field
  trigger with optional selected chips and Add / Change.
- `lib/widgets.dart`: optional/default visuals. Core state and lifecycle logic
  do not belong in consumer-facing widget docs.
- `test/`: core behavior, lifecycle, placement, selection, and visual parity.
- `example/search_anchor_picker_example/`: demos and dependencies used only by
  demos. Its Riverpod integration test lives in its own `test/` directory.
- `technical_overview.md`: architecture rationale for the public types.
- `README.md`: human-facing package documentation.
- `doc/USAGE_SKILL.md`: consumer-agent integration instructions.
- `doc/RAW.md`: internal raw/main layering. Use it when changing package
  internals, not when integrating the picker into an app.

## Design boundaries

Keep popup placement, focus, keyboard handling, loading, and selection in core.
A custom builder replaces only its visual region and must not be required to
reimplement lifecycle behavior.

Resolve visual values in this order:

1. Explicit picker argument.
2. `SearchViewTheme`.
3. Material/SearchAnchor-compatible default.

Mobile defaults to full-screen. Desktop defaults to an anchored popup.
`menuOffset` applies only to anchored popups and only on axes where the shifted
popup remains on screen.

The default full-screen search field owns a localized back button. A custom
`viewLeading` or `searchFieldBuilder` replaces that affordance and must expose
the core-provided close callback when no other visible exit exists.

Do not use `CompositedTransformFollower` for the popup. The package owns an
`OverlayEntry` specifically to support nested offsets without follower-layer
paint-transform failures or parent clipping.

Keep package dependencies minimal. A dependency needed only by an example or
example test belongs in the example package, not the root package.

## Selection changes

Before changing selection behavior, test all three state channels separately:

1. `initialSelectedIds`: authoritative external seed.
2. Pending IDs: current popup checkbox state.
3. Explicit deltas: user intent reported by `onChange` and `onClose`.

Never derive removals by intersecting pending IDs with a loaded page. Verify
partial server results, reloads, temporary empty external seeds, close/reopen,
single-selection modes, bulk controller commands, and nested picker synchronization.

Keep reload invalidation explicit. Inline `PickerConfig(...)` objects are normal
Flutter usage and may be recreated on every parent build. Such replacement must
not cause I/O or loops. `reloadKey` changes may be coalesced within one frame;
all reload paths must retain stale-request suppression and closed-picker lazy
subscription behavior.

`syncPending(added:, removed:)` symmetrically applies an already-persisted
external delta to the currently open picker's temporary pending IDs. It does not
mutate `initialSelectedIds` or caller state and must not emit the same change
again through `onChange` or `onClose`.

`PickerRelatedListItemStatus` is external display/policy state, not a fourth
selection channel. Keep its provider, listener, and builder argument under the
`relatedListItemStatus` prefix. `relatedListItemStatusListenable` must repaint without
loading and must remain an open-only subscription.
`PickerAuxiliaryMembership.unknown` represents
insufficient knowledge from a partial result; it must remain distinct from
`notMember`. An authoritative per-item flag can establish membership without
loading the whole auxiliary list.

The picker notifies; it does not persist.

`onChange` is the immediate save, `onClose` the deferred one; the picker owns
pending IDs in both cases. Block or confirm unselect with
`PickerUnselectPolicy` on `relatedListItemStatusOf`. A blocked or cancelled
unselect never moves the checkbox, so no save runs. Throw from `onChange` to
restore a checkbox after a failed write.

Save in `onChange` (each accepted delta) if the checkbox should move
first. A thrown `onChange` error restores the checkbox and session intent.
Toggling the same ID on and off is two `onChange` calls. Save in `onClose`
(net of session versus the seed at open) while the overlay stays open.
A later `initialSelectedIds` change reseeds checkboxes; it does not retarget
that delta.
Select then deselect is omitted; empty means do not write. A thrown error is
reported and the user is asked whether to update the
selection or close without saving. Persist `added` and `removed`. A load
error or empty search is not a deletion. Both may be set; `onChange` does not
consume session intent, so if both persist the API is called per mutation and
again at close. Persist in only one of them. `closeSavingBuilder` and
`closeSaveFailedBuilder` replace the localized defaults.

Controller bulk commands are not special-cased: `selectLoaded`, `clearLoaded`,
`selectFiltered`, and `clearFiltered` run the same apply pipeline as a row
toggle and produce one delta over every affected ID. The only caveat is on the
application side, documented on `onChange`: a save that loops the delta turns
one command into a request per ID.

Apply order is unselect policy, then pending checkboxes, then
`onChange`. A blocked or cancelled unselect never reaches `onChange`. A
thrown `onChange` restores the checkbox and does not parent-sync. Close waits
for in-flight `onChange` and `onClose` work.

`SubPickerTile` leaves parent selection unchanged unless
`parentSelectionEffect` is set. Passing `parentController` alone does not
enable coupling. Opt-in effects (`selectAdded`, `deselectRemoved`, `mirror`)
copy the matching side of a successful child `onClose` into the open
parent's pending checkboxes, including bulk child commands. If `onClose`
is omitted, the effect applies after each accepted `onChange`. Call
`notifyParent()` from `onChange` only for immediate parent updates when
`onClose` is also set; it is not applied again on close. They call `syncPending`,
which lands on the next frame, so ignore that update if the parent session
has closed or been replaced. The parent search field shows progress while
the child write is in flight; close already waits for in-flight `onChange`.
The effect does not persist parent selection,
reseed `initialSelectedIds`, or emit a parent `onChange` / `onClose` delta.
Session bookkeeping stays core-owned and open-only.

## Verification

Run these before considering maintenance work complete:

```sh
dart format .
flutter analyze
flutter test
cd example/search_anchor_picker_example
flutter analyze
flutter test
```

For view or platform changes, also run the relevant example build. After moving
or renaming the example directory, remove stale generated `build/` output before
running CMake-based desktop builds.

The package uses `very_good_analysis`. Keep analyzer exceptions narrow,
documented, and justified by public API compatibility rather than convenience.

## Documentation and releases

When public behavior changes, update the human README, technical overview,
consumer skill, tests, example, and changelog together. Do not put maintainer or
agent instructions in the human README. Do not document raw types in consumer
or public API docs; use [`doc/RAW.md`](doc/RAW.md) when the internal split
changes.

For a release:

1. Set `pubspec.yaml` to the intended semantic version.
2. Add that version to `CHANGELOG.md` and call out breaking API changes.
3. Run both package and example verification suites.
4. Run `dart pub publish --dry-run` from a clean Git worktree.
5. Create and push a matching `vX.Y.Z` tag; the publish workflow verifies that
   the tag and pubspec version match.
