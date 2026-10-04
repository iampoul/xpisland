local ADDON_NAME, ns = ...
local L = ns.L
local AceAddon = LibStub("AceAddon-3.0")
local AceDB = LibStub("AceDB-3.0")

local defaults = {
	profile = {
		locked = false,
		width = 220,
		scale = 1.0,
		alpha = 0.8,
		showBarText = true,
		showMinimapIcon = true,
		animate = true,
		splitSources = true,
		lastLevel = 1,
		point = "CENTER",
		relPoint = "CENTER",
		x = 0,
		y = -260,

		-- Expanded panel rows. Every row is independently toggleable.
		showSessionRate = true,
		showLevelRate = false,
		showSessionTime = true,
		showLevelTime = true,
		showXP = true,
		showRested = true,
		showPlayed = true,
		showKills = true,
		showQuests = true,
		showSessionXP = false,
		showETA = true,
	},
	global = {},
}

-- Use the actual AddOn name provided by the engine (the .toc basename) so
-- AceAddon registers the same name the client expects. Using a hard-coded
-- different string can prevent the addon lifecycle (OnInitialize, slash
-- registration, etc.) from behaving correctly.
local addon = AceAddon:NewAddon(ADDON_NAME, "AceConsole-3.0")
ns.Addon = addon

function addon:OnInitialize()
	self.db = AceDB:New(ADDON_NAME .. "DB", defaults, true)

	-- Modules are plain tables on the namespace; hang them off the addon so
	-- event handlers can reach them.
	self.Stats = ns.Stats
	self.Bar = ns.Bar
	self.Panel = ns.Panel
	self.Options = ns.Options

	self.version = (C_AddOns and C_AddOns.GetAddOnMetadata)
		and C_AddOns.GetAddOnMetadata(ADDON_NAME, "Version") or ns.VERSION

	self.Stats:Initialize(self.db)
	self.Stats:RegisterListener(function(data) self:OnData(data) end)

	self.Bar:Create()
	self.Panel:Create()
	self.Options:Register()

	self:RegisterChatCommand("xp", "HandleSlash")
	self:RegisterChatCommand("xpisland", "HandleSlash")

	self:ApplySettings()
	self:RegisterMinimapIcon()

	self:Print(("v%s loaded. Type /xp for options."):format(tostring(self.version)))
end

function addon:ApplySettings()
	if self.Bar then self.Bar:ApplySettings() end
	if self.Panel then self.Panel:ApplySettings() end
	self:UpdateMinimapIcon()
end

function addon:HandleSlash(input)
	local cmd = input:match("^(%S*)") or ""
	cmd = cmd:lower()

	if cmd == "lock" then
		self.db.profile.locked = true
		self:ApplySettings()
		self:Print(L["locked_desc"])

	elseif cmd == "unlock" then
		self.db.profile.locked = false
		self:ApplySettings()
		self:Print(L["locked_desc"])

	elseif cmd == "reset" then
		self.Stats:Reset()
		self:Print(L["reset_stats_done"])

	elseif cmd == "resetpos" then
		self.db.profile.point, self.db.profile.relPoint = "CENTER", "CENTER"
		self.db.profile.x, self.db.profile.y = 0, -260
		self:ApplySettings()
		self:Print(L["reset_position_desc"])

	elseif cmd == "toggle" then
		self.db.profile.locked = not self.db.profile.locked
		self:ApplySettings()
		self:Print(L["locked_desc"])

	else
		LibStub("AceConfigDialog-3.0"):Open(ADDON_NAME)
	end
end

function addon:Print(msg)
	if DEFAULT_CHAT_FRAME then
		DEFAULT_CHAT_FRAME:AddMessage("|cff33ff99XP Island|r: " .. tostring(msg))
	end
end

function addon:RegisterMinimapIcon()
	local ldb = LibStub("LibDataBroker-1.1", true)
	local icon = LibStub("LibDBIcon-1.0", true)
	if not ldb or not icon then return end

	-- Registration is idempotent, this only has to happen once.
	if self.minimapObject then return end

	self.minimapObject = ldb:NewDataObject(ADDON_NAME, {
		type = "data source",
		label = L["name"],
		text = "XP",
		icon = "Interface\\Icons\\Spell_Nature_StarFall",
		OnClick = function(frame, button)
			if button == "RightButton" then
				self.db.profile.locked = not self.db.profile.locked
				self:ApplySettings()
			else
				LibStub("AceConfigDialog-3.0"):Open(ADDON_NAME)
			end
		end,
		OnTooltipShow = function(tt)
			tt:AddLine(L["name"])
			tt:AddLine(L["xp_tooltip"], 1, 1, 1)
			tt:AddLine(L["locked_tooltip"], 1, 1, 1)
		end,
	})

	-- LibDBIcon stores its position on the table it is handed, so give it the
	-- profile so the icon position persists with the rest of the settings.
	icon:Register(ADDON_NAME, self.minimapObject, self.db.profile)
end

function addon:UpdateMinimapIcon()
	local icon = LibStub("LibDBIcon-1.0", true)
	if not icon then return end

	self:RegisterMinimapIcon()

	if self.db.profile.showMinimapIcon then
		icon:Show(ADDON_NAME)
	else
		icon:Hide(ADDON_NAME)
	end
end

function addon:OnEnter()
	if self.collapseTimer then
		self.collapseTimer:Cancel()
		self.collapseTimer = nil
	end

	-- Expand the pill fully before fading the stats panel in underneath it,
	-- so the panel never appears wider than the (still animating) pill.
	if self.Bar then
		self.Bar:Expand(function()
			if self.Panel then self.Panel:Show() end
		end)
	elseif self.Panel then
		self.Panel:Show()
	end

	self.Stats:StartPlayedTimePolling()
end

function addon:OnLeave()
	if self.collapseTimer then
		self.collapseTimer:Cancel()
	end

	-- Small delay so moving from the bar onto the panel below it doesn't
	-- cause a flicker; cancelled above if the mouse re-enters in time.
	self.collapseTimer = C_Timer.NewTimer(0.08, function()
		self.collapseTimer = nil

		-- Double-check: if the mouse is actually still over the bar or the
		-- panel (e.g. it only grazed the gap between them for a tick), skip
		-- the collapse instead of flickering open/closed.
		local overBar = self.Bar and self.Bar.frame and self.Bar.frame:IsMouseOver()
		local overPanel = self.Panel and self.Panel.frame and self.Panel.frame:IsMouseOver()
		if overBar or overPanel then return end

		-- Reverse order: fade the panel out first, then shrink the pill,
		-- matching the expand sequence in reverse.
		if self.Panel then
			self.Panel:Hide(function()
				if self.Bar then self.Bar:Collapse() end
			end)
		elseif self.Bar then
			self.Bar:Collapse()
		end

		self.Stats:StopPlayedTimePolling()
	end)
end

function addon:OnData(data)
	if self.Bar then self.Bar:Update(data) end
	if self.Panel then self.Panel:Update(data) end
end
