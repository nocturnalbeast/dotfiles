-- items/memory.lua - used memory % via vm_stat (machine fact 12:
-- `memory_pressure -Q` free% includes purgeable, so used% understates
-- Activity Monitor). used = (Pages wired down + Pages active + Pages
-- occupied by compressor) × page-size ÷ hw.memsize, batched in one exec
-- and grep-narrowed to stay well under the sbar.exec truncation limit
-- (fact 3). 10s poll. fg normally, yellow >60%, red >85%.
-- Hover → absolute "16.2 / 64 GB" append (helpers/hover; GB math from
-- the same vm_stat parse - cache-only, no new execs).
-- Monitor-exclusive: born hidden + updates off in main mode (reload-free
-- mode swap via mode_changed - AGENT.md facts 16-18).
local colors = require("colors")
local settings = require("settings")
local pill = require("helpers.pill")
local hover = require("helpers.hover")
local mode = require("helpers.mode")

local visible = mode.get() == "monitor"

local memory = sbar.add("item", "memory", {
	position = "right",
	drawing = visible and "on" or "off",
	updates = visible,
	icon = {
		string = "󰍛",
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
})

local last_value = nil
local abs = { used_gb = nil, total_gb = nil } -- hover payload cache (GB)

local function color_for(v)
	if v > 85 then
		return colors.red
	elseif v > 60 then
		return colors.yellow
	end
	return colors.fg
end

-- NOTE: vm_stat is /usr/bin/vm_stat on this macOS (not /usr/sbin).
local VM_CMD = "/bin/sh -c '/usr/sbin/sysctl -n hw.memsize; echo ---; "
	.. "/usr/bin/vm_stat | /usr/bin/grep -E "
	.. "\"page size of|Pages wired down:|Pages active:|Pages occupied by compressor:\"'"

local function refresh()
	sbar.exec(VM_CMD, function(out)
		local o = out or ""
		local total = tonumber(o:match("^(%d+)"))
		local page = tonumber(o:match("page size of (%d+) bytes"))
		local wired = tonumber(o:match("Pages wired down:%s*(%d+)%."))
		local active = tonumber(o:match("Pages active:%s*(%d+)%."))
		local comp = tonumber(o:match("Pages occupied by compressor:%s*(%d+)%."))
		if not (total and page and wired and active and comp) or total <= 0 then
			return
		end
		-- absolute GB cache for the hover append (same parse, no execs)
		abs.used_gb = (wired + active + comp) * page / 1073741824
		abs.total_gb = total / 1073741824
		local v = math.floor((wired + active + comp) * page / total * 100 + 0.5)
		if v == last_value then
			return
		end
		last_value = v
		local c = color_for(v)
		memory:set({
			icon = { color = c },
			label = { string = v .. "%", color = c },
		})
	end)
end

-- Hover append: "34%  ·  21.7 / 64 GB" (cache-only; before the first poll
-- completes the cache is empty → no-op reveal)
hover.new(memory, function()
	if not abs.used_gb then
		return ""
	end
	return string.format("%.1f / %d GB", abs.used_gb, math.floor(abs.total_gb + 0.5))
end, { base = function()
	return last_value and (last_value .. "%") or "--%"
end })

-- ============================================================================
-- Mode gating (Lua poll chain gated by `polling` - fact 16; no popup)
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
	end
	memory:set({ drawing = show and "on" or "off", updates = show })
end

mode.on_change(apply_mode)

-- Initial render + poll (only when born visible)
if visible then
	polling = true
	tick()
end
