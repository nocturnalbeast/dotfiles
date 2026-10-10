-- items/disk.lua - root filesystem usage via `df -g /`. 60s poll.
-- Click → popup listing mounted volumes with % used (ONE batched
-- /bin/df -h exec, awk-compacted to stay well under the sbar.exec
-- truncation limit - fact 3; rows parsed in Lua).
-- Hover → "/ used/total GB" append from the same root df parse (the
-- awk now also emits size+used; cache-only, no new execs).
-- Monitor-exclusive: born hidden + updates off in main mode (reload-free
-- mode swap via mode_changed - AGENT.md facts 16-18).
local colors = require("colors")
local settings = require("settings")
local pill = require("helpers.pill")
local popup = require("helpers.popup")
local hover = require("helpers.hover")
local mode = require("helpers.mode")

local visible = mode.get() == "monitor"

local disk = sbar.add("item", "disk", {
	position = "right",
	drawing = visible and "on" or "off",
	updates = visible,
	icon = {
		string = "󰋊",
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
local abs = { used = nil, size = nil } -- hover payload cache (df -g blocks)

local function refresh()
	-- cap% + 1G-blocks total/used (the two extra fields feed the hover
	-- append; output stays ~20B - far under budget)
	sbar.exec("/bin/df -g / | /usr/bin/awk 'NR==2 {print $5, $2, $3; exit}'", function(out)
		local cap, size, used = (out or ""):match("^(%d+)%%%s+(%d+)%s+(%d+)")
		local v = tonumber(cap)
		if not v then
			return
		end
		local s, u = tonumber(size), tonumber(used)
		if s and u then
			abs.size = s
			abs.used = u
		end
		if v == last_value then
			return
		end
		last_value = v
		disk:set({ label = { string = v .. "%" } })
	end)
end

-- ============================================================================
-- Click popup - mounted volumes with % used (cpu-popup row idiom)
-- ============================================================================

local ctl = popup.new(disk)

-- ONE batched exec; awk emits "cap% size used mount" per row and drops
-- pseudo filesystems (devfs, map *) and throwaway system volumes
-- (VM/Preboot/Update/xarts/iSCPreboot/Hardware) so the transported
-- output stays tiny (~100B live, capped at 8 rows ≈ 280B worst case -
-- fact 3 truncation). Every stage's stderr is silenced so the head cap
-- can never leak broken-pipe noise. NOTE: this macOS df has 10 columns;
-- mount is $NF (volume names containing spaces truncate at the first
-- space - cosmetic only).
local DF_CMD = "/bin/df -h 2>/dev/null | /usr/bin/tail -n +2 2>/dev/null | /usr/bin/awk '"
	.. [[ $1 == "devfs" { next } ]]
	.. [[ $1 ~ /^map/ { next } ]]
	.. [[ $NF ~ /^\/System\/Volumes\/(VM|Preboot|Update|xarts|iSCPreboot|Hardware)$/ { next } ]]
	.. [[ { printf "%s %s %s %s\n", $5, $2, $3, $NF } ']]
	.. [[ 2>/dev/null | /usr/bin/head -n 8]]

local function build_popup(b)
	sbar.exec(DF_CMD, function(out)
		local vols = {}
		for line in string.gmatch(out or "", "[^\r\n]+") do
			local cap, size, used, mount = line:match("^(%d+)%% (%S+) (%S+) (.+)$")
			if cap and mount then
				vols[#vols + 1] = { cap = cap, size = size, used = used, mount = mount }
			end
		end
		if #vols == 0 then
			return -- nothing parsed - never open an empty popup
		end
		b.header("Volumes")
		for i, vol in ipairs(vols) do
			b.kv(vol.mount, vol.cap .. "% · " .. vol.used .. "/" .. vol.size,
				{ key_w = 200, val_w = 150 })
		end
		b.show()
	end)
end

disk:subscribe("mouse.clicked", ctl:clicked(build_popup))

-- Hover append: "26%  ·  / 231/994 GB" (cache-only; empty before the
-- first poll completes → no-op reveal)
local hov = hover.new(disk, function()
	if not (abs.used and abs.size) then
		return ""
	end
	return string.format("/ %d/%d GB", abs.used, abs.size)
end, { base = function()
	return last_value and (last_value .. "%") or "--%"
end, no_global_exit = true })

-- merged exited.global: popup close + hover collapse (hover.lua note)
disk:subscribe("mouse.exited.global", popup.guard(disk.name, function()
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
	disk:set({ drawing = show and "on" or "off", updates = show })
end

mode.on_change(apply_mode)

-- Initial render + poll (only when born visible)
if visible then
	polling = true
	tick()
end
