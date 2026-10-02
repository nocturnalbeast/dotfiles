-- items/battery.lua — REAL battery (MacBook Pro M4 Max, plan P0-1:
-- "always rendered when present"). pmset -g batt parse; event-driven via
-- the Hammerspoon bridge `hs_battery` event (instant, richer data — see
-- AGENT.md "Hammerspoon event bridge") + builtin power_source_change +
-- system_woke, with a 60s fallback poll (item stays correct if
-- Hammerspoon isn't running — belt and suspenders). Hides itself if pmset
-- reports no battery (desktop).
--
-- Colors: green >40, yellow 20–40, red <20; charging → accent + bolt glyph.
-- Click → detail popup (cycles / health + discharge watts — ONLY data
-- absent from the pill and hover; hs_battery cache, no execs) via the
-- shared popup DSL (b.header/b.kv/b.empty). Hover → time-estimate append
-- (helpers/hover, cache-only).
local colors = require("colors")
local settings = require("settings")
local pill = require("helpers.pill")
local popup = require("helpers.popup")
local hover = require("helpers.hover")

local ICON_BATTERY = "󰁺"
local ICON_CHARGING = "󰂅"

local battery = sbar.add("item", "battery", {
	position = "right",
	icon = {
		string = ICON_BATTERY,
		color = colors.fg,
		padding_left = 8,
		-- +1: NF glyph ink sits ~1.7pt low in its em-box
		-- (pixel-measured); nudge up to meet the text baseline
		y_offset = 1,
		padding_right = 6,
	},
	label = {
		string = "--%",
		font = settings.font.numbers,
		color = colors.fg,
		padding_right = 8,
	},
	background = pill.background(),
	padding_left = 6, -- wifi-cluster side: restores the standard 8pt visual gap
	padding_right = settings.paddings,
	popup = { align = "center" },
})

-- pmset states are semicolon-delimited: "; charging;", "; charged;",
-- "; discharging;", "AC attached; not charging". A bare "charging"
-- substring also hits "discharging"/"not charging", and "AC Power" is
-- present whenever plugged in (full battery included) — so match the
-- delimited tokens only (verified phrasing: "96%; charging;").
-- Time estimate ("0:20 remaining") is ABSENT when pmset reports
-- "(no estimate)" — the popup degrades gracefully (muted "No estimate").
local function parse_batt(out)
	local o = out or ""
	local pct = tonumber(o:match("(%d+)%%"))
	if not pct then
		return nil
	end
	return {
		pct = pct,
		charging = o:match("; charging;") ~= nil,
		state = (o:match("; charging;") and "Charging")
			or (o:match("; charged;") and "Charged")
			or (o:match("; discharging;") and "On Battery")
			or (o:match("AC attached; not charging") and "AC (not charging)")
			or "Unknown",
		time_left = o:match("(%d+:%d+) remaining"),
	}
end

local function batt_colors(st)
	if st.charging then
		return colors.accent, ICON_CHARGING
	elseif st.pct <= 20 then
		return colors.red, ICON_BATTERY
	elseif st.pct <= 40 then
		return colors.yellow, ICON_BATTERY
	end
	return colors.green, ICON_BATTERY
end

-- Change-detection cache: only touch the bar when pct/charging actually
-- moved (no label churn — same philosophy as media.lua's string cache).
local shown = { pct = -1, charging = nil }

-- Hover/estimate cache — fed by BOTH update paths (pmset H:MM string and
-- the hs_battery TIME_REMAINING minutes); pure reads, no execs.
local est = { min = nil, charging = nil, watts = nil }

local function render(pct, charging)
	if shown.pct == pct and shown.charging == charging then
		return
	end
	shown.pct = pct
	shown.charging = charging
	local color, icon = batt_colors({ pct = pct, charging = charging })
	battery:set({
		drawing = "on",
		icon = { string = icon, color = color },
		label = { string = pct .. "%", color = color },
	})
end

local function refresh()
	sbar.exec("/usr/bin/pmset -g batt", function(out)
		local st = parse_batt(out)
		if not st then
			-- no battery present → remove the pill entirely (P0-1 "when present")
			battery:set({ drawing = "off" })
			return
		end
		if st.time_left then
			local h, m = st.time_left:match("^(%d+):(%d+)")
			if h then
				est.min = tonumber(h) * 60 + tonumber(m)
			end
		end
		est.charging = st.charging
		render(st.pct, st.charging)
	end)
end

-- ============================================================================
-- Hammerspoon bridge — hs_battery (instant, event-driven). Also caches the
-- fields pmset can't provide (watts / cycles / health / time-to-min) for
-- the popup enrichment below; nil until the first event, so a dead
-- Hammerspoon degrades the popup to the pmset rows only.
-- ============================================================================

local ev = nil

battery:subscribe("hs_battery", function(env)
	local pct = tonumber(env.PERCENT)
	if not pct then
		return
	end
	local charging = env.CHARGING == "1"
	local tmin = tonumber(env.TIME_REMAINING)
	if tmin and tmin >= 0 then
		est.min = tmin
	end
	est.charging = charging
	est.watts = tonumber(env.WATTS) or est.watts
	ev = {
		watts = tonumber(env.WATTS),
		cycles = tonumber(env.CYCLES),
		health = tonumber(env.HEALTH),
		time_min = tonumber(env.TIME_REMAINING),
	}
	render(pct, charging)
end)

battery:subscribe({ "power_source_change", "system_woke", "forced" }, refresh)

-- ============================================================================
-- Click popup — ONLY data not already shown by the resting pill (charge %,
-- icon, color state) or the hover append (time estimate, AC watts):
-- discharge wattage + cycle count + health, read from the hs_battery
-- cache (no execs — opens instantly). Reworked 2026-09-04: the old
-- charge/state/time rows duplicated the pill and hover.
-- ============================================================================

local ctl = popup.new(battery)

local function build_popup(b)
	b.header("Battery")
	if not ev then
		b.empty("No detail data (Hammerspoon down)")
		b.show()
		return
	end
	-- discharge draw: the hover only shows watts when on AC — this row is
	-- the battery-side complement
	if ev.watts and ev.watts < 0 then
		b.kv("Draw:", string.format("%.1f W", math.abs(ev.watts)))
	end
	if ev.cycles and ev.cycles > 0 then
		b.kv("Cycles:", tostring(ev.cycles))
	end
	if ev.health and ev.health > 0 then
		b.kv("Health:", ev.health .. "%",
			{ value_color = ev.health >= 80 and colors.green or colors.yellow })
	end
	b.show()
end

battery:subscribe("mouse.clicked", ctl:clicked(build_popup))

-- ============================================================================
-- Hover append — time estimate from the est cache (helpers/hover; no
-- execs): "1h 23m to full" / "4h 08m left" / "on AC · 37.4 W" /
-- "no estimate"
-- ============================================================================

local function fmt_est(min)
	return string.format("%dh %02dm", math.floor(min / 60), min % 60)
end

local hov = hover.new(battery, function()
	if est.charging then
		if est.min and est.min > 0 then
			return fmt_est(est.min) .. " to full"
		end
		if est.watts then
			return string.format("on AC · %.1f W", math.abs(est.watts))
		end
		return "on AC"
	end
	if est.min and est.min > 0 then
		return fmt_est(est.min) .. " left"
	end
	return "no estimate"
end, { base = function()
	return (shown.pct >= 0 and shown.pct or "--") .. "%"
end, no_global_exit = true })

-- merged exited.global: popup close + hover collapse (hover.lua note)
battery:subscribe("mouse.exited.global", popup.guard(battery.name, function()
	ctl:close()
	hov.collapse()
end))

-- Initial render + 60s fallback poll (bridge events are the primary driver)
refresh()
local function tick()
	refresh()
	sbar.delay(60, tick)
end
tick()
