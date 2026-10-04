-- Namespace bootstrap. Loaded first so every other file can attach to a shared table.
local ADDON_NAME, ns = ...

if ADDON_NAME then
	if not ns then
		ns = {}
		_G[ADDON_NAME] = ns
	end
end

ns.ADDON_NAME = ADDON_NAME
ns.VERSION = "1.0.0"

_G.XPIsland = ns