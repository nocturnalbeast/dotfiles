-- items/power.lua — session power menu (rightmost position).
-- Click → popup: Lock / Sleep / Restart / Shutdown.
-- Lock uses `pmset displaysleepnow` — reliable and permission-free (the
-- ctrl+cmd+Q keystroke needs Accessibility grants sketchybar may not have).
-- Restart/Shutdown via System Events AppleScript.
--
-- Popup rows fire the custom `power_action` event (bluetooth bt_refresh
-- idiom) — the Lua handler performs the action AND tears the popup down,
-- so the Lua open-flag never desyncs. (The old click_scripts closed the
-- popup CLI-side; the first anchor click after an action was swallowed.)
local colors = require("colors")
local settings = require("settings")
local pill = require("helpers.pill")
local popup = require("helpers.popup")

local ACTIONS = {
	{
		id = "lock",
		icon = "󰒷",
		label = "Lock",
		script = "/usr/bin/pmset displaysleepnow",
		color = colors.fg,
	},
	{
		id = "sleep",
		icon = "󰤄",
		label = "Sleep",
		script = "/usr/bin/pmset sleepnow",
		color = colors.fg,
	},
	{
		id = "restart",
		icon = "󰜉",
		label = "Restart…",
		script = [[/usr/bin/osascript -e 'tell app "System Events" to restart']],
		color = colors.yellow,
	},
	{
		id = "shutdown",
		icon = "󰐥",
		label = "Shutdown…",
		script = [[/usr/bin/osascript -e 'tell app "System Events" to shut down']],
		color = colors.red,
	},
}

local power = sbar.add("item", "power", {
	position = "right",
	icon = {
		string = "󰐥",
		color = colors.accent,
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
	-- RIGHTMOST pill in BOTH modes: outer padding 0 so the pill sits
	-- flush on the bar's own edge (bar padding is 0 — see init.lua).
	-- padding_left keeps the normal island gap to the wifi cluster.
	padding_left = settings.paddings,
	padding_right = 0,
	popup = { align = "center" },
})

-- ============================================================================
-- Popup (helpers/popup lifecycle — rows tracked + removed on close,
-- unlike the old version which leaked power.pop.* items forever)
-- ============================================================================

local ctl = popup.new(power)

local function build_popup(b)
	b.header("Power")
	for _, act in ipairs(ACTIONS) do
		-- report to Lua, not the CLI: the handler below runs the
		-- action AND closes the popup so state stays in sync
		b.action(act.icon, act.label,
			"/opt/homebrew/bin/sketchybar --trigger power_action ACTION=" .. act.id,
			{ color = act.color })
	end
	b.show()
end

power:subscribe("mouse.clicked", ctl:clicked(build_popup))
power:subscribe("mouse.exited.global", ctl:exited())

-- Popup row actions arrive here; close FIRST (sync flag + remove
-- power.pop.* rows), THEN perform the action.
sbar.add("event", "power_action")
power:subscribe("power_action", function(env)
	ctl:close()
	for _, act in ipairs(ACTIONS) do
		if act.id == env.ACTION then
			sbar.exec(act.script, function() end)
			return
		end
	end
end)
