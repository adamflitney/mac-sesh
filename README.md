# mac-sesh

Native Swift macOS menubar app for managing tmux sessions via Ghostty. Global hotkeys open a floating search overlay to switch to or create project sessions — without Raycast.

## Requirements

- macOS 14+
- Swift 6
- Ghostty terminal
- tmux

## Getting started

```bash
# Build
swift build

# Run
swift run

# Test
swift test
```

## Commands

- **Switch Session** — opens a project in a new Ghostty tab, or jumps to its existing tab
- **Replace Session** — switches the current Ghostty tab's tmux session in-place
