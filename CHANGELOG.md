## 0.0.4

SearchAnchor parity / UI:

* Added SearchAnchor-compatible view properties and `SearchViewTheme` fallback.
* Added mobile full-screen and desktop anchored popup defaults.
* Added focused builders for search, results, loading, empty, error, save-empty,
  composed view, and surface regions.
* Moved optional/default widgets under `lib/src/widgets/` and added `widgets.dart`.
* Deprecated `minWidth` / `maxHeight` in favor of `viewConstraints`.

Selection / lifecycle:

* Split close persistence into `onFinish({added, removed})` explicit deltas and
  the now-deprecated `onFinishReplaceAll(finalIds)` compatibility callback.
* Simplified header actions: `selectLoaded`, `clearLoaded`, and their filtered
  variants record explicit deltas by default; `syncPending(added:, removed:)` is
  the sole pending-only synchronization escape hatch.
* Selected IDs missing from the loaded page are preserved.
* Extracted selection-session bookkeeping and expanded lifecycle coverage.
* Added loading/error/retry states, stale-load suppression, idempotent close,
  and safe callback failure cleanup.
* Empty legacy replace-all saves still require explicit confirmation.

Docs / example:

* Documented server-side search safety, visual builders, theme precedence, and
  `OnToggleMode.awaitGate` versus `OnToggleMode.optimistic`.
* Added the example web deployment workflow and online demo link.

Consumers using Git dependencies should pin a semantic version tag matching
`pubspec.yaml`.

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

## 0.0.2

* Internal packaging bump (see git tags `v13` / `v14` for prior consumer pins).

## 0.0.1

* Initial SearchAnchor-based picker with multi/radio modes, nested
  `SubPickerTile`, and header actions.
