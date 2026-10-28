# snag

**Report UI issues to a coding agent as screenshots with notes.** Press a hotkey, drag over the problem, type what is wrong. Repeat as often as you like. Finish, and hand the agent one folder.

![macOS](https://img.shields.io/badge/platform-macOS-lightgrey)
![Raycast](https://img.shields.io/badge/launcher-Raycast-red)
[![MIT](https://img.shields.io/badge/license-MIT-green)](LICENSE)

## The problem

A first pass over a new screen turns up ten small things. Reporting them to an agent one chat message at a time is slow, loses the screenshot, and loses where you were. Browser bug-report widgets only work inside one app and one browser.

## What snag does

1. **Captures any region of any app.** A hotkey starts the macOS area selection. A small note window then shows the screenshot next to a text box.
2. **Stacks the snags.** Each one is added to the open stack. A click-through counter in the bottom-right corner shows how many you have.
3. **Writes one folder for the agent.** `issues.md` lists every snag with your note, the app, the browser URL and title, and the time, next to `01.png`, `02.png` and so on. The folder path is copied to the clipboard.

In Chrome, Arc, Brave, Edge and Safari, snag also records the active tab URL and title.

## Install

Requirements: macOS, [Raycast](https://raycast.com), Xcode Command Line Tools (`swiftc`) and `jq`.

```bash
git clone git@github.com:filipditrich/snag.git ~/Work/tools/snag
```

1. In Raycast Settings, open **Script Commands** and add the `raycast/` folder of the checkout (not the repo root) under **Script Folders** with **+**.
2. Give **Snag** a hotkey, for example ⌃⌥S. **Snag: Undo Last** and **Snag: Finish** work from the launcher without one.
3. Press the hotkey once. macOS asks for Screen Recording permission for Raycast. In a browser it also asks to let Raycast control that browser, which is how snag reads the tab.

The note window (`src/note.swift`) and the counter (`src/hud.swift`) build themselves into `build/` on first use and after every change to the source. The first snag therefore takes a few seconds.

## Using it

1. **Snag.** Drag over a region (esc cancels). Type the issue. ⌘↵ adds it, esc discards it.
2. **Snag: Undo Last** removes the last snag.
3. **Snag: Finish** writes `issues.md` and copies the folder path. Paste it to the agent.

The same commands work from a terminal:

```console
$ bin/snag ls
2 snags
1. Tlačítko „Uložit“ přetéká
2. Table header is not sticky
$ bin/snag done
2 snags → ~/Work/.snag/2026-10-28-1530 (path copied)
```

An entry in `issues.md` looks like this:

```markdown
## 1. Tlačítko „Uložit“ přetéká

- App: Google Chrome
- URL: https://hub.example.com/events/42/ticketing ("Ticketing – Hub")
- At: 15:31:04

Tlačítko „Uložit“ přetéká
On narrow screens it wraps under the table.

![01](01.png)
```

## Telling your agent

Add a line like this to your agent instructions (`CLAUDE.md`, `AGENTS.md`):

> When I paste a `~/Work/.snag/...` path or say "snags", read `issues.md` there, open each screenshot, and work the issues in order.

## Files

Everything lives in `~/Work/.snag`. Set `SNAG_DIR` to change it.

- `current/` is the open stack. `items.jsonl` holds one line per snag and is the only state.
- `YYYY-MM-DD-HHMM/` is a finished stack with `issues.md`, `NN.png` and `items.jsonl`.
- `latest` links to the last finished stack.

## How it works

`bin/snag` is a bash script and owns every path and format. `add` reads the front app and browser tab through `osascript`, runs `screencapture -i`, and passes the image to the note window. The window prints the note and exits 0, or exits 1 when discarded. The note is appended to `items.jsonl` with `jq`.

The counter is a separate process that polls the line count of `items.jsonl` every half second and quits when the file is gone or empty. `add` starts it in its own session, so Raycast ending the script does not end the counter. `undo` and `done` never talk to it.

## Troubleshooting

**The commands do not show up in Raycast.** The script folder must be `raycast/`, not the repo root. Run **Reload Script Commands** after adding it.

**The URL line is missing.** Raycast is not allowed to control that browser. Allow it in System Settings → Privacy & Security → Automation.

**The screenshot is empty or shows only the wallpaper.** Raycast lacks Screen Recording permission. Allow it in System Settings → Privacy & Security → Screen Recording, then restart Raycast.

**The app is recorded as Raycast.** You started Snag from the Raycast launcher. Use the hotkey to record the app you were in.

## Development

```bash
tests/e2e.sh
```

The test runs the real CLI against a temporary `SNAG_DIR`. `SNAG_IMAGE=<png>` replaces the screen capture, `SNAG_NOTE=<text>` replaces the note window and `SNAG_NO_HUD=1` keeps the counter from starting. It restores your clipboard afterwards.

## License

[MIT](LICENSE)
