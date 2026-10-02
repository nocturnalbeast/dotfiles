-- items/clock.lua — %I:%M %p label (12-hour, hh:mm AM/PM), 30s refresh via
-- update_freq. Click → popup with full date + next 2 today's events
-- (icalBuddy; guard: binary missing or error → date lines only).
-- NOTE deviation from plan: the brew formula is `ical-buddy` but the BINARY
-- is /opt/homebrew/bin/icalBuddy (capital B) — verified on this machine.
-- Main-exclusive: born hidden + updates off in monitor mode (reload-free
-- mode swap via mode_changed — AGENT.md facts 16–18). No Lua poll gate
-- needed: the 30s refresh is update_freq (server-side), which updates=
-- false stops (fact 16).
local colors = require("colors")
local settings = require("settings")
local pill = require("helpers.pill")
local popup = require("helpers.popup")
local hover = require("helpers.hover")
local mode = require("helpers.mode")

local ICALBUDDY = "/opt/homebrew/bin/icalBuddy"
local EVENT_LIMIT = 2

local visible = mode.get() == "main"

local clock_item = sbar.add("item", "clock", {
	position = "right",
	drawing = visible and "on" or "off",
	updates = visible,
	update_freq = 30,
	icon = {
		string = "󰥔",
		color = colors.fg,
		padding_left = 8,
		-- +1: NF glyph ink sits ~1.7pt low in its em-box
		-- (pixel-measured); nudge up to meet the text baseline
		y_offset = 1,
		padding_right = 6,
	},
	label = {
		string = "",
		font = settings.font.numbers,
		color = colors.fg,
		padding_right = 8,
	},
	background = pill.background(),
	padding_left = settings.paddings,
	-- 6 (not 3): wifi cluster is the right neighbor — bracket member
	-- paddings are inert, so THIS side owns the 8pt visual gap
	padding_right = 6,
	popup = { align = "center" },
})

-- Hover append: "01:21 AM  ·  Friday, 21 August 2026" (helpers/hover;
-- base called fresh at reveal/collapse so a tick mid-hover restores
-- correctly — payload is a pure os.date, no execs). Declared BEFORE
-- render_time: the tick calls hov.refresh.
local hov = hover.new(clock_item, function()
	return os.date("%A, %d %B %Y")
end, { base = function()
	return os.date("%I:%M %p")
end, no_global_exit = true })

local function render_time()
	clock_item:set({ label = { string = os.date("%I:%M %p") } })
	hov.refresh(os.date("%A, %d %B %Y"))
end

-- update_freq fires "routine" events
clock_item:subscribe({ "forced", "routine", "system_woke" }, render_time)

-- ============================================================================
-- Calendar popup (helpers/popup lifecycle — rows built async on open,
-- tracked + removed on close; stale icalBuddy callbacks no-op)
-- ============================================================================

local ctl = popup.new(clock_item)

local function build_popup(b)
	b.header(os.date("%A, %d %B %Y"))
	-- 2-event-bounded, byte-capped (long event titles/locations can't
	-- blow the exec transport limit); stderr silenced so the cap can't
	-- leak broken-pipe noise
	sbar.exec(
		string.format("%s -n -ea -li %d eventsToday 2>/dev/null | /usr/bin/head -c 400", ICALBUDDY, EVENT_LIMIT),
		function(out)
			local events = (out or ""):gsub("^%s+", ""):gsub("%s+$", "")
			if events == "" or events:match("^null") then
				b.empty("No events today")
			else
				local i = 0
				for line in string.gmatch(events, "[^\r\n]+") do
					i = i + 1
					b.action("󰃶", line, "")
				end
			end
			-- icalBuddy output arrives async — reveal the popup only once
			-- the children exist (b.show() is generation-guarded: no-op
			-- if the popup was closed while we were fetching)
			b.show()
		end
	)
end

clock_item:subscribe("mouse.clicked", ctl:clicked(build_popup))
-- merged exited.global: popup close + hover collapse (hover.lua note)
clock_item:subscribe("mouse.exited.global", popup.guard(clock_item.name, function()
	ctl:close()
	hov.collapse()
end))

-- ============================================================================
-- Mode gating (drawing/updates only + close popup; update_freq needs no
-- Lua gate — updates=false stops routine ticks server-side, fact 16)
-- ============================================================================

local function apply_mode()
	local show = mode.get() == "main"
	if show then
		render_time() -- no stale time after a hidden period
	else
		ctl:close()
	end
	clock_item:set({ drawing = show and "on" or "off", updates = show })
end

mode.on_change(apply_mode)

render_time()
