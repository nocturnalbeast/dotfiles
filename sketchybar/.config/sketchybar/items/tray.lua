-- items/tray.lua — Wi-Fi pill: ONE visual pill, stacked bandwidth chips.
--
-- Layout (right side, visual L→R inside ONE pill drawn by wifi.bracket):
--   [ ↑ up  ]  stacked 10pt chips (y_offset ±4, no own background)
--   [ ↓ down]
--   [ 󰤨 <SSID/IP> ]  state item: signal icon + head label
--
-- ONE PILL, not two: the old look of "a pill on top of a pill" was the
-- state item AND the bracket both drawing pill backgrounds. Now ONLY the
-- bracket draws — the chips and the state item have background off.
--
--   head:  SSID chain: hs_wifi cache → ipconfig awk (30s tick, only while
--          HS cache empty) → IP (fact-8 degradation).
--   icon:  signal bars from RSSI cache (≥−55 󰤨 · ≥−65 󰤥 · ≥−75 󰤢 · else
--          󰤟); no RSSI → generic 󰤨; disconnected → 󰤭 muted; VPN (utun)
--          overrides → 󰌾 green.
--   chips: up yellow / down cyan (muted when idle), fed by the
--          network_load bridge's 2s events, pretty-formatted.
--   hover: append "IP <addr> · <txrate> Mbps" on the state
--          item (helpers/hover). IP is CACHED from the 30s ipconfig tick;
--          hover never execs. The 2s chip ticks write CHIP labels only —
--          they can't touch the hovered head label.
--   click: detail popup (Hostname/Router/RSSI rows — copy-on-click;
--          click-to-copy) anchored on the state item.
--
-- Bandwidth: the compiled `network_load` C bridge (plugins/) pushes
-- `network_update` every 2s. Launched DETACHED (nohup + background +
-- redirects): the foreground-exec form made the wrapper sh block in
-- wait(), so every reload's `killall network_load` printed "Terminated:
-- 15" to inherited stderr. Detached, the kill is silent; the bridge
-- survives config swaps by design.
--
-- Hammerspoon bridge: `hs_wifi` events trigger instant refreshes and
-- cache RSSI/TXRATE/SSID (see AGENT.md "Hammerspoon event bridge").
-- SSID="" (Location-denied) just exercises the documented fallback chain
-- — the bar never pokes the Location dialog (fact 8).
--
-- WHY NOT AN ALIAS: native menu bar is hidden (`_HIHideMenuBar=1`) so
-- SystemUIServer exposes nothing to mirror.
local colors = require("colors")
local settings = require("settings")
local pill = require("helpers.pill")
local popup = require("helpers.popup")
local hover = require("helpers.hover")

local CONFIG_DIR = os.getenv("HOME") .. "/.config/sketchybar"

local BARS_4 = "󰤨" -- ≥−55 dBm (also the generic "connected, no RSSI" icon)
local BARS_3 = "󰤥" -- ≥−65
local BARS_2 = "󰤢" -- ≥−75
local BARS_1 = "󰤟" -- below −75
local ICON_OFF = "󰤭"
local ICON_VPN = "󰌾"

local CHIP_UP_ICON = "󰜷" -- md-arrow_up_bold (U+F0737) — real arrows (the
local CHIP_DOWN_ICON = "󰜮" -- md-arrow_down_bold (U+F072E) — old codepoints were md-twitch/md-order_numeric_ascending!)

-- ============================================================================
-- Bandwidth bridge spawn (unchanged — see header)
-- ============================================================================
sbar.exec("killall network_load >/dev/null 2>&1; nohup " .. CONFIG_DIR
	.. "/plugins/network_load en0 network_update 2.0 >/dev/null 2>&1 &")

-- ============================================================================
-- Items — right side renders REVERSE of add order. Add chips FIRST, state
-- item LAST → visual L→R inside the bracket pill: [↑][↓][󰤨 head]
-- ============================================================================

local wifi_up = sbar.add("item", "wifi.up", {
	position = "right",
	width = 0,
	icon = {
		string = CHIP_UP_ICON,
		-- 2: matches the head icon's left inset — consistent pill rhythm
		-- (4 read as over-padded on the left)
		padding_left = 2,
		-- minimal gap to the counter (icon renders immediately left of
		-- the dynamic-width label — [icon][text] packs and overflows
		-- leftward from the shared right anchor)
		padding_right = 1,
		font = { family = settings.font_family.icons, size = 8.0 },
		color = colors.muted,
	},
	label = {
		font = { family = settings.font_family.numbers, size = 8.0 },
		color = colors.fg,
		string = "",
		-- DYNAMIC width (no align/width): [icon][text] packs tightly — the
		-- icon sits right next to the counter. The item's right anchor
		-- (slot x + this equal padding) keeps both counters' right edges
		-- on the same coordinate. 7: breathing room to the pill's right
		-- edge (4 read as tight).
		padding_right = 7,
	},
	-- ±6 (with 8pt text): balanced vertical separation between the two
	-- counters (user-tuned: 7 read as too separated)
	y_offset = 6,
	background = { drawing = false }, -- ONE pill: the bracket draws it
	-- RIGHT edge of the cluster (first-added renders rightmost); equal
	-- on both chips so the stack stays put — 6 = pixel-calibrated
	padding_left = 0,
	padding_right = 6,
})

local wifi_down = sbar.add("item", "wifi.down", {
	position = "right",
	width = 0,
	icon = {
		string = CHIP_DOWN_ICON,
		padding_left = 2, -- matches wifi.up — consistent pill rhythm
		padding_right = 1, -- minimal gap to the counter (see wifi.up note)
		font = { family = settings.font_family.icons, size = 8.0 },
		color = colors.muted,
	},
	label = {
		font = { family = settings.font_family.numbers, size = 8.0 },
		color = colors.fg,
		string = "",
		padding_right = 7, -- equal to wifi.up — same right edge
	},
		y_offset = -6,
		background = { drawing = false },
		padding_left = 0,
		padding_right = 6, -- MUST equal wifi.up — the shared right anchor
		-- (a 3pt drift here skews the whole stack; regression 2026-08-27)
	})

local wifi = sbar.add("item", "wifi", {
	position = "right",
	icon = {
		string = ICON_OFF,
		color = colors.muted,
		-- 8/8: bar-wide icon padding convention (battery/clock/caffeine/
		-- memory/cpu all 8/8). +1: NF glyph ink sits ~1.7pt low in its
		-- em-box (pixel-measured); nudge up to meet the text baseline.
		padding_left = 8,
		padding_right = 6,
		y_offset = 1,
	},
	label = {
		string = "",
		font = settings.font.text,
		color = colors.fg,
		-- RESERVED BAND for the stacked chips (DYNAMIC — see retune_band):
		-- the chips are width=0 items whose text overflows LEFTWARD from
		-- their slots (right of this one). The add-time 64 is a safe floor;
		-- every 2s tick re-measures the chips' rendered rects and retunes
		-- this padding to hug the actual counter widths (+ gutter).
		padding_right = 64,
	},
	background = { drawing = false }, -- the bracket is the ONE pill surface
	-- LEFT edge of the cluster. Member item paddings are INERT for a
	-- bracket's bg edge (measured twice) — the clock|wifi visual gap is
	-- owned by clock.padding_right = 6 (the standalone neighbor knob,
	-- same pattern as battery.pl on the cluster's right side)
	padding_left = settings.paddings,
	padding_right = settings.paddings,
	-- popup anchor (rows wifi.*.t; click handler queries this item)
	popup = { align = "center", height = 30 },
})

-- The ONE pill: bracket wraps chips + state item and draws the background
local wifi_bracket = sbar.add("bracket", "wifi.bracket", { wifi_up.name, wifi_down.name, wifi.name }, {
	background = pill.background(),
	-- bracket paddings EXPLICITLY 0: sbar.default would otherwise apply
	-- 3/3 and EXTEND the bg past the members, eating the island gap
	padding_left = 0,
	padding_right = 0,
	-- NO bracket paddings: bracket padding EXTENDS the bg (cancels the
	-- members' island-gap item paddings — measured). Outer gaps come
	-- from the members' item paddings (head pl / chips pr = paddings)
})

-- ============================================================================
-- Caches (hover payloads are cache-only — the hover convention)
-- ============================================================================

-- state cache: filled by refresh_state (30s tick + wifi_change/woke/hs_wifi)
local state = { ip = "", ipconfig_ssid = "", connected = false, vpn = false }
-- bandwidth cache: filled by network_update (2s bridge events)
local bw = { up = "", down = "" }
-- Hammerspoon bridge cache (instant; strings — "" when HS down/denied)
local wifi_ev = { rssi = "", txrate = "", ssid = "" }

-- ============================================================================
-- Composition helpers
-- ============================================================================

-- Raw "002KBps" → prettified "2 KBps" (strip pad zeros, space before unit).
-- Second return: idle flag (raw zeros → traffic is 0).
local function pretty(v)
	if not v or v == "" then
		return "", true
	end
	local num, unit = v:match("^(%d+)([KMG]?Bps)$")
	if not num then
		return v, v == "000Bps"
	end
	num = num:gsub("^0+", "")
	if num == "" then
		num = "0"
	end
	return num .. " " .. unit, num == "0"
end

-- SSID chain: hs_wifi cache → ipconfig awk cache → IP (fact-8 degradation)
local function label_head()
	if wifi_ev.ssid ~= "" then
		return wifi_ev.ssid
	end
	if state.ipconfig_ssid ~= "" then
		return state.ipconfig_ssid
	end
	return state.ip
end

-- Head-only label: speeds live in the stacked chips, not here
local function base_label()
	if not state.connected then
		return "" -- disconnected: no head (chips go idle-muted via bridge zeros)
	end
	return label_head()
end

-- Signal-strength bars from the RSSI cache (buckets mirror rssi_quality)
local function signal_icon(rssi)
	if not rssi then
		return BARS_4
	end
	if rssi >= -55 then
		return BARS_4
	elseif rssi >= -65 then
		return BARS_3
	elseif rssi >= -75 then
		return BARS_2
	end
	return BARS_1
end

-- "IP <addr> · <txrate> Mbps" — only pieces we actually have (dBm lives
-- in the popup's RSSI row, not the hover).
-- Trailing " ·": the label's LAST glyph sits immediately before the
-- counters in BOTH states (resting base carries its own trailing dot;
-- hovered composition = dotted base + " " + this payload), giving the
-- visual break regardless of hover.
local function hover_payload()
	-- dBm deliberately NOT in the hover (user request 2026-09-04): the
	-- pill icon already buckets the signal quality, and the popup's RSSI
	-- row carries the precise number + quality word
	local parts = {}
	if state.ip ~= "" then
		parts[#parts + 1] = "IP " .. state.ip
	end
	local txrate = tonumber(wifi_ev.txrate)
	if txrate then
		parts[#parts + 1] = string.format("%.1f Mbps", txrate)
	end
	local s = table.concat(parts, " · ")
	if s == "" then
		return "" -- no data — reveal no-ops, resting label stays dotted
	end
	return s .. " ·"
end

-- ============================================================================
-- Render paths (ALL label writes go through render_label — see header)
-- ============================================================================

local hov -- forward-declared: render_label branches on hov.is_hovered()

local function render_icon()
	local icon, icon_color
	if not state.connected then
		icon, icon_color = ICON_OFF, colors.muted
	else
		icon = signal_icon(tonumber(wifi_ev.rssi))
		icon_color = colors.fg
	end
	if state.vpn then -- utun override (existing behavior, colors.green)
		icon, icon_color = ICON_VPN, colors.green
	end
	wifi:set({ icon = { string = icon, color = icon_color } })
end

-- Resting head label: the dot separator lives HERE (not in one render
-- path) so every consumer — resting renders, hover collapse restore,
-- hover recomposition — sees the SAME dotted base. Hover gets a narrow
-- sep ("·" already ends the base) to avoid doubling it.
local function resting_label()
	local base = base_label()
	if base == "" then
		return ""
	end
	return base .. " ·"
end

local function render_label()
	if hov and hov.is_hovered() then
		hov.refresh(hover_payload())
	else
		wifi:set({ label = { string = resting_label(), color = state.vpn and colors.green or colors.fg } })
	end
end

hov = hover.new(wifi, hover_payload, { base = resting_label, sep = " " })

-- ============================================================================
-- DYNAMIC reserved band — re-measure the chips' rendered widths and size
-- the head's label padding to hug them. Closed loop, one-directional
-- (chip text → chip rect → head padding → head layout): the chips'
-- positions never depend on the band, so it cannot oscillate. Quantized
-- to 4pt steps with hysteresis (≥4pt delta) so per-tick jitter in the
-- speed strings doesn't churn the layout every 2s.
-- ============================================================================

local BAND_GUTTER = 4 -- head-text → counter gap (user-tuned +2: 2 read as
-- too tight against the "·" separator; each +1 here is +1px of gap,
-- modulo QUANTUM rounding slack + icon pad)
local BAND_MIN, BAND_MAX = 40, 84
local QUANTUM = 2 -- fine steps: 4pt quantization left up to 4pt slack and
-- the measured head→counter gap read 11pt; 2 keeps it ≈ gutter + icon pad
local band_current = 64 -- add-time value; tracked for hysteresis

local function retune_band()
	local ok_up, qu = pcall(function()
		return wifi_up:query()
	end)
	local ok_down, qd = pcall(function()
		return wifi_down:query()
	end)
	local widest = 0
	local function absorb(q)
		for _, r in pairs((q or {}).bounding_rects or {}) do
			local w = r and r.size and (r.size[1] or r.size[2]) or 0 -- Lua JSON arrays are 1-BASED: size[1]=width
			if w > widest then
				widest = w
			end
		end
	end
	if ok_up then
		absorb(qu)
	end
	if ok_down then
		absorb(qd)
	end
	if widest <= 0 then
		return -- no rects yet (pre-layout) — keep current band
	end
	-- quantize: round UP to the next quantum so the band only grows
	-- within a bucket, never clips mid-bucket
	local desired = math.ceil((widest + BAND_GUTTER) / QUANTUM) * QUANTUM
	desired = math.min(BAND_MAX, math.max(BAND_MIN, desired))
	if math.abs(desired - band_current) < QUANTUM then
		return -- within hysteresis — no churn
	end
	band_current = desired
	wifi:set({ label = { padding_right = desired } })
end

-- ============================================================================
-- Bandwidth (2s bridge events → cache + label-only render; icon unaffected)
-- ============================================================================

-- last-rendered chip state, idle flag folded in (it drives muted/fg) —
-- change detection per the cpu.lua/memory.lua last_value idiom: an idle
-- link ticks byte-identical strings every 2s, and the old form wrote
-- BOTH chips + scheduled a band-retune query on EVERY tick (~43k no-op
-- write cycles/day)
local last_up_state, last_down_state = nil, nil

wifi:subscribe("network_update", function(env)
	-- bridge sends lowercase keys (upload/download); normalize case.
	-- Chips carry the speeds (idle → muted); the head label is untouched
	-- here — a hovered head can never be collapsed by the 2s tick.
	bw.up = env.UPLOAD or env.upload or ""
	bw.down = env.DOWNLOAD or env.download or ""
	local up, idle_up = pretty(bw.up)
	local down, idle_down = pretty(bw.down)
	local up_state = (idle_up and "i" or "a") .. up
	local down_state = (idle_down and "i" or "a") .. down
	local up_changed = up_state ~= last_up_state
	local down_changed = down_state ~= last_down_state
	if not up_changed and not down_changed then
		return -- byte-identical tick — no writes, no retune
	end
	last_up_state, last_down_state = up_state, down_state
	-- SAME color for both counters (fg; muted when idle) — the old
	-- yellow/cyan split is retired per user preference
	if up_changed then
		wifi_up:set({
			icon = { color = idle_up and colors.muted or colors.fg },
			label = { string = up, color = idle_up and colors.muted or colors.fg },
		})
	end
	if down_changed then
		wifi_down:set({
			icon = { color = idle_down and colors.muted or colors.fg },
			label = { string = down, color = idle_down and colors.muted or colors.fg },
		})
	end
	-- DYNAMIC spacing: after the daemon lays out the new chip texts,
	-- re-measure their rendered widths and resize the head's reserved
	-- band to hug them (0.1s lets the render settle; quantized +
	-- hysteresis so jitter like "81 KBps"↔"337 KBps" doesn't churn).
	-- Only scheduled when a chip actually changed.
	sbar.delay(0.1, retune_band)
end)

-- ============================================================================
-- State refresh (30s tick + wifi_change/system_woke/forced + hs_wifi)
-- ============================================================================

local function refresh_state()
	sbar.exec("/usr/sbin/ipconfig getifaddr en0", function(ip)
		state.ip = (ip or ""):gsub("^%s+", ""):gsub("%s+$", "")
		state.connected = state.ip ~= ""

		-- VPN check (utun present overrides icon)
		sbar.exec("/usr/sbin/scutil --nwi | /usr/bin/grep -m1 utun", function(vpn)
			state.vpn = vpn and vpn ~= "" or false
			render_icon()
			render_label()
		end)

		-- SSID fallback: only while the HS cache is empty (HS down or
		-- Location-denied). Fact 8: ipconfig SSID content may itself be
		-- privacy-redacted ("<redacted>" marker) — treat that as empty so
		-- the chain degrades to the IP (show state/IP, never marker noise).
		if state.connected and wifi_ev.ssid == "" then
			sbar.exec(
				"/usr/sbin/ipconfig getsummary en0 | /usr/bin/awk -F ' SSID : ' '/ SSID : / {print $2; exit}'",
				function(ssid)
					state.ipconfig_ssid = (ssid or ""):gsub("^%s+", ""):gsub("%s+$", "")
					if state.ipconfig_ssid == "<redacted>" then
						state.ipconfig_ssid = ""
					end
					render_label()
				end
			)
		else
			state.ipconfig_ssid = ""
		end
	end)
end

wifi:subscribe({ "wifi_change", "system_woke", "forced" }, refresh_state)

-- ============================================================================
-- Hammerspoon bridge — hs_wifi (instant refresh on link/power/SSID change)
-- ============================================================================

wifi:subscribe("hs_wifi", function(env)
	wifi_ev.rssi = env.RSSI or ""
	wifi_ev.txrate = env.TXRATE or ""
	wifi_ev.ssid = env.SSID or ""
	refresh_state()
end)

-- ============================================================================
-- Detail popup rows (verbatim from the old bracket popup — now anchored on
-- `wifi`; names unchanged so sbar.query/copy keep working)
-- ============================================================================
local function detail_row(id, title)
	-- styled to MATCH the popup DSL's b.kv rows (helpers/popup.lua):
	-- muted key left in a 90pt column, value right in 160pt, and the
	-- same 12pt transparent row padding that b.add injects (without it
	-- the text hugs the popup edge — visually off vs every other popup)
	local row_icon = sbar.add("item", id .. ".t", {
		position = "popup." .. wifi.name,
		icon = {
			string = title,
			align = "left",
			width = 90,
			font = settings.font.text,
		},
		label = {
			string = "…",
			align = "right",
			width = 160,
			font = settings.font.text,
		},
		background = { height = 20, padding_left = 12, padding_right = 12 },
	})
	return row_icon
end

-- SSID row REMOVED (resting pill label shows it), IP row REMOVED (hover
-- append shows it), Link-rate row REMOVED (hover append shows it) — the
-- popup only carries data absent from the pill/hover (2026-09-04)
-- Popup header (muted, centered, not copyable) — created FIRST so the
-- popup's member order renders it on top
local row_hdr = sbar.add("item", "wifi.hdr.t", {
	position = "popup." .. wifi.name,
	icon = { drawing = false },
	-- width = the rows' fixed column span (90+160): align=center centers
	-- over the data instead of hugging left (dynamic width = no-op center)
	label = {
		string = "Wi-Fi",
		color = colors.muted,
		align = "center",
		width = 250,
		font = settings.font.bold,
	},
	background = { height = 20, padding_left = 12, padding_right = 12 },
})
local row_host = detail_row("wifi.host", "Hostname:")
local row_router = detail_row("wifi.router", "Router:")
-- bridge enrichment row (hs_wifi cache; "—" until an event carried data)
local row_rssi = detail_row("wifi.rssi", "RSSI:")

-- RSSI quality word (dBm → human). Rough 5GHz-band buckets.
local function rssi_quality(rssi)
	if rssi >= -55 then
		return "Excellent"
	elseif rssi >= -65 then
		return "Good"
	elseif rssi >= -75 then
		return "Fair"
	end
	return "Weak"
end

-- Fill the bridge-enrichment rows from the hs_wifi cache (no exec — the
-- values arrived with the event; muted "—" when never/not populated).
local function fill_signal_rows()
	local rssi = tonumber(wifi_ev.rssi)
	row_rssi:set({
		label = {
			string = rssi and (rssi .. " dBm (" .. rssi_quality(rssi) .. ")") or "—",
			color = rssi and colors.fg or colors.muted,
		},
	})
end

-- Click the pill → toggle detail popup (fills rows on open).
-- NAME-guarded: mouse.clicked is a broadcast — without the filter, any
-- click anywhere toggled this popup too.
-- Lifecycle via helpers/popup (central pill styling): the PERMANENT rows
-- below are registered with wifi_ctl:track (bracket-wrapped + hidden on
-- close, never removed); prefix avoids their names — the stale-row sweep
-- has nothing transient to clean in this popup.
local wifi_ctl = popup.new(wifi, { prefix = "wifi.transient." })
wifi:subscribe("mouse.clicked", popup.guard(wifi.name, function()
	wifi_ctl:toggle(function(b)
		fill_signal_rows()
		sbar.exec("/usr/sbin/networksetup -getcomputername", function(host)
			row_host:set({ label = { string = (host or ""):gsub("%s+$", "") } })
		end)
		sbar.exec("/usr/sbin/networksetup -getinfo Wi-Fi | /usr/bin/awk -F 'Router: ' '/^Router: / {print $2}'", function(r)
			row_router:set({ label = { string = (r or ""):gsub("%s+$", "") } })
		end)
		b.show()
	end)
end))

-- Popup rows: click to copy. Each row's subscription is NAME-guarded —
-- the click broadcast would otherwise run copy_label with a FOREIGN
-- env.NAME (querying that item and copying ITS label).
local function copy_label(env)
	local row = sbar.query(env.NAME)
	local value = row and row.label and row.label.value or ""
	if value == "" then
		return
	end
	-- Single-quoted printf: the value (SSID/hostname) can't break out of
	-- the shell string; embedded quotes escaped POSIX-style ('\'').
	sbar.exec(string.format("/usr/bin/printf '%%s' '%s' | /usr/bin/pbcopy", (value:gsub("'", "'\\''"))))
	sbar.set(env.NAME, { label = { string = "copied", align = "right" } })
	sbar.delay(1.0, function()
		sbar.set(env.NAME, { label = { string = value, align = "right" } })
	end)
end

local detail_rows = { row_host, row_router, row_rssi }
wifi_ctl:track(row_hdr.name)
for _, row in ipairs(detail_rows) do
	row:subscribe("mouse.clicked", popup.guard(row.name, copy_label))
	wifi_ctl:track(row.name) -- permanent rows: bracket-wrapped, never removed
end

-- Initial state + 30s refresh (bridge handles bandwidth continuously)
refresh_state()
local function tick()
	refresh_state()
	sbar.delay(30, tick)
end
tick()
