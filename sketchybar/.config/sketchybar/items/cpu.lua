-- items/cpu.lua — total CPU % via ps top-sum (plan §4: NOT `top -l1` —
-- slow spawn). 10s poll. fg normally, yellow >60%, red >85%.
-- Click → popup with top 5 processes.
-- Monitor-exclusive: born hidden + updates off in main mode (reload-free
-- mode swap via mode_changed — AGENT.md facts 16–18).
local colors = require("colors")
local settings = require("settings")
local pill = require("helpers.pill")
local popup = require("helpers.popup")
local mode = require("helpers.mode")

local PS = "/bin/ps"

local visible = mode.get() == "monitor"

local cpu = sbar.add("item", "cpu", {
	position = "right",
	drawing = visible and "on" or "off",
	updates = visible,
	icon = {
		string = "󰻠",
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
	padding_left = settings.paddings,
	padding_right = settings.paddings,
	popup = { align = "center" },
})

local last_value = nil

local function color_for(v)
	if v > 85 then
		return colors.red
	elseif v > 60 then
		return colors.yellow
	end
	return colors.fg
end

-- Core count fetched once at load — ps %cpu sums across ALL cores (M4 Max
-- = 16c → raw sums up to 1600%); normalize to a 0-100% figure like
-- Activity Monitor.
local ncpu = 8
do
	-- timeout 5 (2026-09-27): load-time io.popen, same pclose hang
	-- class as the detect-loop incident; sysctl is instant when healthy
	local h = io.popen("/opt/homebrew/bin/timeout 5 /usr/sbin/sysctl -n hw.ncpu 2>/dev/null")
	if h then
		local n = tonumber((h:read("*a") or ""):match("%d+"))
		h:close()
		if n and n > 0 then
			ncpu = n
		end
	end
end

local function refresh()
	sbar.exec(PS .. [[ -Arc -o %cpu | /usr/bin/tail -n +2 | /usr/bin/awk '{s+=$1} END {printf "%d", s+0.5}']], function(out)
		local raw = tonumber((out or ""):match("%d+"))
		if not raw then
			return
		end
		local v = math.min(100, math.floor(raw / ncpu + 0.5))
		if v == last_value then
			return
		end
		last_value = v
		local c = color_for(v)
		cpu:set({
			icon = { color = c },
			label = { string = v .. "%", color = c },
		})
	end)
end

-- ============================================================================
-- Top-processes popup (helpers/popup lifecycle — rows built async on
-- open, tracked + removed on close; a close while ps is in flight
-- generation-guards the adds away)
-- ============================================================================

local ctl = popup.new(cpu)

local function build_popup(b)
	-- reduce full binary paths to their basename (cut -c chopped paths
	-- mid-word); handles spaced names like "Microsoft Teams ModuleHost"
	sbar.exec(PS .. [[ -Arc -o %cpu,comm | /usr/bin/tail -n +2 | /usr/bin/head -5 | /usr/bin/awk '{ pct = $1; name = $0; sub(/^[ \t]*[0-9.]+[ \t]+/, "", name); sub(/.*\//, "", name); printf "%s %s\n", pct, name }']], function(out)
		b.header("Top processes")
		for line in string.gmatch(out or "", "[^\r\n]+") do
			local pct, name = line:match("^%s*(%d+%.?%d*)%s+(.+)$")
			if name then
				b.kv(name, pct .. "%", { key_w = 230, val_w = 60 })
			end
		end
		b.show()
	end)
end

cpu:subscribe("mouse.clicked", ctl:clicked(build_popup))
cpu:subscribe("mouse.exited.global", ctl:exited())

-- ============================================================================
-- Mode gating (Lua poll chain gated by `polling` — fact 16)
-- ============================================================================

local polling = false

local function tick()
	if not polling then
		return
	end
	refresh()
	sbar.delay(10, tick)
end

local function apply_mode()
	local show = mode.get() == "monitor"
	if show and not polling then
		polling = true
		tick()
	elseif not show then
		polling = false
		ctl:close()
	end
	cpu:set({ drawing = show and "on" or "off", updates = show })
end

mode.on_change(apply_mode)

-- Initial render + poll (only when born visible)
if visible then
	polling = true
	tick()
end
