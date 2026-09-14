## 0.1.2

* Added API documentation for the public libraries and query-close behavior.
* Added localized default empty/no-results messages with `emptyText` and
  `noResultsText` overrides for main and nested pickers.
* Localized default retry and in-use removal warning/confirmation text through
  the same locale resolver.

## 0.1.1

* Made item reloads explicit: ordinary `PickerConfig` replacement now rebinds
  without fetching, while `reloadKey`, `listenable`, and controller `refresh()`
  provide deliberate invalidation paths.

## 0.1.0

Breaking package identity:

* Renamed the unpublished package from `generic_search_selector` to
  `search_anchor_picker`; imports now use
  `package:search_anchor_picker/search_anchor_picker.dart`.
* Renamed `GenericPickerActions` / `PickerActions` to
  `GenericPickerController` / `PickerController`, and renamed
  `SubPickerTile.parentActions` to `parentController`.
* Removed the deprecated `onFinishReplaceAll`, `minWidth`, and `maxHeight`
  APIs. Use explicit `onFinish` deltas and `viewConstraints`.
* Removed the replace-all-only empty-save parameters, builder, and default
  widget.

* Raised the declared Flutter minimum to 3.38 and activated
  `very_good_analysis` for the package.
* Kept Riverpod isolated to the async example by moving its integration test
  into the example package.
* Split agent documentation into a package maintenance guide and a standalone
  consumer integration skill.

## 0.0.4

SearchAnchor parity / UI:

* Added SearchAnchor-compatible view properties and `SearchViewTheme` fallback.
* Added mobile full-screen and desktop anchored popup defaults.
* Added focused builders for search, results, loading, empty, error, composed
  view, and surface regions.
* Moved optional/default widgets under `lib/src/widgets/` and added `widgets.dart`.
* Added `viewConstraints` for popup sizing.

Selection / lifecycle:

* Close persistence uses `onFinish({added, removed})` explicit deltas.
* Simplified header actions: `selectLoaded`, `clearLoaded`, and their filtered
  variants record explicit deltas by default; `syncPending(added:, removed:)` is
  the sole pending-only synchronization escape hatch.
* Selected IDs missing from the loaded page are preserved.
* Extracted selection-session bookkeeping and expanded lifecycle coverage.
* Added loading/error/retry states, stale-load suppression, idempotent close,
  and safe callback failure cleanup.

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
* Added agent-facing integration guidance for common consumer pitfalls.
* Example web deploy workflow + online demo link.

## 0.0.2

* Internal packaging bump (see git tags `v13` / `v14` for prior consumer pins).

## 0.0.1

* Initial SearchAnchor-based picker with multi/radio modes, nested
  `SubPickerTile`, and header actions.
