local ADDON_NAME, ns = ...
local L = ns.L

local Bar = {}
ns.Bar = Bar

local COLLAPSED_HEIGHT = 40
local EXPAND_DURATION = 0.18
local COLLAPSE_DURATION = 0.11
local EXTRA_EXPAND_WIDTH = 240
local MIN_EXPANDED_WIDTH = 440

local FRAME_BACKDROP = {
	bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
	edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
	tile = true, tileSize = 16, edgeSize = 14,
	insets = { left = 3, right = 3, top = 3, bottom = 3 },
}

local ICON_BACKDROP = {
	bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
	edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
	tile = true, tileSize = 8, edgeSize = 8,
	insets = { left = 2, right = 2, top = 2, bottom = 2 },
}

local STATUSBAR_TEXTURE = "Interface\\TargetingFrame\\UI-StatusBar"

local COLOR_BG = { 0.0, 0.0, 0.0, 0.92 }
local COLOR_BORDER = { 0.84, 0.71, 0.29, 1 }
local COLOR_ICON_BG = { 0.0, 0.0, 0.0, 1 }
local COLOR_GOLD = { 0.84, 0.71, 0.29 }
local COLOR_WHITE = { 1, 1, 1 }
local COLOR_TRACK = { 0.0, 0.0, 0.0, 1 }
local COLOR_FILL = { 0.64, 0.33, 0.82, 1 }
local COLOR_RESTED = { 0.95, 0.78, 0.2, 0.9 }

-- Small helper: applies SetBackdrop defensively since some client builds
-- don't expose it the same way.
local function TryBackdrop(frame, backdrop, bg, border)
	if not frame.SetBackdrop then return end
	frame:SetBackdrop(backdrop)
	if bg then frame:SetBackdropColor(unpack(bg)) end
	if border then frame:SetBackdropBorderColor(unpack(border)) end
end

function Bar:Create()
	local addon = ns.Addon
	local profile = addon.db.profile

	local frame = CreateFrame("Frame", "XPIslandBar", UIParent, "BackdropTemplate")
	frame:SetSize(profile.width, COLLAPSED_HEIGHT)
	frame:SetFrameStrata("MEDIUM")
	frame:SetClampedToScreen(true)
	frame:SetMovable(not profile.locked)
	frame:EnableMouse(true)
	TryBackdrop(frame, FRAME_BACKDROP, COLOR_BG, COLOR_BORDER)

	-- Enlarge the invisible hover-detection area a little beyond the visible
	-- pill. Without this, a cursor sitting exactly on the edge pixel can
	-- flicker in/out of "mouse over" every frame as it renders.
	if frame.SetHitRectInset then
		frame:SetHitRectInset(-8, -8, -6, -6)
	end

	self.frame = frame
	self.collapsedWidth = profile.width
	self.expandedWidth = math.max(profile.width + EXTRA_EXPAND_WIDTH, MIN_EXPANDED_WIDTH)
	self.expanded = false

	-- Level badge on the left, styled like a standard icon slot button.
	local icon = CreateFrame("Frame", nil, frame, "BackdropTemplate")
	icon:SetSize(COLLAPSED_HEIGHT - 10, COLLAPSED_HEIGHT - 10)
	icon:SetPoint("LEFT", frame, "LEFT", 6, 0)
	TryBackdrop(icon, ICON_BACKDROP, COLOR_ICON_BG, COLOR_GOLD)
	frame.icon = icon

	-- A gold icon-slot ring, same texture Blizzard uses on spell/item icons.
	local iconRing = icon:CreateTexture(nil, "OVERLAY")
	iconRing:SetTexture("Interface\\Common\\WhiteIconFrame")
	iconRing:SetVertexColor(unpack(COLOR_GOLD))
	iconRing:SetPoint("TOPLEFT", icon, "TOPLEFT", -3, 3)
	iconRing:SetPoint("BOTTOMRIGHT", icon, "BOTTOMRIGHT", 3, -3)
	icon.ring = iconRing

	local iconText = icon:CreateFontString(nil, "OVERLAY", "GameFontNormal")
	iconText:SetPoint("CENTER")
	iconText:SetTextColor(unpack(COLOR_WHITE))
	icon.text = iconText

	-- Content area to the right of the icon: label/value row + progress track.
	local content = CreateFrame("Frame", nil, frame)
	content:SetPoint("TOPLEFT", icon, "TOPRIGHT", 10, -2)
	content:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -10, 4)
	frame.content = content

	-- Percent sits top-right; the value label fills the remaining space to
	-- its left so the two never overlap regardless of text length.
	local percent = content:CreateFontString(nil, "OVERLAY", "GameFontNormal")
	percent:SetPoint("TOPRIGHT", content, "TOPRIGHT", 0, 2)
	percent:SetTextColor(unpack(COLOR_WHITE))
	frame.percent = percent

	local value = content:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
	value:SetPoint("TOPLEFT", content, "TOPLEFT", 0, 0)
	value:SetPoint("RIGHT", percent, "LEFT", -10, 0)
	value:SetJustifyH("LEFT")
	value:SetTextColor(unpack(COLOR_WHITE))
	frame.value = value

	-- Progress track, pinned to the bottom of the content area so it always
	-- spans the full width even while the island is mid-animation.
	local track = CreateFrame("Frame", nil, content, "BackdropTemplate")
	track:SetHeight(9)
	track:SetPoint("BOTTOMLEFT", content, "BOTTOMLEFT", 0, 0)
	track:SetPoint("BOTTOMRIGHT", content, "BOTTOMRIGHT", 0, 0)
	TryBackdrop(track, ICON_BACKDROP, COLOR_TRACK, COLOR_GOLD)
	frame.track = track

	-- Same statusbar texture Blizzard uses for health/mana/XP bars, tinted
	-- to match, instead of a flat color fill.
	local rested = track:CreateTexture(nil, "ARTWORK")
	rested:SetTexture(STATUSBAR_TEXTURE)
	rested:SetVertexColor(unpack(COLOR_RESTED))
	rested:SetPoint("TOPLEFT", track, "TOPLEFT", 2, -2)
	rested:SetPoint("BOTTOMLEFT", track, "BOTTOMLEFT", 2, 2)
	frame.restedTex = rested

	local fill = track:CreateTexture(nil, "ARTWORK", nil, 1)
	fill:SetTexture(STATUSBAR_TEXTURE)
	fill:SetVertexColor(unpack(COLOR_FILL))
	fill:SetPoint("TOPLEFT", track, "TOPLEFT", 2, -2)
	fill:SetPoint("BOTTOMLEFT", track, "BOTTOMLEFT", 2, 2)
	frame.fillTex = fill

	-- Thin highlight line along the top of the track for a bit of shine,
	-- same trick Blizzard uses on action button glows.
	local sheen = track:CreateTexture(nil, "ARTWORK", nil, 2)
	sheen:SetColorTexture(1, 1, 1, 0.18)
	sheen:SetPoint("TOPLEFT", track, "TOPLEFT", 2, -2)
	sheen:SetPoint("TOPRIGHT", track, "TOPRIGHT", -2, -2)
	sheen:SetHeight(2)
	frame.sheen = sheen

	frame:SetScript("OnEnter", function() addon:OnEnter() end)
	frame:SetScript("OnLeave", function() addon:OnLeave() end)

	frame:SetScript("OnMouseDown", function(self, button)
		if button ~= "LeftButton" then return end

		if profile.locked then
			addon:Print(L["locked_tooltip"])
		else
			self:StartMoving()
		end
	end)

	frame:SetScript("OnMouseUp", function(self)
		self:StopMovingOrSizing()

		-- Always store the position as a CENTER anchor (regardless of which
		-- corner WoW reports from the drag) so expand/collapse always grows
		-- symmetrically. Anything else causes the island to grow/shrink from
		-- a corner, which can chase the cursor and flicker near an edge.
		local cx, cy = self:GetCenter()
		local pcx, pcy = UIParent:GetCenter()
		profile.point, profile.relPoint = "CENTER", "CENTER"
		profile.x, profile.y = (cx or 0) - (pcx or 0), (cy or 0) - (pcy or 0)
	end)

	self:ApplySettings()
	self:Update(ns.Stats:GetData())
end

function Bar:ApplySettings()
	local profile = ns.Addon.db.profile
	local frame = self.frame
	if not frame then return end

	self.collapsedWidth = profile.width
	self.expandedWidth = math.max(profile.width + EXTRA_EXPAND_WIDTH, MIN_EXPANDED_WIDTH)

	if not self.expanded then
		frame:SetWidth(profile.width)
	end

	frame:SetScale(profile.scale)
	if frame.SetBackdropColor then
		frame:SetBackdropColor(COLOR_BG[1], COLOR_BG[2], COLOR_BG[3], profile.alpha)
	end
	frame:SetMovable(not profile.locked)

	local point = profile.point or "CENTER"
	frame:ClearAllPoints()
	frame:SetPoint(point, UIParent, profile.relPoint or point, profile.x or 0, profile.y or -260)

	if profile.showBarText then
		frame.value:Show()
	else
		frame.value:Hide()
	end

	self:Reflow()
end

-- Smoothly grows the island. Anchored on CENTER by default so it widens
-- evenly left/right; for other anchors it will grow from that corner.
function Bar:Expand(onComplete)
	local frame = self.frame
	if not frame then return end

	if self.expanded then
		if onComplete then onComplete() end
		return
	end

	if ns.Addon.db.profile.animate == false then
		frame:SetWidth(self.expandedWidth)
		self:Reflow()
		self.expanded = true
		if onComplete then onComplete() end
		return
	end

	self.expanded = true
	ns.Animate(frame, frame:GetWidth(), self.expandedWidth, EXPAND_DURATION, function(f, w)
		f:SetWidth(w)
		self:Reflow()
	end, function()
		if onComplete then onComplete() end
	end)
end

function Bar:Collapse(onComplete)
	local frame = self.frame
	if not frame then return end

	if not self.expanded then
		if onComplete then onComplete() end
		return
	end

	if ns.Addon.db.profile.animate == false then
		frame:SetWidth(self.collapsedWidth)
		self:Reflow()
		self.expanded = false
		if onComplete then onComplete() end
		return
	end

	self.expanded = false
	ns.Animate(frame, frame:GetWidth(), self.collapsedWidth, COLLAPSE_DURATION, function(f, w)
		f:SetWidth(w)
		self:Reflow()
	end, function()
		if onComplete then onComplete() end
	end)
end

-- Re-applies the last known data to the (possibly resized) fill bars so the
-- progress stays correct while the island animates.
function Bar:Reflow()
	if self.lastData then
		self:Update(self.lastData)
	end
end

function Bar:Update(data)
	local frame = self.frame
	if not frame or not data then return end

	self.lastData = data

	local trackWidth = frame.track:GetWidth() or 1
	local inner = math.max(0, trackWidth - 4)
	local max = data.maxXP

	local fillFrac = 0
	local restedFrac = 0

	if max > 0 then
		fillFrac = math.max(0, math.min(1, data.currentXP / max))

		local rested = math.min(data.restedXP, max - data.currentXP)
		restedFrac = math.max(0, math.min(1 - fillFrac, rested / max))
	end

	frame.fillTex:SetWidth(math.max(0.0001, inner * fillFrac))
	frame.restedTex:SetWidth(math.max(0.0001, inner * (fillFrac + restedFrac)))

	frame.icon.text:SetText(tostring(data.level))
	frame.value:SetText(string.format("%s / %s", ns.FormatThousands(data.currentXP), ns.FormatThousands(data.maxXP)))
	frame.percent:SetText(ns.FormatPercent(data.currentXP, data.maxXP))
end
