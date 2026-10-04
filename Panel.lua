local ADDON_NAME, ns = ...
local L = ns.L

local Panel = {}
ns.Panel = Panel

local COLS = 4
local PADDING = 16
local COL_GUTTER = 18
local ROW_GAP = 14
local CELL_HEIGHT = 34
local TOP_OFFSET = 20   -- top margin
local BOTTOM_OFFSET = 16 -- bottom margin
local FADE_IN_DURATION = 0.2
local FADE_OUT_DURATION = 0.12

local BACKDROP = {
	bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
	edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
	tile = true, tileSize = 16, edgeSize = 14,
	insets = { left = 3, right = 3, top = 3, bottom = 3 },
}

local COLOR_BG = { 0.0, 0.0, 0.0, 0.95 }
local COLOR_BORDER = { 0.84, 0.71, 0.29, 1 }
local COLOR_GOLD = { 0.84, 0.71, 0.29 }
local COLOR_WHITE = { 1, 1, 1 }
local COLOR_RESTED = { 0.4, 0.68, 0.95 }

local function TryBackdrop(frame, backdrop, bg, border)
	if not frame.SetBackdrop then return end
	frame:SetBackdrop(backdrop)
	if bg then frame:SetBackdropColor(unpack(bg)) end
	if border then frame:SetBackdropBorderColor(unpack(border)) end
end

-- Row definitions. "key" is the profile setting that toggles the row.
-- "color" optionally overrides the value text color.
function Panel:BuildRowList()
	return {
		{ key = "showXP", label = L["row_xp"],
			value = function(d) return string.format("%s / %s", ns.FormatThousands(d.currentXP), ns.FormatThousands(d.maxXP)) end },

		{ key = "showRested", label = L["row_rested"], color = COLOR_RESTED,
			value = function(d)
				if d.restedXP <= 0 then return L["none"] end
				return ns.FormatThousands(d.restedXP)
			end },

		{ key = "showSessionXP", label = L["row_session_xp"],
			value = function(d) return ns.FormatThousands(d.sessionXP) end },

		{ key = "showSessionRate", label = L["row_session_rate"],
			value = function(d)
				if d.sessionRate <= 0 then return "--" end
				return ns.FormatRate(d.sessionRate)
			end },

		{ key = "showSessionTime", label = L["row_session_time"],
			value = function(d) return ns.FormatDuration(d.sessionTime) end },

		{ key = "showLevelTime", label = L["row_level_time"],
			value = function(d) return ns.FormatDuration(d.levelTime) end },

		{ key = "showPlayed", label = L["row_played"],
			value = function(d) return ns.FormatDuration(d.playedTime) end },

		{ key = "showQuests", label = L["row_quests"],
			value = function(d) return ns.FormatThousands(d.questXP) end },

		{ key = "showKills", label = L["row_kills"],
			value = function(d) return ns.FormatThousands(d.killXP) end },

		{ key = "showLevelRate", label = L["row_level_rate"],
			value = function(d)
				if d.levelRate <= 0 then return "--" end
				return ns.FormatRate(d.levelRate)
			end },

		{ key = "showETA", label = L["row_eta"],
			value = function(d)
				if not d.eta then return L["na"] end
				return ns.FormatDuration(d.eta)
			end },
	}
end

function Panel:Create()
	local addon = ns.Addon

	local frame = CreateFrame("Frame", "XPIslandPanel", addon.Bar.frame, "BackdropTemplate")
	frame:SetFrameStrata("DIALOG")
	frame:SetPoint("TOPLEFT", addon.Bar.frame, "BOTTOMLEFT", 0, 0)
	TryBackdrop(frame, BACKDROP, COLOR_BG, COLOR_BORDER)
	frame:SetAlpha(0)

	-- Mouse enabled so moving from the bar onto the panel does not collapse it.
	frame:EnableMouse(true)
	frame:SetScript("OnEnter", function() addon:OnEnter() end)
	frame:SetScript("OnLeave", function() addon:OnLeave() end)

	-- Same hover buffer as the pill (see Bar.lua) so the exact edge pixel
	-- doesn't flicker the hover state in and out.
	if frame.SetHitRectInset then
		frame:SetHitRectInset(-8, -8, 0, -8)
	end

	frame:Hide()
	self.frame = frame

	self.rows = {}
	self.visibleRows = 0

	-- Faint vertical dividers between columns, purely decorative.
	self.dividers = {}
	for i = 1, COLS - 1 do
		local divider = frame:CreateTexture(nil, "ARTWORK")
		divider:SetColorTexture(1, 1, 1, 0.08)
		divider:SetWidth(1)
		self.dividers[i] = divider
	end

	self:ApplySettings()
end

function Panel:CreateRow(def)
	local frame = self.frame

	local label = frame:CreateFontString(nil, "ARTWORK", "GameFontNormalSmall")
	label:SetJustifyH("LEFT")
	label:SetTextColor(unpack(COLOR_GOLD))
	label:SetText(def.label)

	local value = frame:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
	value:SetJustifyH("LEFT")

	return { def = def, label = label, value = value }
end

function Panel:LayoutRows()
	local frame = self.frame
	local width = frame:GetWidth() or 440
	local usable = width - PADDING * 2
	local colWidth = (usable - COL_GUTTER * (COLS - 1)) / COLS

	for i = 1, #self.rows do
		local row = self.rows[i]
		local col = (i - 1) % COLS
		local line = math.floor((i - 1) / COLS)

		local x = PADDING + col * (colWidth + COL_GUTTER)
		local y = -(TOP_OFFSET + line * (CELL_HEIGHT + ROW_GAP))

		row.label:ClearAllPoints()
		row.value:ClearAllPoints()
		row.label:SetPoint("TOPLEFT", frame, "TOPLEFT", x, y)
		row.label:SetWidth(colWidth)
		row.value:SetPoint("TOPLEFT", frame, "TOPLEFT", x, y - 16)
		row.value:SetWidth(colWidth)

		if row.def.color then
			row.value:SetTextColor(unpack(row.def.color))
		else
			row.value:SetTextColor(unpack(COLOR_WHITE))
		end
	end

	-- Dividers sit halfway through each gutter, spanning from just below the
	-- top margin to just above the bottom margin.
	local lines = math.max(1, math.ceil(self.visibleRows / COLS))
	local gridHeight = lines * CELL_HEIGHT + (lines - 1) * ROW_GAP

	for i = 1, COLS - 1 do
		local divider = self.dividers[i]
		local x = PADDING + i * colWidth + (i - 1) * COL_GUTTER + COL_GUTTER / 2

		divider:ClearAllPoints()
		divider:SetPoint("TOPLEFT", frame, "TOPLEFT", x, -(TOP_OFFSET - 4))
		divider:SetHeight(gridHeight + 4)

		-- Only show a divider if at least one visible row actually has a
		-- cell to its right (avoids a stray line past a short last row).
		if self.visibleRows > i then
			divider:Show()
		else
			divider:Hide()
		end
	end
end

function Panel:ApplySettings()
	if not self.frame then return end

	local profile = ns.Addon.db.profile
	local defs = self:BuildRowList()

	-- Reuse row objects so we do not churn frames every time a toggle flips.
	local active = {}
	for _, def in ipairs(defs) do
		if profile[def.key] then
			table.insert(active, def)
		end
	end

	for i, def in ipairs(active) do
		local row = self.rows[i]

		if not row then
			row = self:CreateRow(def)
			self.rows[i] = row
		end

		row.def = def
		row.label:SetText(def.label)
		row.label:Show()
		row.value:Show()
	end

	for i = #active + 1, #self.rows do
		local row = self.rows[i]
		row.label:Hide()
		row.value:Hide()
	end

	self.visibleRows = #active
	self:UpdateLayout()
end

function Panel:UpdateLayout()
	local frame = self.frame
	if not frame then return end

	local width = ns.Addon.Bar.expandedWidth or 440
	local lines = math.max(1, math.ceil(self.visibleRows / COLS))
	local height = TOP_OFFSET + lines * CELL_HEIGHT + (lines - 1) * ROW_GAP + BOTTOM_OFFSET

	frame:SetSize(width, height)
	self:LayoutRows()
end

function Panel:Show()
	if not self.frame then return end

	self.frame:Show()
	ns.StopAnimation(self.frame)

	if ns.Addon.db.profile.animate == false then
		self.frame:SetAlpha(1)
		self.shown = true
		return
	end

	self.shown = true
	ns.Animate(self.frame, self.frame:GetAlpha(), 1, FADE_IN_DURATION, function(f, a) f:SetAlpha(a) end)
end

function Panel:Hide(onComplete)
	if not self.frame or not self.shown then
		if onComplete then onComplete() end
		return
	end

	self.shown = false
	ns.StopAnimation(self.frame)

	if ns.Addon.db.profile.animate == false then
		self.frame:SetAlpha(0)
		self.frame:Hide()
		if onComplete then onComplete() end
		return
	end

	local frame = self.frame
	ns.Animate(frame, frame:GetAlpha(), 0, FADE_OUT_DURATION, function(f, a) f:SetAlpha(a) end, function(f)
		if not Panel.shown then f:Hide() end
		if onComplete then onComplete() end
	end)
end

function Panel:Update(data)
	if not self.frame or not data then return end

	for i = 1, self.visibleRows do
		local row = self.rows[i]
		if row and row.def then
			row.value:SetText(row.def.value(data))
		end
	end
end
