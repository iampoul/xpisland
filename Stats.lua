local ADDON_NAME, ns = ...
local L = ns.L
local AceEvent = LibStub("AceEvent-3.0")
local AceTimer = LibStub("AceTimer-3.0")

local Stats = {}
ns.Stats = Stats

-- Session-scoped state lives in the AceDB global table so a /reload does not
-- wipe the timers or the XP totals. lastLevel/lastXP are what let XP keep
-- accumulating correctly across a reload.
local DEFAULT_GLOBAL = {
	sessionStart = 0,
	sessionXP = 0,
	levelStart = 0,
	lastLevel = 0,
	lastXP = 0,
	killXP = 0,
	questXP = 0,
	playedTotal = 0,
	playedStamp = 0,
	levelMaxXP = {},
}

function Stats:Initialize(db)
	self.db = db

	local g = db.global
	for k, v in pairs(DEFAULT_GLOBAL) do
		if g[k] == nil then
			g[k] = v
		end
	end
	if type(g.levelMaxXP) ~= "table" then g.levelMaxXP = {} end

	local now = time()
	local level = UnitLevel("player") or 1

	if g.sessionStart == 0 then g.sessionStart = now end
	if g.playedStamp == 0 then g.playedStamp = now end

	-- A brand new session starts counting from wherever the character is now.
	if g.lastLevel == 0 then
		g.lastLevel = level
		g.lastXP = UnitXP("player") or 0
	end

	-- Level time survives a reload but starts fresh if we loaded mid-level and
	-- have no prior record, otherwise it would count from account creation.
	if g.levelStart == 0 then
		g.levelStart = now
	end

	self.listeners = {}

	AceEvent:Embed(self)
	self:RegisterEvent("PLAYER_ENTERING_WORLD")
	self:RegisterEvent("PLAYER_LEVEL_UP")
	self:RegisterEvent("PLAYER_XP_UPDATE")
	self:RegisterEvent("UPDATE_EXHAUSTION")
	self:RegisterEvent("CHAT_MSG_COMBAT_XP_GAIN")
	self:RegisterEvent("TIME_PLAYED_MSG")

	AceTimer:Embed(self)
	self:ScheduleRepeatingTimer(function() self:Fire() end, 1)

	-- Remember the max XP of every level we are on, so completed levels can be
	-- summed up later once UnitXPMax no longer reports them.
	self:TrackLevelMax()

	self:RequestPlayedTime()
end

function Stats:RequestPlayedTime()
	if C_TimePlayed and C_TimePlayed.RequestTimePlayed then
		C_TimePlayed.RequestTimePlayed()
	elseif RequestTimePlayed then
		RequestTimePlayed()
	end
end

-- Time played only refreshes when asked, so poll while the panel is open.
function Stats:StartPlayedTimePolling()
	if self.playedPoll then return end

	self:RequestPlayedTime()
	self.playedPoll = self:ScheduleRepeatingTimer(function()
		self:RequestPlayedTime()
	end, 300)
end

function Stats:StopPlayedTimePolling()
	if not self.playedPoll then return end

	self:CancelTimer(self.playedPoll)
	self.playedPoll = nil
end

-- TIME_PLAYED_MSG arrives as "Total: a | Level: b | Played: c"
function Stats:TIME_PLAYED_MSG(total, level, played)
	local seconds = ns.ParsePlayedTime(played)

	if seconds > 0 then
		self.db.global.playedTotal = seconds
		self.db.global.playedStamp = time()
		self:Fire()
	end
end

function Stats:PLAYER_ENTERING_WORLD()
	self:RequestPlayedTime()
	self:TrackLevelMax()
	self:Fire()
end

-- All XP accounting happens here. PLAYER_LEVEL_UP only needs to nudge the UI so
-- the level number updates immediately, the counter catches up on the next tick.
function Stats:PLAYER_LEVEL_UP(level)
	self.db.profile.lastLevel = level
	self:Fire()
end

function Stats:PLAYER_XP_UPDATE()
	local g = self.db.global
	local level = UnitLevel("player") or 1
	local current = UnitXP("player") or 0

	self:TrackLevelMax()

	if level > g.lastLevel then
		-- Leveled up. Credit the full max XP of every level we just finished,
		-- using the values captured while we were still on those levels.
		for lvl = g.lastLevel, (level - 1) do
			g.sessionXP = g.sessionXP + (g.levelMaxXP[lvl] or 0)
		end

		g.levelStart = time()
		g.lastLevel = level
		g.lastXP = current
	else
		local delta = current - g.lastXP

		-- XP within a level only ever grows, so a negative delta means something
		-- else happened (a level up we already handled, or a quest rescaling XP).
		if delta > 0 then
			g.sessionXP = g.sessionXP + delta
		end

		g.lastXP = current
	end

	self:Fire()
end

function Stats:UPDATE_EXHAUSTION()
	self:Fire()
end

-- Split combat XP into kills vs quests. Chat messages are only used for the
-- breakdown; the headline totals always come from the XP counter so nothing is
-- lost when a message is missed.
function Stats:CHAT_MSG_COMBAT_XP_GAIN(msg)
	local amount = tonumber(msg:match("(%d+)%s+experience"))
	if not amount then return end

	local g = self.db.global

	if self.db.profile.splitSources then
		if msg:find("[Qq]uest") then
			g.questXP = (g.questXP or 0) + amount
		else
			g.killXP = (g.killXP or 0) + amount
		end
	else
		g.killXP = (g.killXP or 0) + amount
	end

	self:Fire()
end

function Stats:TrackLevelMax()
	local max = UnitXPMax("player") or 0
	local level = UnitLevel("player") or 1

	if max > 0 and self.db.global.levelMaxXP[level] == nil then
		self.db.global.levelMaxXP[level] = max
	end
end

function Stats:GetRestedXP()
	if C_PlayerInfo and C_PlayerInfo.GetXPExhaustion then
		return C_PlayerInfo.GetXPExhaustion() or 0
	end
	if GetXPExhaustion then
		return GetXPExhaustion() or 0
	end
	return 0
end

function Stats:GetData()
	local g = self.db.global
	local now = time()

	local level = UnitLevel("player") or 1
	local current = UnitXP("player") or 0
	local max = UnitXPMax("player") or 0
	local rested = self:GetRestedXP()

	local sessionTime = math.max(0, now - (g.sessionStart or now))
	local levelTime = math.max(0, now - (g.levelStart or now))
	local sessionXP = math.max(0, g.sessionXP or 0)

	-- XP banked on the level you are currently on. UnitXP restarts at 0 on a
	-- level up, which is exactly what this row wants.
	local levelXP = math.max(0, current)

	-- Played time is the server value plus everything elapsed since it arrived,
	-- which keeps counting up smoothly between polls.
	local played = (g.playedTotal or 0) + math.max(0, now - (g.playedStamp or now))

	-- Ignore the first few seconds so the rate is not absurd right after login.
	local sessionRate = sessionTime > 10 and (sessionXP / sessionTime) * 3600 or 0
	local levelRate = levelTime > 10 and (levelXP / levelTime) * 3600 or 0

	local remaining = math.max(0, max - current)
	local eta = levelRate > 0 and (remaining / levelRate) * 3600 or nil

	return {
		level = level,
		currentXP = current,
		maxXP = max,
		restedXP = rested,
		percent = max > 0 and (current / max) * 100 or 0,
		sessionXP = sessionXP,
		levelXP = levelXP,
		killXP = g.killXP or 0,
		questXP = g.questXP or 0,
		sessionTime = sessionTime,
		levelTime = levelTime,
		playedTime = played,
		sessionRate = sessionRate,
		levelRate = levelRate,
		eta = eta,
	}
end

function Stats:Reset()
	local g = self.db.global
	local now = time()

	g.sessionStart = now
	g.sessionXP = 0
	g.levelStart = now
	g.lastLevel = UnitLevel("player") or 1
	g.lastXP = UnitXP("player") or 0
	g.killXP = 0
	g.questXP = 0

	self:Fire()
end

function Stats:RegisterListener(fn)
	table.insert(self.listeners, fn)
end

function Stats:Fire()
	local data = self:GetData()

	for _, fn in ipairs(self.listeners) do
		fn(data)
	end
end