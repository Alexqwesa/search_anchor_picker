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
- Async loads are generation guarded. Stale or post-disposal completions must
  not update an overlay.
- Config identity is not a reload signal. Rebind configuration on replacement,
  but fetch only on open, `controller.refresh()`, a configured `Listenable`
  notification, or a changed `reloadKey` while open.
- Escape and back close only the topmost picker. Outside taps close anchored
  popups; full-screen views instead retain a visible close/back affordance.
  Close callbacks run at most once per session.
- Search remains editable after opening and after clearing the query.

## Repository map

- `lib/src/search_anchor_picker.dart`: overlay ownership, placement, animation,
  focus, lazy resources, load lifecycle, and close behavior.
- `lib/src/selection_session.dart`: initial seed, pending IDs, and explicit
  delta bookkeeping. Keep selection policy independent of rendering.
- `lib/src/overlay_body.dart`: filtering, rows, and toggle orchestration.
- `lib/src/picker_config.dart`: public configuration and picker controller API.
- `lib/src/picker_builders.dart`: focused visual extension points.
- `lib/src/widgets/`: optional/default visuals and `SubPickerTile`. Core state
  and lifecycle logic do not belong here.
- `test/`: core behavior, lifecycle, placement, selection, and visual parity.
- `example/search_anchor_picker_example/`: demos and dependencies used only by
  demos. Its Riverpod integration test lives in its own `test/` directory.
- `technical_overview.md`: architecture rationale.
- `README.md`: human-facing package documentation.
- `doc/USAGE_SKILL.md`: consumer-agent integration instructions.

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
3. Explicit deltas: user intent reported by `onFinish`.

Never derive removals by intersecting pending IDs with a loaded page. Verify
partial server results, reloads, temporary empty external seeds, close/reopen,
radio modes, bulk controller commands, and nested picker synchronization.

Keep reload invalidation explicit. Inline `PickerConfig(...)` objects are normal
Flutter usage and may be recreated on every parent build. Such replacement must
not cause I/O or loops. `reloadKey` changes may be coalesced within one frame;
all reload paths must retain stale-request suppression and closed-picker lazy
subscription behavior.

`syncPending(added:, removed:)` symmetrically applies an already-persisted
external delta to the currently open picker's temporary pending IDs. It does not
mutate `initialSelectedIds` or caller state and must not emit the same change
again through `onFinish`. `SubPickerTile` intentionally forwards only child
removals; that nested-list policy is separate from `syncPending` behavior.

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
agent instructions in the human README.

For a release:

1. Set `pubspec.yaml` to the intended semantic version.
2. Add that version to `CHANGELOG.md` and call out breaking API changes.
3. Run both package and example verification suites.
4. Run `dart pub publish --dry-run` from a clean Git worktree.
5. Create and push a matching `vX.Y.Z` tag; the publish workflow verifies that
   the tag and pubspec version match.
