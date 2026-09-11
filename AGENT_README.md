# Agent documentation moved

Full agent integration rules live in **[doc/AGENTS.md](doc/AGENTS.md)**.

That file covers:

- `SubPickerTile` (save-on-close) vs `onToggle` (gate / async)
- `initialSelectedIds` sync while open vs closed
- `OnToggleMode` (`awaitGate` vs `optimistic`)
- `idOf` stability and `listenable` vs `actions.refresh()`

Consumer apps should add a short Cursor skill (see end of `doc/AGENTS.md`).
