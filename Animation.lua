local ADDON_NAME, ns = ...

-- Minimal tween engine: one active animation per frame, driven by a single
-- shared OnUpdate so we don't spin up extra frames/timers per tween.
local active = {}
local driver = CreateFrame("Frame")

local function OnUpdate(self, elapsed)
	local any = false

	-- Snapshot the keys before iterating: a completion callback can start a
	-- brand new animation (adding a new key to `active`), and mutating a
	-- table with new keys while pairs()/next() is traversing it is unsafe
	-- and intermittently throws "invalid key to 'next'".
	local frames = {}
	for frame in pairs(active) do
		frames[#frames + 1] = frame
	end

	for i = 1, #frames do
		local frame = frames[i]
		local anim = active[frame]
		if anim then
			anim.t = anim.t + elapsed
			local frac = anim.t / anim.duration
			if frac >= 1 then frac = 1 end

			-- easeOutQuad
			local eased = 1 - (1 - frac) * (1 - frac)
			anim.onUpdate(frame, anim.from + (anim.to - anim.from) * eased)

			if frac >= 1 then
				if active[frame] == anim then
					active[frame] = nil
				end
				if anim.onComplete then anim.onComplete(frame) end
			end
		end
	end

	for _ in pairs(active) do
		any = true
		break
	end

	if not any then
		self:SetScript("OnUpdate", nil)
		self.running = false
	end
end

-- Animates a single numeric value from `from` to `to` over `duration` seconds,
-- calling onUpdate(frame, value) every tick. Only one tween per frame object
-- is tracked at a time; starting a new one replaces the old.
function ns.Animate(frame, from, to, duration, onUpdate, onComplete)
	if not frame then return end

	if not duration or duration <= 0 then
		onUpdate(frame, to)
		if onComplete then onComplete(frame) end
		active[frame] = nil
		return
	end

	active[frame] = { t = 0, from = from, to = to, duration = duration, onUpdate = onUpdate, onComplete = onComplete }

	if not driver.running then
		driver.running = true
		driver:SetScript("OnUpdate", OnUpdate)
	end
end

function ns.StopAnimation(frame)
	active[frame] = nil
end
