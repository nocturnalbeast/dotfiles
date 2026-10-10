-- items/vol.lua - output volume. Event-driven via the BUILTIN volume_change
-- event (P1-4: no polling - a 5s poll would spawn osascript 17k×/day) plus
-- the Hammerspoon bridge `hs_audio` event (instant + carries MUTED).
-- Scroll = ±5, click = toggle mute, initial read at load.
-- Hover → output-device name append (helpers/hover, hs_audio cache only -
-- no execs; empty cache = no-op reveal).
-- Main-exclusive: born hidden + updates off in monitor mode (reload-free
-- mode swap via mode_changed - AGENT.md facts 16-18). updates=false stops
-- volume_change dispatch while hidden (fact 16); read_volume() on re-show
-- resyncs.
local colors = require("colors")
local settings = require("settings")
local pill = require("helpers.pill")
local popup = require("helpers.popup")
local hover = require("helpers.hover")
local mode = require("helpers.mode")

local OSASCRIPT = "/usr/bin/osascript"

local ICON_ON = "󰕾"
local ICON_OFF = "󰖁"

local visible = mode.get() == "main"

local vol = sbar.add("item", "vol", {
	position = "right",
	drawing = visible and "on" or "off",
	updates = visible,
	icon = {
		string = ICON_ON,
		color = colors.fg,
		padding_left = 8,
		-- +1: NF glyph ink sits ~1.7pt low in its em-box
		-- (pixel-measured); nudge up to meet the text baseline
		y_offset = 1,
		padding_right = 6,
	},
	label = {
		string = "--",
		font = settings.font.numbers,
		color = colors.fg,
		padding_right = 8,
	},
	background = pill.background(),
	padding_left = 6, -- media-cluster side: restores the standard 8pt visual gap
	padding_right = settings.paddings,
})

local shown_volume = nil -- last rendered level (hover base)

local function render(volume, muted)
	shown_volume = volume
	local on = not muted and volume > 0
	vol:set({
		icon = {
			string = on and ICON_ON or ICON_OFF,
			color = on and colors.fg or colors.muted,
		},
		label = {
			string = volume .. "%",
			color = on and colors.fg or colors.muted,
		},
	})
end

local function read_volume()
	sbar.exec(OSASCRIPT .. [[ -e 'output volume of (get volume settings)']], function(out)
		local volume = tonumber((out or ""):match("%d+"))
		if not volume then
			return
		end
		-- read mute state in the same pass (two quick calls, only on
		-- events/interaction - never on a timer)
		sbar.exec(OSASCRIPT .. [[ -e 'output muted of (get volume settings)']], function(m)
			local muted = (m or ""):match("true") ~= nil
			render(volume, muted)
		end)
	end)
end

vol:subscribe("volume_change", function(env)
	local volume = tonumber(env.INFO)
	if volume then
		render(volume, false)
		-- volume_change carries the level, not the mute flag - cheap
		-- follow-up read keeps the mute glyph truthful.
		sbar.exec(OSASCRIPT .. [[ -e 'output muted of (get volume settings)']], function(m)
			local muted = (m or ""):match("true") ~= nil
			if muted then
				render(volume, true)
			end
		end)
	else
		read_volume()
	end
end)

-- Hammerspoon bridge - hs_audio (instant volume/mute pushes; see AGENT.md
-- "Hammerspoon event bridge"). The builtin volume_change above stays the
-- daemon-side truth for the level; this just makes updates instant and
-- carries the mute flag the builtin lacks. VOLUME="-1" = device doesn't
-- expose volume (unsupported) → keep the last known level, if any.
-- (Subscription on this mode-gated item is dispatched only while
-- updates=true - server-side block while hidden, resync on re-show.)
local last_volume
local device = nil -- hs_audio DEVICE cache (hover payload; no execs)

vol:subscribe("hs_audio", function(env)
	local muted = env.MUTED == "1"
	local v = tonumber(env.VOLUME)
	if v and v >= 0 then
		last_volume = v
	end
	if env.DEVICE and env.DEVICE ~= "" then
		device = env.DEVICE
	end
	if last_volume then
		render(last_volume, muted)
	end
end)

-- Hover append: "56%  ·  MacBook Pro Speakers" (cache-only; empty cache →
-- no-op reveal - hover on vol never spawns an exec)
hover.new(vol, function()
	return device or ""
end, { base = function()
	return (shown_volume or 0) .. "%"
end })

-- ±5 per scroll tick (direction-based; env.INFO.delta magnitude varies by
-- device, so we use it only for sign). NAME-guarded: scrolling ANY item
-- broadcasts to every mouse.scrolled subscriber.
vol:subscribe("mouse.scrolled", popup.guard(vol.name, function(env)
	local delta = tonumber(env.INFO and env.INFO.delta) or 0
	if delta == 0 then
		return
	end
	local step = delta > 0 and 5 or -5
	sbar.exec(
		OSASCRIPT
			.. [[ -e 'set volume output volume (output volume of (get volume settings) + ]]
			.. step
			.. [[)']],
		function() end
	)
end))

-- Mute toggle may not fire volume_change with a useful payload - manual
-- re-read after toggling (idempotent if the event also fires).
vol:subscribe("mouse.clicked", popup.guard(vol.name, function()
	sbar.exec(
		OSASCRIPT .. [[ -e 'set volume output muted not (output muted of (get volume settings))']],
		function() end
	)
	read_volume()
end))

-- ============================================================================
-- Mode gating (drawing/updates only; resync volume/mute on re-show)
-- ============================================================================

local function apply_mode()
	local show = mode.get() == "main"
	vol:set({ drawing = show and "on" or "off", updates = show })
	if show then
		read_volume()
	end
end

mode.on_change(apply_mode)

-- Initial read at load (only when born visible)
if visible then
	read_volume()
end
