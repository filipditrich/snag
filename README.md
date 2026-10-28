# snag

**Report UI issues to a coding agent as screenshots with notes.** Press a hotkey, drag over the problem, type what is wrong. Repeat. Finish, and hand the agent one folder.

Works in any app. In Chrome, Arc, Brave, Edge and Safari it also records the active tab URL and title.

## Setup

Requirements: macOS, Xcode Command Line Tools (`swiftc`), `jq`.

1. In Raycast Settings, open Script Commands and add `raycast/` (not the repo root) under Script Folders with +.
2. Give hotkeys to **Snag**, **Snag: Undo Last** and **Snag: Finish**.

The note window (`src/note.swift`) and the counter (`src/hud.swift`) build themselves into `build/` on first use and after every change to the source. The first time snag reads a browser tab, macOS asks to let Raycast control that browser.

## Using it

1. **Snag.** Drag over a region (esc cancels). In the note window, type the issue. ⌘↵ adds it, esc discards it.
2. **Snag: Undo Last** removes the last snag.
3. **Snag: Finish** writes `issues.md` next to the numbered PNGs and copies the folder path. Paste it to the agent.

While a stack is open, a click-through pill in the bottom-right corner shows its snag count.

```console
$ bin/snag ls
2 snags
1. Tlačítko „Uložit“ přetéká
2. Table header is not sticky
$ bin/snag done
2 snags → ~/Work/.snag/2026-10-28-1530 (path copied)
```

## Files

Everything lives in `~/Work/.snag` (set `SNAG_DIR` to change it).

- `current/` is the open stack. `items.jsonl` holds one line per snag and is the only state.
- `YYYY-MM-DD-HHMM/` is a finished stack with `issues.md`, `NN.png` and `items.jsonl`.
- `latest` links to the last finished stack.

For tests, `SNAG_IMAGE=<png>` replaces the screen capture, `SNAG_NOTE=<text>` replaces the note window and `SNAG_NO_HUD=1` keeps the counter from starting.
