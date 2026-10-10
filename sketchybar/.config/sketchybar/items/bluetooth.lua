-- items/bluetooth.lua - power state + connected devices via blueutil.
-- 30s poll (sbar.delay timer idiom; was 10s - the sweep costs 3 spawns
-- per tick for user-action-paced data). Click → dropdown menu listing
-- connected devices + power toggle. All blueutil calls guarded (TCC/Bluetooth permission
-- failures → dim icon, never crash).
-- Main-exclusive: born hidden + updates off in monitor mode (reload-free
-- mode swap via mode_changed - AGENT.md facts 16-18).
local colors = require("colors")
local settings = require("settings")
local pill = require("helpers.pill")
local popup = require("helpers.popup")
local mode = require("helpers.mode")

local BLUEUTIL = "/opt/homebrew/bin/blueutil"

local ICON_ON = "󰂱"
local ICON_OFF = "󰂯"

local visible = mode.get() == "main"

local bluetooth = sbar.add("item", "bluetooth", {
	position = "right",
	drawing = visible and "on" or "off",
	updates = visible,
	icon = {
		string = ICON_OFF,
		color = colors.muted,
		padding_left = 8,
		-- +1: NF glyph ink sits ~1.7pt low in its em-box
		-- (pixel-measured); nudge up to meet the text baseline
		y_offset = 1,
		padding_right = 6,
	},
	label = {
		string = "",
		font = settings.font.text,
		color = colors.fg,
		padding_right = 8,
	},
	background = pill.background(),
	padding_left = settings.paddings,
	padding_right = settings.paddings,
	popup = { align = "center" },
})

local bt_ok = true -- flips false on first blueutil failure
local power_state = false
local devices = {} -- { { address = ..., name = ... } }

local function truncate(s, n)
	if #s <= n then
		return s
	end
	return s:sub(1, n - 1) .. "…"
end

local function render()
	if not bt_ok then
		bluetooth:set({
			icon = { string = ICON_OFF, color = colors.inactive },
			label = { string = "" },
		})
		return
	end
	local label
	if not power_state then
		label = "Off"
	elseif #devices == 1 then
		label = truncate(devices[1].name, 12)
	elseif #devices > 1 then
		label = #devices .. " devices"
	else
		label = "On"
	end
	-- Four live states, optically distinct:
	--   power ON + connected  → fg icon + device name / "n devices"
	--   power ON + 0 devices  → muted icon (dim: "on but idle") + "On"
	--   power OFF             → inactive icon (dead grey) + muted "Off"
	--   blueutil failure      → inactive icon, empty label (error state)
	local icon_color = not power_state and colors.inactive
		or (#devices > 0 and colors.fg or colors.muted)
	local label_color = not power_state and colors.muted or colors.fg
	bluetooth:set({
		icon = {
			string = power_state and ICON_ON or ICON_OFF,
			color = icon_color,
		},
		label = { string = label, color = label_color },
	})
end

-- ============================================================================
-- State sweep - ONE batched exec, COMPACT protocol.
--
-- The old passthrough shipped blueutil's verbose lines whole (137B per
-- paired device - 695B for five, over the sbar.exec transport limit):
-- output truncated AND the closed pipe EPIPE'd the shell writers
-- ("/bin/sh: echo: write error: Broken pipe"). Now awk reduces each
-- --paired line to `state|address|name` (~40B) and power becomes a
-- single `P0`/`P1` line; head caps the device count. Worst case
-- (6 devices) ≈ 250B - nothing truncates, nothing EPIPEs. Every
-- stage's stderr is silenced so the head() cap can never leak noise.
--
-- Protocol:  `P0`|`P1` power line, then per paired device
--            `C|addr|name` (connected) or `-|addr|name` (not).
--            Connection state comes from the --paired listing itself
--            (blueutil reports it per device) - the separate
--            --connected spawn is gone (3 spawns → 2, still one exec).
-- ============================================================================
-- blueutil 2.14 quirk (2026-09-04): under a launchd context --paired
-- reports EVERY device as "not connected" (its connection-state query is
-- broken there), while --connected works and already carries address +
-- name for exactly the devices we care about. Build the device list
-- from --connected alone; every emitted row is connected by definition.
-- blueutil 2.14 quirk (2026-09-04): under a launchd context --paired
-- reports EVERY device as "not connected" (its connection-state query is
-- broken there), while --connected works and already carries address +
-- name for exactly the devices we care about. Build the device list
-- from --connected alone; every emitted row is connected by definition.
-- getenv guard: a nil HOME under odd launchd contexts made this concat
-- nil → io.open(nil) crashed every sweep (log: bluetooth.lua:139)
local BT_CONN_FILE = (os.getenv("HOME") or "/tmp") .. "/.cache/sketchybar/bt_connected.txt"
-- blueutil 2.14 under the launchd context (brew services): the live
-- connection-state is written LATE - piping --connected into awk races
-- the reader (the sweep saw P1-only while the data landed in the file
-- milliseconds later, verified twice). Fix: redirect to a FILE - the
-- shell's `;` sequencing guarantees it is complete before the exec
-- callback fires - and parse it Lua-side. --connected carries address +
-- name for exactly the devices we care about; every row is connected.
local SWEEP_CMD = BLUEUTIL .. [[ --connected > ]] .. BT_CONN_FILE
	.. [[ 2>/dev/null; printf 'P%s\n' "$(]] .. BLUEUTIL .. [[ --power 2>/dev/null)"]]

local function sweep()
	sbar.exec(SWEEP_CMD, function(out)
		local power = nil
		for line in string.gmatch(out or "", "[^\r\n]+") do
			local p = line:match("^P([01])$")
			if p then
				power = p
			end
		end
		-- device list from the file (complete: the printf marker runs
		-- strictly after blueutil exits - see SWEEP_CMD note)
		local f = io.open(BT_CONN_FILE, "r")
		local data = f and f:read("*a") or ""
		if f then
			f:close()
		end
		local paired = {}
		for line in string.gmatch(data, "[^\r\n]+") do
			-- .-: state fields ("connected (…)", "not favourite", …) sit
			-- between the address and the name - skip them lazily
			local addr, name = line:match('^address: ([^,]*).-name: "(.*)"')
			if addr then
				name = name:gsub("%s+$", "")
				paired[#paired + 1] = {
					address = addr,
					name = name ~= "" and name or addr,
					connected = true, -- --connected emits connected devices only
				}
			end
		end

		if power ~= "0" and power ~= "1" then
			bt_ok = false
			render()
			return
		end
		bt_ok = true
		power_state = (power == "1")

		devices = {}
		for _, d in ipairs(paired) do
			if d.connected then
				devices[#devices + 1] = d
			end
		end
		render()
	end)
end

-- ============================================================================
-- Popup menu (helpers/popup lifecycle - rows built on open, tracked by
-- exact name in Lua and removed on close; the old sbar.remove("/bt%.…/")
-- regexes were silent no-ops, see AGENT.md fact 13). prefix "bt." covers
-- the legacy row names for the stale-row sweeps. Subscriptions are NAME-
-- guarded: mouse.clicked is a broadcast (env.NAME = clicked item).
-- ============================================================================

local ctl = popup.new(bluetooth, { prefix = "bt." })

local function build_popup(b)
	b.header(#devices > 0 and ("Connected (" .. #devices .. ")") or "Bluetooth")
	for i, dev in ipairs(devices) do
		b.action("󰂱", dev.name, "")
	end
	b.action(
		power_state and ICON_ON or ICON_OFF,
		power_state and "Power: On" or "Power: Off",
		BLUEUTIL .. " --power " .. (power_state and "0" or "1")
			.. " && /opt/homebrew/bin/sketchybar --trigger bt_refresh",
		{ color = power_state and colors.accent or colors.muted }
	)
	b.show()
end

bluetooth:subscribe("mouse.clicked", popup.guard(bluetooth.name, function(env)
	if env.BUTTON == "right" then
		-- RIGHT-click: flip BT power in place. Optimistic render (the
		-- 30s sweep re-confirms); left-click keeps the device popup.
		power_state = not power_state
		render()
		sbar.delay(0.5, sweep)
		sbar.exec(BLUEUTIL .. " --power " .. (power_state and "1" or "0"))
		return
	end
	if ctl:is_open() then
		ctl:close()
	else
		sweep()
		ctl:open(build_popup)
	end
end))

bluetooth:subscribe("mouse.exited.global", ctl:exited())

-- power-toggle re-render trigger (fired from popup click_script)
sbar.add("event", "bt_refresh")
bluetooth:subscribe("bt_refresh", function()
	sbar.delay(0.3, function()
		sweep()
		if ctl:is_open() then
			ctl:close()
			sbar.delay(0.1, function()
				sweep()
				ctl:open(build_popup)
			end)
		end
	end)
end)

-- ============================================================================
-- Mode gating (Lua poll chain gated by `polling` - fact 16; sweep on
-- re-show so the pill reflects any state change from the hidden period)
-- ============================================================================

local polling = false

local function poll()
	if not polling then
		return
	end
	sweep()
	-- 30s (was 10s): BT state changes at user-action pace, and the
	-- right-click + bt_refresh paths re-sweep immediately anyway
	sbar.delay(30, poll)
end

local function apply_mode()
	local show = mode.get() == "main"
	if show and not polling then
		polling = true
		poll()
	elseif not show then
		polling = false
		ctl:close()
	end
	bluetooth:set({ drawing = show and "on" or "off", updates = show })
end

mode.on_change(apply_mode)

-- Initial sweep + 30s poll (only when born visible)
if visible then
	polling = true
	poll()
end
