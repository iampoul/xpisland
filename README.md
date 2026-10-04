# XP Island

A draggable XP "island" for WoW Classic Era. Hover it to smoothly expand into
a full stats panel showing XP/hr, session and level timers, rested XP, total
played time, and kill/quest XP breakdown. Collapses back down when you move
away.

## Features

- Draggable, lockable island bar with saved position
- Hover to expand into a detailed stats panel (animated, matches native
  WoW tooltip styling)
- Session and level timers persist across `/reload`
- Every stat row is individually toggleable via the options panel
- Minimap icon (LibDataBroker/LibDBIcon) to quickly open options
- Lightweight — no heavy dependencies beyond the bundled Ace3 libs

## Slash commands

- `/xp` or `/xpisland` — open options
- `/xpisland lock` / `/xpisland unlock` — lock or unlock dragging
- `/xpisland toggle` — toggle lock state
- `/xpisland resetpos` — reset the island back to the center of the screen
- `/xpisland reset` — reset session statistics (XP/hr, timers, kill/quest XP)

## Installation

1. Download the latest release.
2. Extract into `Interface/AddOns/` so you end up with
   `Interface/AddOns/xpisland/xpisland.toc`.
3. Enable "XP Island" at the character selection AddOns screen.

## Notes on bundled libraries

A small number of the embedded Ace3/LibDataBroker files under `Libs/` include
local compatibility fixes for Classic Era (see `CHANGELOG.md`). If you update
these libraries from an external source, re-check those fixes still apply.

## Contributing / Issues

Open an issue or pull request on the GitHub repo. Please include your client
version (Classic Era build number) and any Lua error text when reporting
bugs.

## License

MIT — see `LICENSE`.
