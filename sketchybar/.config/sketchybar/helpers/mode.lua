-- helpers/mode.lua - bar mode machinery (main / monitor), RELOAD-FREE.
-- Mode persists in settings.MODE_FILE; toggle writes the file and triggers
-- the custom "mode_changed" event - items flip their own drawing/updates
-- (see init.lua union order + AGENT.md facts 16-18). No `sketchybar
-- --reload` on mode toggle: one config process for the whole session.
-- (Reload machinery was removed from here; `--reload` remains for THEME
-- switches only, driven by theme.sh.)
--
-- DELIVERY GOTCHA (empirically verified - AGENT.md fact 17): `--trigger` /
-- sbar.trigger does NOT reach items with updates=false. A mode-exclusive
-- item born hidden (updates=false) would therefore NEVER hear mode_changed
-- and could never re-show - the naive `item:subscribe("mode_changed", …)`
-- design deadlocks after one toggle. Solution: this module owns ONE relay
-- item (mode.relay: drawing=off, updates=true FOREVER - the aerospace.
-- observer idiom) that receives the event and dispatches to Lua listeners
-- via mode.on_change(), independent of every target item's updates flag.
local settings = require("settings")

local mode = {}

function mode.get()
	local f = io.open(settings.MODE_FILE, "r")
	if not f then
		return "main"
	end
	local content = f:read("*a") or ""
	f:close()
	content = content:gsub("^%s+", ""):gsub("%s+$", "")
	if content == "monitor" then
		return "monitor"
	end
	return "main"
end

-- ============================================================================
-- mode_changed relay (see header). Item creation happens on first use -
-- always inside init.lua's begin_config/end_config window, since every
-- caller (mode_switch + mode-exclusive modules) is required there.
-- ============================================================================

local listeners = {}
local relay = nil

local function ensure_relay()
	if relay then
		return
	end
	relay = sbar.add("item", "mode.relay", { drawing = "off", updates = true })
	relay:subscribe("mode_changed", function()
		for _, fn in ipairs(listeners) do
			fn()
		end
	end)
end

--- Register fn to run on every mode_changed trigger (toggle OR the CLI
--- quick-sheet path). fn re-reads the mode file itself (no payload).
function mode.on_change(fn)
	ensure_relay()
	listeners[#listeners + 1] = fn
end

function mode.toggle()
	local next_mode = mode.get() == "monitor" and "main" or "monitor"
	mode.set(next_mode)
end

--- Switch to `target` ("main"|"monitor"). No-op when already current:
--- no file write, no mode_changed trigger, no churn (menu selection of
--- the current mode just closes the menu). Any other target is ignored.
--- Menu selection flows through the SAME mode_changed relay as toggle.
function mode.set(target)
	if target ~= "main" and target ~= "monitor" then
		return
	end
	if target == mode.get() then
		return
	end

	-- Write the file synchronously FIRST, then trigger the in-process
	-- swap: the relay fans out to every module's apply_mode, which reads
	-- the file (the trigger carries no payload) and flips
	-- drawing/updates/poll gates.
	local dir = settings.MODE_FILE:match("^(.*)/[^/]+$")
	os.execute('/bin/mkdir -p "' .. dir .. '"')
	local f = io.open(settings.MODE_FILE, "w")
	if f then
		f:write(target)
		f:close()
	end

	sbar.trigger("mode_changed")
end

return mode
