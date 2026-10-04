local ADDON_NAME, ns = ...
local L = ns.L

-- Shorthand number formatting, e.g. 1234567 -> "1.23M"
function ns.FormatNumber(value, digits)
	if not value then return L["na"] end

	local abs = math.abs(value)
	if abs >= 1e9 then
		return string.format("%.2fB", value / 1e9)
	elseif abs >= 1e6 then
		return string.format("%.2fM", value / 1e6)
	elseif abs >= 1e4 then
		return string.format("%.1fk", value / 1e3)
	end

	return tostring(math.floor(value + 0.5))
end

-- Thousands separators for exact values, e.g. 1234567 -> "1,234,567"
function ns.FormatThousands(value)
	value = math.floor(value or 0)

	local sign = value < 0 and "-" or ""
	local str = tostring(math.abs(value))
	local out = str

	while true do
		local replaced
		out, replaced = out:gsub("^(-?%d+)(%d%d%d)", "%1,%2")
		if replaced == 0 then break end
	end

	return sign .. out:gsub("^-", "")
end

-- Durations. Compact form used on the panel: "2d 3h", "3h 12m", "12m 04s", "45s"
function ns.FormatDuration(seconds, style)
	seconds = math.max(0, math.floor(seconds or 0))

	local days = math.floor(seconds / 86400)
	local hours = math.floor((seconds % 86400) / 3600)
	local minutes = math.floor((seconds % 3600) / 60)
	local secs = seconds % 60

	if style == "short" then
		if days > 0 then return string.format("%dd %dh", days, hours) end
		if hours > 0 then return string.format("%dh %dm", hours, minutes) end
		if minutes > 0 then return string.format("%dm %ds", minutes, secs) end
		return string.format("%ds", secs)
	end

	if days > 0 then return string.format("%dd %dh %dm", days, hours, minutes) end
	if hours > 0 then return string.format("%dh %dm", hours, minutes) end
	if minutes > 0 then return string.format("%dm %ds", minutes, secs) end
	return string.format("%ds", secs)
end

-- Rates use the same suffix ladder as FormatNumber but keep one decimal place
function ns.FormatRate(perHour)
	if not perHour or perHour <= 0 then return "0" end
	return ns.FormatNumber(perHour, 1)
end

function ns.FormatPercent(current, max)
	if not max or max <= 0 then return "0%" end
	return string.format("%.1f%%", current / max * 100)
end

-- Parses Blizzard's TIME_PLAYED_MSG string, e.g. "3 Days 4 Hours 5 Minutes"
function ns.ParsePlayedTime(str)
    if not str then return 0 end

    -- If the API already provided a numeric seconds value, just return it.
    if type(str) == "number" then return str end

    -- Otherwise coerce to string and normalize. Older and newer WoW builds
    -- may send localized/time-formatted strings; attempt a forgiving parse.
    local s = tostring(str):lower()
    local seconds = 0
    local units = {
        day = 86400,
        hour = 3600,
        minute = 60,
        second = 1,
    }

    for word, value in pairs(units) do
        -- Match both singular and plural (Day/Days) and allow optional commas.
        local pattern = "(%d+)%%s+" .. word .. "%w*"
        local n = s:match(pattern)
        if n then
            seconds = seconds + tonumber(n) * value
        end
    end

    return seconds
end
