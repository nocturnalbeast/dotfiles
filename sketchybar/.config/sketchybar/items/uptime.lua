-- items/uptime.lua - time since boot from sysctl kern.boottime.
-- 60s poll. Label "3d 4h" (hours-only under a day).
-- Click → popup: exact boot timestamp + humanized uptime.
-- Hover → exact boot timestamp append (helpers/hover; boot epoch is
-- cached on first read - read_boot never re-execs within a boot).
-- Monitor-exclusive: born hidden + updates off in main mode (reload-free
-- mode swap via mode_changed - AGENT.md facts 16-18).
local colors = require("colors")
local settings = require("settings")
local pill = require("helpers.pill")
local popup = require("helpers.popup")
local hover = require("helpers.hover")
local mode = require("helpers.mode")

local visible = mode.get() == "monitor"

local uptime = sbar.add("item", "uptime", {
	position = "right",
	drawing = visible and "on" or "off",
	updates = visible,
	icon = {
		string = "󰅑",
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
	popup = { align = "center" },
})

local last_label = nil
local boot_epoch = nil -- kern.boottime cache (constant within a boot)

-- "{ sec = 1787038133, usec = ... } Tue Aug 18 12:58:53 2026"
local function read_boot(cb)
	if boot_epoch then
		cb(boot_epoch)
		return
	end
	sbar.exec("/usr/sbin/sysctl -n kern.boottime", function(out)
		local sec = tonumber((out or ""):match("sec%s*=%s*(%d+)"))
		if sec then
			boot_epoch = sec
			cb(sec)
		end
	end)
end

local function refresh()
	read_boot(function(boot_sec)
		if not boot_sec then
			return
		end
		local diff = math.max(0, os.time() - boot_sec)
		local days = math.floor(diff / 86400)
		local hours = math.floor((diff % 86400) / 3600)
		local minutes = math.floor((diff % 3600) / 60)
		local label
		if days >= 1 then
			label = days .. "d " .. hours .. "h"
		elseif hours >= 1 then
			label = hours .. "h"
		else
			label = minutes .. "m"
		end
		if label == last_label then
			return
		end
		last_label = label
		uptime:set({ label = { string = label } })
	end)
end

-- ============================================================================
-- Click popup - boot timestamp + humanized uptime (fresh read on open,
-- cpu-popup idiom; rows tracked + removed on close)
-- ============================================================================

local ctl = popup.new(uptime)

local function build_popup(b)
	read_boot(function(boot_sec)
		if not boot_sec then
			return
		end
		local diff = math.max(0, os.time() - boot_sec)
		local days = math.floor(diff / 86400)
		local hours = math.floor((diff % 86400) / 3600)
		local minutes = math.floor((diff % 3600) / 60)
		-- humanized: leading zero units dropped ("42m" / "4h 12m" / "3d 4h 12m")
		local parts = {}
		if days > 0 then
			parts[#parts + 1] = days .. "d"
		end
		if hours > 0 or days > 0 then
			parts[#parts + 1] = hours .. "h"
		end
		parts[#parts + 1] = minutes .. "m"
		b.header("Uptime")
		b.kv("Booted:", os.date("%a, %d %b %Y %I:%M %p", boot_sec))
		b.kv("Uptime:", table.concat(parts, " "))
		b.show()
	end)
end

uptime:subscribe("mouse.clicked", ctl:clicked(build_popup))

-- Hover append: "3d 4h  ·  Tue 18 Aug 2026, 12:58 PM" (cached boot epoch)
local hov = hover.new(uptime, function()
	return boot_epoch and os.date("%a %d %b %Y, %I:%M %p", boot_epoch) or ""
end, { base = function()
	return last_label or "--"
end, no_global_exit = true })

-- merged exited.global: popup close + hover collapse (hover.lua note)
uptime:subscribe("mouse.exited.global", popup.guard(uptime.name, function()
	ctl:close()
	hov.collapse()
end))

-- ============================================================================
-- Mode gating (Lua poll chain gated by `polling` - fact 16)
-- ============================================================================

local polling = false

local function tick()
	if not polling then
		return
	end
	refresh()
	sbar.delay(60, tick)
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
	uptime:set({ drawing = show and "on" or "off", updates = show })
end

mode.on_change(apply_mode)

-- Initial render + poll (only when born visible)
if visible then
	polling = true
	tick()
end
