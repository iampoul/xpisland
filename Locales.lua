local ADDON_NAME, ns = ...

-- Be defensive: LibStub or AceLocale may not be present at file-load time when
-- the game's addon loader executes files. Fall back to a plain table so the
-- addon still has a usable locale table while AceLocale initializes later.
ns = ns or {}
ns.L = ns.L or {}
local L = ns.L

if LibStub then
    local ok, AceLocale = pcall(LibStub, "AceLocale-3.0")
    if ok and AceLocale and AceLocale.GetLocale then
        local locale = AceLocale:GetLocale(ADDON_NAME, "enUS", true)
        if locale then
            L = locale
            ns.L = L
        end
    end
end

L["name"] = "XP Island"
L["bar"] = "Bar"
L["display"] = "Display"
L["info"] = "Information"
L["advanced"] = "Advanced"

L["show_xphr"] = "Session XP per hour"
L["show_xphr_desc"] = "Experience gained per hour, based on the current session."

L["show_levelxphr"] = "Level XP per hour"
L["show_levelxphr_desc"] = "Experience gained per hour since reaching your current level."

L["show_session_time"] = "Session time"
L["show_session_time_desc"] = "Time since you logged in. Survives a UI reload."

L["show_level_time"] = "Level time"
L["show_level_time_desc"] = "Time spent on your current level. Resets when you level up."

L["show_xp"] = "Current XP"
L["show_xp_desc"] = "Your current XP and the XP needed for the next level."

L["show_rested"] = "Rested XP"
L["show_rested_desc"] = "Bonus experience you have banked while rested."

L["show_played"] = "Total played time"
L["show_played_desc"] = "Total time played on this account."

L["show_kills"] = "XP from kills"
L["show_kills_desc"] = "Experience gained from killing creatures this session."

L["show_quests"] = "XP from quests"
L["show_quests_desc"] = "Experience gained from quests this session."

L["show_session_xp"] = "Session XP"
L["show_session_xp_desc"] = "Total experience gained this session."

L["show_eta"] = "Time to next level"
L["show_eta_desc"] = "Estimated time remaining based on your current XP rate."

L["locked"] = "Lock the bar"
L["locked_desc"] = "Prevent the bar from being dragged."

L["width"] = "Bar width"
L["width_desc"] = "Width of the island in pixels."

L["scale"] = "Scale"
L["scale_desc"] = "Scales the whole island, including the expanded panel."

L["show_barname"] = "Show bar text"
L["show_barname_desc"] = "Show your level and progress percentage on the bar."

L["alpha"] = "Bar transparency"
L["alpha_desc"] = "Transparency of the island background."

L["show_minimap"] = "Show minimap icon"
L["show_minimap_desc"] = "Display an icon on the minimap that opens the options."

L["reset_stats"] = "Reset session statistics"
L["reset_stats_desc"] = "Clears XP totals and timers for this session."

L["reset_position"] = "Reset bar position"
L["reset_position_desc"] = "Moves the island back to its default location."

L["lock_toggle"] = "Toggle bar lock"
L["lock_toggle_desc"] = "Lock or unlock the bar so it can be dragged."

L["open_options"] = "Open options"
L["open_options_desc"] = "Opens the Blizzard options panel for this addon."

-- Expanded panel row labels
L["row_session_rate"] = "Session XP/hr"
L["row_level_rate"] = "Level XP/hr"
L["row_session_time"] = "Session time"
L["row_level_time"] = "Level time"
L["row_xp"] = "Current XP"
L["row_rested"] = "Rested XP"
L["row_played"] = "Played"
L["row_kills"] = "XP from kills"
L["row_quests"] = "XP from quests"
L["row_session_xp"] = "Session XP"
L["row_eta"] = "Time to next level"

L["none"] = "None"
L["split_sources"] = "Split quest XP"
L["split_sources_desc"] = "Attribute quest experience separately from kill experience. When off, all combat XP counts as kills."

L["xp_tooltip"] = "Left click to open options. Drag to move the island."
L["locked_tooltip"] = "The island is locked. Use the options to unlock it."

L["level_short"] = "Lv"
L["na"] = "n/a"
L["unknown"] = "?"

L["reset_stats_done"] = "Session statistics reset."
L["minimap_tooltip"] = "XP Island"

L["panel_footer_hint"] = "Hover to view · drag to move"
L["panel_updated_now"] = "Updated just now"

L["animate"] = "Animate expand/collapse"
L["animate_desc"] = "Smoothly grow the island on hover instead of snapping instantly."
