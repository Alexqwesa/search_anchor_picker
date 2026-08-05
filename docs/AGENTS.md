# Integration Notes

## Choose the persistence boundary

| Use case | Preferred API |
| --- | --- |
| Main-list row assignment | `onToggle` or root `onFinish` |
| Nested pool/sublist membership | `SubPickerTile` + `onFinish` |
| Header bulk selection | `selectLoaded`, `clearLoaded`, or filtered variants |
| Mirror already-persisted external changes | `syncPending` |

`onFinishReplaceAll` is deprecated. Do not introduce it in new integrations.
Use explicit deltas unless the backend truly requires a complete, authoritative
snapshot that was loaded independently from search/pagination results.

## Selection invariants

- `initialSelectedIds` is the external seed for the next open.
- An open picker may reseed pending IDs when `initialSelectedIds` changes; that
  external change never becomes an `added` or `removed` delta.
- Missing loaded IDs remain selected. `loadItems` is display data, not deletion
  truth.
- Row toggles, `setSelected`, and loaded/filtered bulk helpers produce deltas.
- `syncPending(added:, removed:)` is the only pending-only action. Use it to
  mirror changes already persisted elsewhere, not for ordinary user controls.
- Use `initialSelectedIds` for authoritative full-state synchronization.
- Loaded/filtered helpers never touch hidden server-side IDs.

For save-on-close, apply `added` and `removed` to caller state after persistence.
For save-on-each-click, use `onToggle`; choose `OnToggleMode.optimistic` when the
UI should move before a remote operation completes.

## Nested pickers

Pass the current sublist membership to `SubPickerTile.initialSelectedIds`. When
`parentActions` is provided, explicit sub-picker removals are removed from parent
pending selection. Additions remain unselected in the parent.

Desktop submenus may use `menuOffset`. Mobile defaults to full-screen just like
SearchAnchor; set `isFullScreen: false` only when an anchored mobile submenu is an
intentional UX decision.

## Visual customization

Prefer SearchAnchor-style view properties and `SearchViewTheme` for styling.
Use focused builders only for the region that needs custom behavior:

- trigger/header/item
- search field/results
- loading/empty/error
- save-empty/view/surface

Default visual widgets and `SubPickerTile` live in `lib/src/widgets/` and are
exported through `package:generic_search_selector/widgets.dart`.

## Lifecycle checks

- Keep configs stable where possible; changing a config while open starts a new,
  generation-guarded load.
- Do not retain popup `BuildContext`, actions, or dynamic keys after close.
- Async callbacks may complete after close; core cleanup is already synchronous.
- Callback failures are reported through `FlutterError`, so integrations should
  still handle persistence errors and provide user feedback.
