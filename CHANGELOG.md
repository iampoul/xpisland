# Changelog

All notable changes to this project are documented here.

## 1.1.0

### Changed
- Gold-tinted borders on the pill and stats panel (replacing plain white
  tooltip borders) for a more cohesive, native look.
- Added a subtle sheen highlight along the top of the progress bar.
- Added faint vertical divider lines between stat columns in the expanded
  panel.
- Added CurseForge project metadata (`X-Curse-Project-ID`) for automated
  releases.

## 1.0.0

### Added
- Draggable, lockable XP island bar with saved position.
- Hover-to-expand animated stats panel (XP/hr, session/level timers, rested
  XP, played time, kill/quest XP breakdown).
- Per-row toggles for the stats panel via Blizzard-style options
  (AceConfig).
- Minimap icon via LibDataBroker/LibDBIcon.
- Slash commands: `/xp`, `/xpisland`, plus `lock`, `unlock`, `toggle`,
  `resetpos`, `reset` subcommands.
- Native WoW tooltip-skin backdrop and real statusbar texture for the
  progress bar, to blend into the standard interface.

### Fixed (compatibility with Classic Era)
- `CallbackHandler-1.0`: replaced dynamic dispatcher codegen with a simple,
  robust iterate-and-xpcall dispatcher (the generated-code path could throw
  `'for' limit must be a number` / syntax errors on this client).
- `AceGUI-3.0` Frame container widget: guarded `SetBackdrop` /
  `SetMinResize` / `SetToplevel` calls that are not available on all client
  builds.
- `AceConfigDialog-3.0`: reduced `GameTooltip:SetText` calls to the
  text-only argument form for broader compatibility.
- `Format.lua` `ParsePlayedTime`: accepts both numeric and string forms of
  `TIME_PLAYED_MSG` payloads.
- Animation driver (`Animation.lua`): snapshots tween keys before iterating
  so starting a new animation from inside a completion callback doesn't
  corrupt the in-progress `pairs()` traversal.
