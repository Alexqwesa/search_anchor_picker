## 0.0.3

Breaking / API:

* Split close persistence into `onFinish({added, removed})` (explicit row deltas) and `onFinishReplaceAll(finalIds)` (replace-all).
* `onFinish` no longer receives the full `finalIds` list; use `onFinishReplaceAll` when the backend needs the whole selection.
* Empty `onFinishReplaceAll` saves require an explicit empty-save confirmation (`saveEmptyLabel` / `showSaveEmptyButton`).
* Added bulk pending helpers: `pendingClearLoaded`, `pendingClearFiltered`, `pendingSelectLoaded`, `pendingSelectFiltered` (no deltas).
* Added explicit delta helpers: `toggleIdAsDelta`, `clearLoadedAsDelta`, `selectLoadedAsDelta`, `clearFilteredAsDelta`, `selectFilteredAsDelta`.

Behavior / docs:

* Selected IDs missing from the current `loadItems` page are preserved (server-side search safe).
* Documented `OnToggleMode.awaitGate` vs `OnToggleMode.optimistic` for async checkbox UX.
* Added `docs/AGENTS.md` and consumer skill template for integrator pitfalls.
* Example web deploy workflow + online demo link.

Consumers on git should bump `ref` to **`v15`**.

## 0.0.2

* Internal packaging bump (see git tags `v13` / `v14` for prior consumer pins).

## 0.0.1

* Initial SearchAnchor-based picker with multi/radio modes, nested `SubPickerTile`, and header actions.
