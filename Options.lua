local ADDON_NAME, ns = ...
local L = ns.L
local AceConfig = LibStub("AceConfig-3.0")

local Options = {}
ns.Options = Options

local function get(info)
	return ns.Addon.db.profile[info[#info]]
end

local function set(info, value)
	ns.Addon.db.profile[info[#info]] = value
	ns.Addon:ApplySettings()
end

function Options:Register()
	local options = {
		type = "group",
		name = L["name"],
		childGroups = "tab",
		args = {
			info = {
				type = "group",
				name = L["info"],
				order = 1,
				args = {
					header = {
						type = "header",
						name = L["info"],
						order = 1,
					},

					showSessionRate = {
						type = "toggle",
						name = L["show_xphr"],
						desc = L["show_xphr_desc"],
						order = 2,
						get = get, set = set,
					},
					showLevelRate = {
						type = "toggle",
						name = L["show_levelxphr"],
						desc = L["show_levelxphr_desc"],
						order = 3,
						get = get, set = set,
					},
					showSessionTime = {
						type = "toggle",
						name = L["show_session_time"],
						desc = L["show_session_time_desc"],
						order = 4,
						get = get, set = set,
					},
					showLevelTime = {
						type = "toggle",
						name = L["show_level_time"],
						desc = L["show_level_time_desc"],
						order = 5,
						get = get, set = set,
					},
					showXP = {
						type = "toggle",
						name = L["show_xp"],
						desc = L["show_xp_desc"],
						order = 6,
						get = get, set = set,
					},
					showRested = {
						type = "toggle",
						name = L["show_rested"],
						desc = L["show_rested_desc"],
						order = 7,
						get = get, set = set,
					},
					showPlayed = {
						type = "toggle",
						name = L["show_played"],
						desc = L["show_played_desc"],
						order = 8,
						get = get, set = set,
					},
					showKills = {
						type = "toggle",
						name = L["show_kills"],
						desc = L["show_kills_desc"],
						order = 9,
						get = get, set = set,
					},
					showQuests = {
						type = "toggle",
						name = L["show_quests"],
						desc = L["show_quests_desc"],
						order = 10,
						get = get, set = set,
					},
					showSessionXP = {
						type = "toggle",
						name = L["show_session_xp"],
						desc = L["show_session_xp_desc"],
						order = 11,
						get = get, set = set,
					},
					showETA = {
						type = "toggle",
						name = L["show_eta"],
						desc = L["show_eta_desc"],
						order = 12,
						get = get, set = set,
					},
				},
			},

			bar = {
				type = "group",
				name = L["bar"],
				order = 2,
				args = {
					header = {
						type = "header",
						name = L["bar"],
						order = 1,
					},
					locked = {
						type = "toggle",
						name = L["locked"],
						desc = L["locked_desc"],
						order = 2,
						get = get, set = set,
					},
					lock_toggle = {
						type = "execute",
						name = L["lock_toggle"],
						desc = L["lock_toggle_desc"],
						order = 3,
						func = function()
							ns.Addon.db.profile.locked = not ns.Addon.db.profile.locked
							ns.Addon:ApplySettings()
						end,
					},
					reset_position = {
						type = "execute",
						name = L["reset_position"],
						desc = L["reset_position_desc"],
						order = 4,
						func = function()
							local profile = ns.Addon.db.profile
							profile.point, profile.relPoint = "CENTER", "CENTER"
							profile.x, profile.y = 0, -260
							ns.Addon:ApplySettings()
						end,
					},
					width = {
						type = "range",
						name = L["width"],
						desc = L["width_desc"],
						order = 5,
						min = 120, max = 500, step = 5,
						get = get, set = set,
					},
					scale = {
						type = "range",
						name = L["scale"],
						desc = L["scale_desc"],
						order = 6,
						min = 0.5, max = 2.0, step = 0.05,
						get = get, set = set,
					},
					alpha = {
						type = "range",
						name = L["alpha"],
						desc = L["alpha_desc"],
						order = 7,
						min = 0.0, max = 1.0, step = 0.05,
						get = get, set = set,
					},
					showBarText = {
						type = "toggle",
						name = L["show_barname"],
						desc = L["show_barname_desc"],
						order = 8,
						get = get, set = set,
					},
					animate = {
						type = "toggle",
						name = L["animate"],
						desc = L["animate_desc"],
						order = 9,
						get = get, set = set,
					},
				},
			},

			advanced = {
				type = "group",
				name = L["advanced"],
				order = 3,
				args = {
					header = {
						type = "header",
						name = L["advanced"],
						order = 1,
					},
					showMinimapIcon = {
						type = "toggle",
						name = L["show_minimap"],
						desc = L["show_minimap_desc"],
						order = 2,
						get = get, set = set,
					},
					splitSources = {
						type = "toggle",
						name = L["split_sources"],
						desc = L["split_sources_desc"],
						order = 3,
						get = get, set = set,
					},
					reset_stats = {
						type = "execute",
						name = L["reset_stats"],
						desc = L["reset_stats_desc"],
						order = 4,
						func = function()
							ns.Stats:Reset()
							ns.Addon:Print(L["reset_stats_done"])
						end,
					},
				},
			},
		},
	}

	AceConfig:RegisterOptionsTable(ADDON_NAME, options)
end