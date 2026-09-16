# Raw picker layer (maintenance)

This document is for people changing this package. It is not a consumer
integration guide.

Consumer apps and consumer agents should use only the finished public types
from `package:search_anchor_picker/search_anchor_picker.dart` and
`package:search_anchor_picker/widgets.dart`:

- `SearchAnchorPicker` / `GenericSearchAnchorPicker`
- `PickerConfig` / `GenericPickerConfig`
- `PickerController` / `GenericPickerController`
- `SubPickerTile` / `GenericSubPickerTile`
- `PickerRelatedListItemStatus`, `PickerUnselectPolicy`,
  `PickerAuxiliaryMembership`, `SubPickerParentSelectionEffect`,
  `PickerPersistence`, `PickerSelectionResult`
- default widgets exported by `widgets.dart`

Do not tell application code to import `package:search_anchor_picker/raw.dart`.

## Why the split exists

The raw layer is the pre-status picker: overlay, search, selection session,
load lifecycle, and builder hooks. The main library wraps it with related-list
status, membership icons, per-item unselect policy, and parent/child selection
effects.

| Concern | Layer | Types |
| --- | --- | --- |
| Overlay, search, selection, load/close | Raw | `GenericRawSearchAnchorPicker`, `GenericRawPickerConfig`, `OverlayBody`, `PickerSelectionSession` |
| Related-list status and unselect policy | Main | `PickerRelatedListItemStatus`, `GenericPickerConfig`, `GenericSearchAnchorPicker` |
| Parent/child checkbox sync | Main | `SubPickerParentSelectionEffect`, `GenericSubPickerTile` |
| Persistence policy | Raw | `PickerPersistence`, `canChangeSelection`, observer `onFinish` |
| Nested tile without parent sync | Raw | `GenericRawSubPickerTile` |

## Libraries

- `lib/search_anchor_picker.dart` — published product API.
- `lib/widgets.dart` — published default and convenience widgets.
- `lib/raw.dart` — unpublished-in-docs maintenance entrypoint for the raw
  types. Import it only from package code, tests that need internals, or this
  maintenance workflow.

## Source map

- `lib/src/raw/search_anchor_picker.dart`: overlay ownership, placement,
  animation, focus, lazy resources, load lifecycle, and close behavior.
- `lib/src/raw/selection_session.dart`: initial seed, pending IDs, and explicit
  delta bookkeeping.
- `lib/src/raw/overlay_body.dart`: filtering, rows, and toggle orchestration.
- `lib/src/raw/picker_persistence.dart`: `PickerDelta`, `PickerPersistence`,
  apply mode, and session result types.
- `lib/src/raw/picker_config.dart`: raw config, controller, `PickerUnselectPolicy`.
- `lib/src/picker_status.dart`: related-list membership and unselect policy.
- `lib/src/picker_config.dart`: public config wrapping the raw config.
- `lib/src/search_anchor_picker.dart`: public picker wrapping the raw picker.
- `lib/src/widgets/sub_picker_tile.dart`: public nested tile extends the raw
  tile. It supplies related-list status, unselect policy, and
  `SubPickerParentSelectionEffect` through the raw tile's picker hooks and does not
  override `createPicker()`.
- `lib/src/widgets/picker_defaults.dart`: public default widgets that add
  package semantics (for example `DefaultPickerItemTile.auxiliaryMembership`)
  onto raw primitives.
- `lib/src/raw/widgets/`: primitive default visuals used as raw fallbacks,
  including `RawDefaultPickerItemTile`.

## Changing behavior

- Overlay, placement, loading, selection deltas, and close lifecycle: edit raw,
  then confirm the main wrappers still forward the public API.
- Related-list status, membership icons, unselect policy: edit main wrappers
  and `lib/src/picker_status.dart`. Do not teach raw about auxiliary membership.
- Parent/child sync (`SubPickerParentSelectionEffect` via `onDeltaPersisted`):
  edit `lib/src/widgets/sub_picker_tile.dart`. Raw tiles must not apply parent
  effects. Persistence, gates, and observer `onFinish` belong on the raw picker.

When public behavior changes, update README, `doc/USAGE_SKILL.md`, tests,
example, and changelog. Update this file only when the raw/main split changes.
