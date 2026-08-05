# Generic Search Selector Consumer Checklist

Use this checklist when changing an integration:

- Prefer `onFinish(added:, removed:)` for save-on-close persistence.
- Prefer `onToggle` for save-on-each-click persistence.
- Use `SubPickerTile` for nested pool/sublist membership.
- Treat `initialSelectedIds` as external selection state, not as a loading
  placeholder.
- Treat `loadItems` as a partial display/search result; absence never means
  deletion.
- Use `selectLoaded`, `clearLoaded`, and their filtered variants for bulk user
  intent. Reserve `syncPending` for mirroring changes already persisted elsewhere.
- Do not add new `onFinishReplaceAll` usage; it is deprecated because partial
  server results cannot safely replace authoritative selection state.
- Use `SearchViewTheme` or SearchAnchor-style view properties before replacing a
  whole visual region with a builder.
- Keep nested popup offsets desktop-oriented; mobile defaults to full-screen.
