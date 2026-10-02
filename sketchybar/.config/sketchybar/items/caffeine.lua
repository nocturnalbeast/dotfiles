-- items/caffeine.lua — caffeinate keep-awake toggle.
-- Click: running → pkill; not running → spawn DETACHED (P2: a mode toggle or
-- theme reload kills plugin children — nohup+background via zsh -c survives).
-- This is a phase-5 gate requirement, baked in now.
-- Main-exclusive: born hidden + updates off in monitor mode (reload-free
-- mode swap via mode_changed — AGENT.md facts 16–18).
local colors = require("colors")
local settings = require("settings")
local pill = require("helpers.pill")
local popup = require("helpers.popup")
local mode = require("helpers.mode")

local CAFFEINATE_SPAWN = "/bin/zsh -c 'nohup /usr/bin/caffeinate -d >/dev/null 2>&1 &'"

-- Glyph swaps with state (user request 2026-09-04: color alone read as
-- "always off"): md-coffee U+F0176 (steaming cup) = ACTIVE,
-- md-coffee_off U+F0FAA = off. Codepoints VERIFIED against the font's
-- cmap (fontTools) — do NOT trust memorized NF codepoints: U+F0576 is
-- a three-bars glyph, not coffee (bit us 2026-09-04).
local ICON_ON = "󰅶"
local ICON_OFF = "󰾪"

local visible = mode.get() == "main"

local caffeine = sbar.add("item", "caffeine", {
	position = "right",
	drawing = visible and "on" or "off",
	updates = visible,
	icon = {
		string = ICON_OFF,
		color = colors.muted, -- dim when off
		-- 8/8: icon-only item — padding_right keeps MDI glyph ink (wider
		-- than its advance width) off the pill border (fact 19)
		padding_left = 8,
		-- +1: NF glyph ink sits ~1.7pt low in its em-box
		-- (pixel-measured); nudge up to meet the text baseline
		y_offset = 1,
		padding_right = 6,
	},
	label = { drawing = false },
	background = pill.background(),
	padding_left = settings.paddings,
	padding_right = settings.paddings, -- back to 3: no longer adjacent to the
	-- wifi cluster (moved between battery and power; 3+3+2 slop = 8pt visual)
})

local function render(active)
	caffeine:set({
		icon = {
			string = active and ICON_ON or ICON_OFF,
			color = active and colors.accent or colors.muted,
		},
		-- active pill gets a faint accent tint, like the focused workspace
		background = active and pill.background({ accent = colors.accent })
			or pill.background(),
	})
end

local function check_state(cb)
	sbar.exec("/usr/bin/pgrep -x caffeinate", function(out)
		local active = (out or ""):match("%d") ~= nil
		cb(active)
	end)
end

-- broadcast guard: mouse.clicked fires on EVERY item's click — without
-- this, any click anywhere toggled caffeinate
caffeine:subscribe("mouse.clicked", popup.guard(caffeine.name, function()
	check_state(function(active)
		if active then
			sbar.exec("/usr/bin/pkill -x caffeinate", function()
				render(false)
			end)
		else
			-- DETACHED spawn: survives bar reloads / mode toggles (P2)
			sbar.exec(CAFFEINATE_SPAWN, function()
				sbar.delay(0.2, function()
					check_state(render)
				end)
			end)
		end
	end)
end))

-- ============================================================================
-- Mode gating (no poll loop, no popup — drawing/updates only; re-check
-- caffeinate state on re-show, it may have changed while hidden)
-- ============================================================================

local function apply_mode()
	local show = mode.get() == "main"
	caffeine:set({ drawing = show and "on" or "off", updates = show })
	if show then
		check_state(render)
	end
end

mode.on_change(apply_mode)

-- Initial state at load (survives --reload: caffeinate is detached)
if visible then
	check_state(render)
end
