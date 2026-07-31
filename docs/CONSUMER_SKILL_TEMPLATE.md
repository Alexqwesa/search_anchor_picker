# Generic Search Selector Consumer Checklist

Use this checklist when changing an integration:

- Prefer `onFinish(added:, removed:)` for save-on-close persistence.
- Prefer `onToggle` for save-on-each-click persistence.
- Use `SubPickerTile` for nested pool/sublist membership.
- Treat `initialSelectedIds` as external selection state, not as a loading
  placeholder.
- Treat `loadItems` as a partial display/search result; absence never means
  deletion.
- Use `pending*` actions for pending-only UI and `*AsDelta()` actions for explicit
  bulk persistence intent.
- Do not add new `onFinishReplaceAll` usage; it is deprecated because partial
  server results cannot safely replace authoritative selection state.
- Use `SearchViewTheme` or SearchAnchor-style view properties before replacing a
  whole visual region with a builder.
- Keep nested popup offsets desktop-oriented; mobile defaults to full-screen.
