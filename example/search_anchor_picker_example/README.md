# Search Anchor Picker example

Demonstrates main pickers, nested `SubPickerTile` menus, async data sources,
single-selection modes, explicit delta persistence, and SearchAnchor-compatible popup
customization.

Run locally with:

```sh
flutter run -d chrome
```

Run the focused bulk-actions and pending-sync demo without changing the test-imported
`main.dart` entrypoint:

```sh
flutter run -d chrome -t lib/main_pending_actions.dart
```

Run the scenario-card gallery (chip fields, nested lists, `onClose` /
`onChange`, per-card source):

```sh
flutter run -d chrome -t lib/main_cards.dart
```

The deployed example is available at
https://alexqwesa.github.io/search_anchor_picker/.
