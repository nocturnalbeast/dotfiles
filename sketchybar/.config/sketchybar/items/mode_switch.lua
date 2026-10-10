-- items/mode_switch.lua - leftmost item; barswitch + SYSTEM menu.
--   LEFT-click  → system menu popup (static, synchronous build - opens
--                 instantly): About This Mac, System Settings, Force
--                 Quit front app, then a divider and the stack controls
--                 (Restart AeroSpace / Reload Sketchybar / Restart
--                 Hammerspoon). Rows fire `sys_menu_pick TARGET=<id>`
--                 round-trips; commands execute Lua-side from ACTIONS.
--                 (The old front-app `menus` popup was retired - the
--                 bar-hover app-menu strip covers front-app menus.)
--   RIGHT-click → instant mode.toggle() (main/monitor barswitch).
-- Icon-only: the Apple glyph (md-apple) in BOTH modes - no label.
-- Icon codepoints VERIFIED against the font cmap (caffeine rule).
local colors = require("colors")
local settings = require("settings")
local pill = require("helpers.pill")
local popup = require("helpers.popup")
local mode = require("helpers.mode")

local SB_BIN = "/opt/homebrew/bin/sketchybar"

local ICON_APPLE = "󰀵" -- md-apple (U+F0035)

local mode_switch = sbar.add("item", "mode_switch", {
	position = "left",
	icon = {
		string = ICON_APPLE,
		color = colors.muted,
		padding_left = 8,
		-- +1: NF glyph ink sits ~1.7pt low in its em-box
		-- (pixel-measured); nudge up to meet the text baseline
		y_offset = 1,
		padding_right = 6,
	},
	background = pill.background(),
	-- LEFTMOST pill of the bar: outer padding 0 so the pill sits flush on
	-- the bar's own edge (bar padding is 0 - see init.lua). padding_right
	-- keeps the normal island gap to the aerospace trio.
	padding_left = 0,
	padding_right = settings.paddings,
	-- menu anchor; "left" keeps the popup on-screen from the bar's edge
	popup = { align = "left" },
})

-- ============================================================================
-- System menu popup (helpers/popup lifecycle; rows tracked + removed by
-- exact name). STATIC rows - no async fetch, the menu opens instantly.
-- ============================================================================

local ctl = popup.new(mode_switch)

-- Glyphs verified via fontTools cmap 2026-09-04 (do NOT memorize NF cps)
local ACTIONS = {
	{ id = "about",     icon = "\u{F0379}", label = "About This Mac",
	  cmd = 'open "x-apple.systempreferences:com.apple.SystemProfiler.AboutExtension"' },
	{ id = "settings",  icon = "\u{F0493}", label = "System Settings",
	  cmd = 'open -a "System Settings"' },
	{ id = "fquit",     icon = "\u{F015C}", label = "Force Quit Front App",
	  -- Accessibility-gated (same TCC grant as plugins/menus). unix id +
	  -- shell kill: System Events has no kill verb (-1708, measured);
	  -- kill -9 = force quit (no save prompts - that is the point)
	  cmd = "/usr/bin/osascript -e 'tell application \"System Events\" to set p to unix id of (first application process whose frontmost is true)' -e 'do shell script \"kill -9 \" & p'" },
	{ id = "divider" },
	{ id = "aero",      icon = "\u{F0709}", label = "Restart AeroSpace",
	  -- GUI app (cask, /Applications/AeroSpace.app), NOT a brew service
	  -- (brew services restart aerospace → "No available formula") -
	  -- graceful SIGTERM then relaunch
	  cmd = "killall AeroSpace >/dev/null 2>&1; sleep 0.5; open -a AeroSpace" },
	{ id = "sbar",      icon = "\u{F0453}", label = "Reload Sketchybar",
	  cmd = SB_BIN .. " --reload" },
	{ id = "hs",        icon = "\u{F08EA}", label = "Restart Hammerspoon",
	  cmd = "killall Hammerspoon >/dev/null 2>&1; open -a Hammerspoon" },
}

local function open_system_menu()
	ctl:open(function(b)
		b.header("System")
		for _, a in ipairs(ACTIONS) do
			if a.id == "divider" then
				b.divider()
			else
				-- daemon-side, hit-tested on the row: round-trip so the
				-- popup closes, command executes Lua-side (the
				-- ws_menu_pick idiom)
				b.action(a.icon, a.label,
					SB_BIN .. " --trigger sys_menu_pick TARGET=" .. a.id)
			end
		end
		b.show()
	end)
end

sbar.add("event", "sys_menu_pick")
mode_switch:subscribe("sys_menu_pick", function(env)
	ctl:close()
	local action = env.TARGET
	for _, a in ipairs(ACTIONS) do
		if a.id == action and a.cmd then
			sbar.exec(a.cmd)
		end
	end
end)

-- ============================================================================
-- Click routing: right = instant toggle, anything else = app-menu popup
-- ============================================================================

-- mouse.clicked is a BROADCAST (every subscriber fires, env.NAME names
-- the clicked item) - guard or ANY click in the bar opens the menu.
mode_switch:subscribe("mouse.clicked", popup.guard(mode_switch.name, function(env)
	if env.BUTTON == "right" then
		mode.toggle()
	elseif ctl:is_open() then
		ctl:close()
	else
		open_system_menu()
	end
end))

-- Bar-exit safety net: close the app-menu popup when the pointer leaves
-- the bar (the old merged handler's hover-collapse half retired with the
-- hover reveal).
mode_switch:subscribe("mouse.exited.global", popup.guard(mode_switch.name, function()
	ctl:close()
end))
