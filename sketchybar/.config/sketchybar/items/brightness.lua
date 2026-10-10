-- items/brightness.lua - display brightness via /opt/homebrew/bin/brightness.
-- P1-2: ~/.local/bin/brightness is a broken Linux leftover - absolute path.
--
-- DEVIATION from plan §4: brew's brightness 1.2 (and the `-g` flag the plan
-- assumed) is broken on this machine's XDR panel (error -536870201 for BOTH
-- read and set). Fixed by `brew install --HEAD brightness` (nriley HEAD
-- supports modern CoreDisplay): reads via `brightness -l` ("display 0:
-- brightness 0.422500"), sets via `brightness 0.8`. No `-g` on this build.
--
-- No event source - 30s poll (sbar.delay timer, aerospace safety-refresh
-- idiom), updating the label only when the value changes (no label churn).
-- Main-exclusive: born hidden + updates off in monitor mode (reload-free
-- mode swap via mode_changed - AGENT.md facts 16-18).
local colors = require("colors")
local settings = require("settings")
local pill = require("helpers.pill")
local popup = require("helpers.popup")
local mode = require("helpers.mode")

local BRIGHTNESS = "/opt/homebrew/bin/brightness"

-- 30s (was 10s): the value only moves on user interaction/auto-adapt;
-- the scroll path reads back immediately
local POLL_INTERVAL = 30

local visible = mode.get() == "main"

local brightness_item = sbar.add("item", "brightness", {
	position = "right",
	drawing = visible and "on" or "off",
	updates = visible,
	icon = {
		string = "󰃟",
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
	padding_left = settings.paddings,
	padding_right = settings.paddings,
})

local last_percent = nil

local function read_brightness()
	-- 2>/dev/null: external DDC displays (MSI) can't report brightness -
	-- stderr noise only, value comes from the built-in display's line
	sbar.exec(BRIGHTNESS .. " -l 2>/dev/null", function(out)
		-- "display 0: brightness 0.422500"
		local level = tonumber((out or ""):match("brightness%s+([%d%.]+)"))
		if not level then
			return
		end
		local percent = math.floor(level * 100 + 0.5)
		if percent ~= last_percent then
			last_percent = percent
			brightness_item:set({ label = { string = percent .. "%" } })
		end
	end)
end

-- ±0.1 per scroll tick (direction-based). NAME-guarded: scrolling any
-- OTHER item broadcasts here too and would retune the display.
brightness_item:subscribe("mouse.scrolled", popup.guard(brightness_item.name, function(env)
	local delta = tonumber(env.INFO and env.INFO.delta) or 0
	if delta == 0 then
		return
	end
	local step = delta > 0 and 0.1 or -0.1
	sbar.exec(string.format("%s %f 2>/dev/null", BRIGHTNESS, math.min(1.0, math.max(0.0, (last_percent or 50) / 100 + step))), function()
		-- read back immediately so scroll feels responsive
		last_percent = nil
		read_brightness()
	end)
end))

-- ============================================================================
-- Mode gating (Lua poll chain gated by `polling` - fact 16; no popup)
-- ============================================================================

local polling = false

local function poll()
	if not polling then
		return
	end
	read_brightness()
	sbar.delay(POLL_INTERVAL, poll)
end

local function apply_mode()
	local show = mode.get() == "main"
	if show and not polling then
		polling = true
		poll()
	elseif not show then
		polling = false
	end
	brightness_item:set({ drawing = show and "on" or "off", updates = show })
end

mode.on_change(apply_mode)

-- Initial read + poll (only when born visible)
if visible then
	polling = true
	poll()
end
