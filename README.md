# mac-sesh

[![Download](https://img.shields.io/github/v/release/adamflitney/mac-sesh?label=download&logo=apple)](https://github.com/adamflitney/mac-sesh/releases/latest)

A native Swift macOS menubar app for managing tmux sessions in Ghostty. Press a global hotkey from any app, type a few characters to fuzzy-search your git projects, and hit Enter — mac-sesh opens the project in a new Ghostty tab (or jumps to its existing one), with a pre-configured tmux session ready to go.

Built as a Raycast-independent replacement for [raycast-sesh](https://github.com/adamflitney/raycast-sesh).

## How it works

1. mac-sesh runs as a menubar app (no Dock icon).
2. Press a global hotkey — a floating search overlay appears on your primary monitor.
3. Type to fuzzy-search git projects in your configured directories.
4. Press Enter (or click) to open the project.
   - **Switch Session**: opens a new Ghostty tab attached to a tmux session for that project, or jumps to the existing tab if one is already open.
   - **Replace Session**: switches the active Ghostty tab's tmux session in-place — useful for re-using an existing window rather than accumulating tabs.
5. When a session is created for the first time, mac-sesh sets up a tmux session with your configured windows (default: `neovim`, `claude`, `shell`) and focuses the default window.

Projects are ranked by **frecency** — a combination of how recently and how often you've visited them — so your most-used projects float to the top automatically.

## Requirements

- macOS 14+
- Ghostty terminal
- tmux

## Install

**Download** the latest DMG from [Releases](https://github.com/adamflitney/mac-sesh/releases/latest), open it, and drag MacSesh to `/Applications`.

macOS may block the app on first launch since it is ad-hoc signed but not notarized. To allow it:

```bash
xattr -dr com.apple.quarantine /Applications/MacSesh.app
```

Or: right-click MacSesh.app → **Open** → **Open**.

## Build from source

```bash
git clone https://github.com/adamflitney/mac-sesh.git
cd mac-sesh
swift run MacSesh
```

On first launch mac-sesh will:
- Appear as a terminal icon (`⌦`) in your menubar.
- Write a default config file to `~/.config/mac-sesh/config.json`.
- Register the global hotkeys (no Accessibility permission needed — uses Carbon).

## Default config

```json
{
  "hotkeys": {
    "switchSession":  "hyper+w",
    "replaceSession": "hyper+e"
  },
  "session": {
    "defaultWindow": "neovim",
    "windows": [
      { "name": "neovim", "command": "nvim ." },
      { "name": "claude", "command": "claude" },
      { "name": "shell" }
    ]
  },
  "projects": {
    "directories": ["~/dev"],
    "exclude": []
  }
}
```

### Hotkeys

Modifier names: `hyper`, `cmd`, `shift`, `ctrl`, `opt` (or `option`/`alt`/`control`/`command`).

Key names: any letter `a`–`z`, digits `0`–`9`, `space`, `tab`, `return`, `escape`, `f1`–`f12`.

`hyper` is a shorthand for `cmd+ctrl+opt+shift` — the common Caps Lock remap used with Karabiner-Elements.

### Session windows

Each window entry has a `name` and an optional `command`. If `command` is omitted the window opens a plain shell in the project directory.

```json
{ "name": "opencode", "command": "opencode" }
```

`defaultWindow` sets which window gets focus after the session is created. Defaults to the first window.

### Project directories

`directories` is a list of root directories to scan for git repositories (immediate subdirectories containing a `.git` folder).

`exclude` is a list of path prefixes to skip. Tilde paths are expanded:

```json
"exclude": ["~/dev/archived", "~/dev/scratch"]
```

## Menubar

| Item | Action |
|---|---|
| Switch Session `✦W` | Open the Switch Session overlay |
| Replace Session `✦E` | Open the Replace Session overlay |
| Edit Config | Open `~/.config/mac-sesh/config.json` in your default editor |
| Reload Config | Re-read the config and swap hotkeys live (no restart needed) |
| Quit mac-sesh | Quit |

## Development

```bash
swift build   # build
swift test    # run 41 tests
swift run MacSesh
```

The project is structured as a Swift Package with two targets:

- **MacSeshCore** — pure logic: tmux parsing, Ghostty AppleScript, fuzzy search, config, frecency scoring. Fully unit-tested, no AppKit dependency.
- **MacSesh** — the app: AppDelegate, floating NSPanel, SwiftUI search view, Carbon hotkey registration.
