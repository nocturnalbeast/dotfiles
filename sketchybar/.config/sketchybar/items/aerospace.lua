-- items/aerospace.lua - AeroSpace TRIO (compact three-segment design,
-- replaces the full workspace strip + items/front_app.lua):
--
--   [mode_switch] [aerospace.monitor] [aerospace.ws] [aerospace.window]
--
--   * aerospace.monitor - display-layout pill: mirrored 󰍡 / extended
--     (focused monitor's type: 󰌢 Built-in, 󰍹 external) / hidden when
--     single-monitor. Click → monitor-focus menu. Hover (reveal) →
--     layout summary.
--   * aerospace.ws - ACTIVE workspace pill: ws-type glyph + name. Click →
--     workspace picker menu (declared toml order, current accent).
--     Hover (append) → app names in the active ws.
--   * aerospace.window - ACTIVE window pill: app ligature + title
--     (Lua-side trunc at 50 - max_chars is add-time-only). Hidden when no
--     focused window. Hover (replace) →
--     full untruncated title.
--
-- ADAPTER EXTRACTION (2026-09-04, Phase 1): this file is now the
-- WM-AGNOSTIC WIDGET - it renders state and owns nothing AeroSpace-specific.
-- The data plane (commands, sweep, parsing, topology, actions, observer,
-- timers) lives in helpers/wm_aerospace.lua behind the helpers/wm adapter
-- registry; Rift/OmniWM adapters slot in behind the same interface
-- (Phase 3/4). Rendering is driven by the adapter's on_sweep callback -
-- driven by the supervisor's detect loop (wm.supervise at file end).
--
-- Invariants preserved from the strip era:
--   * FULL RE-QUERY per event - never trust event payloads (adapter-owned)
--   * change-detection caches here - no label churn
local colors = require("colors")
local settings = require("settings")
local icons = require("helpers.icons")
local pill = require("helpers.pill")
local popup = require("helpers.popup")
local hover = require("helpers.hover")
local wm = require("helpers.wm")
require("helpers.wm_aerospace") -- registers the AeroSpace adapter (side effect)
require("helpers.wm_rift") -- registers the Rift adapter
require("helpers.wm_omniwm") -- registers the OmniWM adapter

-- The ACTIVE adapter (resolved per call - the supervisor may re-bind on
-- WM hot-switch; never cache the returned adapter)
local function AD()
	return wm.active_adapter()
end

local SB_BIN = "/opt/homebrew/bin/sketchybar"

-- Menu pick round-trip events (click_script → custom event → subscriber;
-- click_script is daemon-side hit-tested, so no fact-14 broadcast hazard -
-- the mode_switch menu idiom, see AGENT.md "mode_switch menu contract").
-- Registered BEFORE the items that subscribe to them.
sbar.add("event", "ws_menu_pick")
sbar.add("event", "monitor_menu_pick")

-- ============================================================================
-- Glyph maps (VictorMono NF, verified)
-- ============================================================================

local WS_GLYPHS = {	-- ported from ~/.dotfiles/polybar/.config/polybar/env (ICON_WORKSPACE_0..9, positional)
	main = "", -- U+E795
	inet = "󰇧", -- U+F01E7
	code = "󰅴", -- U+F0174
	data = "󰉋", -- U+F024B
	play = "󰈯", -- U+F022F
	docs = "󰈙", -- U+F0219
	draw = "", -- U+F1FC
	txns = "󰇚", -- U+F01DA
	info = "󰓅", -- U+F04C5
	misc = "", -- U+F2D0
}
local WS_GLYPH_DEFAULT = ""	-- fa-star_of_life (env default)

local ICON_MIRROR = "󰍡"
local ICON_LAPTOP = "󰌢"
local ICON_DISPLAY = "󰍹"

-- ============================================================================
-- ITEM CREATION - add order = render order: monitor, ws, window
-- (left side renders in ADD order; fact 2)
-- ============================================================================

local monitor_item = sbar.add("item", "aerospace.monitor", {
	position = "left",
	drawing = "off", -- hidden until topology says multi-monitor/mirrored
	icon = {
		string = ICON_DISPLAY,
		color = colors.fg,
		padding_left = 8,
		padding_right = 6,
		y_offset = 1, -- NF ink ~1.7pt low (see battery.lua note)
	},
	-- hover-reveal label (helpers/hover reveal mode): born ZERO-WIDTH so
	-- the resting pill is unchanged (mode_switch pattern)
	label = {
		string = "",
		width = 0,
		font = settings.font.text,
		color = colors.fg,
		padding_left = 0,
		padding_right = 8,
	},
	background = pill.background(),
	padding_left = settings.paddings,
	padding_right = settings.paddings,
	popup = { align = "center" },
})

local ws_item = sbar.add("item", "aerospace.ws", {
	position = "left",
	icon = {
		string = WS_GLYPH_DEFAULT,
		color = colors.accent, -- the ACTIVE ws (echoes the strip's focused
		-- highlight_color accent without a permanent accent pill)
		padding_left = 8,
		padding_right = 6,
		y_offset = 1, -- NF ink ~1.7pt low (see battery.lua note)
	},
	label = {
		string = "",
		font = settings.font.text,
		color = colors.fg,
		padding_right = 8,
		max_chars = 40, -- bounds append-hover growth (app-name lists)
	},
	background = pill.background(),
	padding_left = settings.paddings,
	padding_right = settings.paddings,
	popup = { align = "center" },
})

local window_item = sbar.add("item", "aerospace.window", {
	position = "left",
	drawing = "off", -- no focused window yet
	icon = {
		-- inherits the sbar.default icon font (settings.font.icons =
		-- VictorMono NF) - the single icon font; app glyphs come from
		-- helpers/icons.lua's generated NF map (NF glyph ink sits ~1.7pt
		-- low in its em-box - +1 nudge, like every other pill icon)
		string = "󰖯",
		padding_left = 8,
		padding_right = 6,
		y_offset = 1, -- NF ink ~1.7pt low (see battery.lua note)
	},
	label = {
		string = "",
		font = settings.font.text,
		color = colors.fg,
		padding_right = 8,
		-- belt only (never binds): real truncation is Lua-side
		-- trunc_title() - max_chars is add-time-only
		max_chars = 64,
	},
	background = pill.background(),
	padding_left = settings.paddings,
	-- 6: the outer spacer before the app-menu strip's pill bg -
	-- PIXEL-calibrated (visual gap = this + 2 bg-inset slop = the
	-- standard 8pt; rect-level 8 measured 10 visually)
	padding_right = 6,
})

-- ============================================================================
-- HOVER (payloads are cache-only - see AGENT.md hover convention)
-- ============================================================================

local function ws_apps_payload()
	local st = AD().get_state()
	local apps = st.apps_by_ws[st.focused.ws]
	if not apps or #apps == 0 then
		return ""
	end
	local joined = table.concat(apps, ", ")
	if #joined > 120 then
		joined = joined:sub(1, 117) .. "…"
	end
	return joined
end

local function monitor_name(id)
	local st = AD().get_state()
	for _, m in ipairs(st.topology.monitors) do
		if m.id == id then
			return m.name
		end
	end
	return ""
end

local function monitor_summary()
	local st = AD().get_state()
	if not st.topology.loaded then
		return ""
	end
	if st.topology.mirrored then
		return "Mirrored"
	end
	local names = {}
	for _, m in ipairs(st.topology.monitors) do
		names[#names + 1] = m.name
	end
	return "Extended · " .. table.concat(names, " + ")
end

local shown_ws = ""
local shown_win = { app = "", title = "" }
local shown_mon = { show = nil, icon = "" }

-- ws pill: append mode (base = ws name)
local hov_ws = hover.new(ws_item, ws_apps_payload, {
	base = function()
		return shown_ws
	end,
	no_global_exit = true,
})

-- monitor pill: reveal mode (label born width 0)
local hov_monitor = hover.new(monitor_item, monitor_summary, {
	reveal = true,
	no_global_exit = true,
})

-- window pill: REPLACE mode (payload = full title; resting string is the
-- Lua-truncated title - label.max_chars is add-time-only and no-ops at
-- runtime, so the truncation lives in trunc_title()). No popup → hover
-- owns all three subscriptions (vol/memory pattern).
local function trunc_title(t)
	if #t > 50 then -- user-tuned limit (was 30); hover (replace) shows full title
		return t:sub(1, 49) .. "…"
	end
	return t
end

local hov_window = hover.new(window_item, function()
	return AD().get_state().focused.title
end, {
	mode = "replace",
	base = function()
		return trunc_title(AD().get_state().focused.title)
	end,
})

-- ============================================================================
-- RENDER (change-detection caches - no label churn)
-- ============================================================================

local function render_ws()
	local st = AD().get_state()
	if st.focused.ws ~= "" and st.focused.ws ~= shown_ws then
		shown_ws = st.focused.ws
		ws_item:set({
			icon = { string = WS_GLYPHS[st.focused.ws] or WS_GLYPH_DEFAULT },
			label = { string = st.focused.ws },
		})
	end
	hov_ws.refresh(ws_apps_payload())
end

local function render_window()
	local st = AD().get_state()
	if st.focused.app == "" then
		if shown_win.app ~= "" then
			shown_win = { app = "", title = "" }
			window_item:set({ drawing = "off" })
		end
		return
	end
	if st.focused.app ~= shown_win.app or st.focused.title ~= shown_win.title then
		shown_win = { app = st.focused.app, title = st.focused.title }
		window_item:set({
			drawing = "on",
			icon = { string = icons.get(st.focused.app) },
			-- Lua-side truncation (max_chars prop is add-time-only)
			label = { string = trunc_title(st.focused.title) },
		})
	end
	hov_window.refresh(st.focused.title)
end

local function render_monitor()
	local st = AD().get_state()
	if not st.topology.loaded then
		return
	end
	local show, icon
	if st.topology.mirrored then
		show, icon = true, ICON_MIRROR
	elseif #st.topology.monitors >= 2 then
		-- focused monitor type: focused.monitor_id comes FREE from the
		-- focused-window sweep query
		show = true
		icon = monitor_name(st.focused.monitor_id):find("Built-in", 1, true)
			and ICON_LAPTOP
			or ICON_DISPLAY
	else
		show = false -- single monitor: hidden entirely (polybar behavior)
	end
	if show ~= shown_mon.show or icon ~= shown_mon.icon then
		shown_mon = { show = show, icon = icon }
		monitor_item:set({
			drawing = show and "on" or "off",
			icon = { string = icon },
		})
	end
	hov_monitor.refresh(monitor_summary())
end

local function render_all()
	render_ws()
	render_window()
	render_monitor()
end

-- ============================================================================
-- MENUS (helpers/popup lifecycle; rows tracked + removed by exact name)
-- ============================================================================

local ws_ctl = popup.new(ws_item)

local function build_ws_menu(b)
	-- hot-swap race: builds run in popup's ASYNC stale-sweep callback -
	-- the adapter may have died between click and build
	local a = AD()
	if not a then
		return
	end
	local st = a.get_state()
	if #st.workspace_list == 0 then
		-- refresh_workspace_list is an OPTIONAL adapter method (only
		-- wm_aerospace implements it) - a blind nil-call crashed the
		-- handler under rift/omniwm
		if a.refresh_workspace_list then
			-- bar loaded while the WM was down → the load-time list is
			-- empty; refresh once and build in the callback (b.show is
			-- generation-guarded: a close during the fetch is a no-op)
			a.refresh_workspace_list(function()
				local a2 = AD() -- re-resolve: the hot-swap race again
				if not a2 then
					return
				end
				if #a2.get_state().workspace_list > 0 then
					build_ws_menu(b)
				else
					b.header("Workspaces")
					b.empty("no workspaces reported")
					b.show()
				end
			end)
			return
		end
		-- no refresher + empty list: the uniform empty state (popups
		-- open even with no data; they never refuse)
		b.header("Workspaces")
		b.empty("no workspaces reported")
		b.show()
		return
	end
	b.header("Workspaces")
	for _, ws in ipairs(st.workspace_list) do -- declared toml order
		local is_current = (ws == st.focused.ws)
		-- row icon = the workspace's own glyph (WS_GLYPHS, same map the
		-- ws pill renders); active ws is highlighted by accent color on
		-- icon+label - NO check mark (the highlight is enough, user
		-- request 2026-09-04)
		b.action(WS_GLYPHS[ws] or WS_GLYPH_DEFAULT, ws,
			SB_BIN .. " --trigger ws_menu_pick TARGET=" .. ws,
			{ color = is_current and colors.accent or nil })
	end
	b.show()
end

ws_item:subscribe("ws_menu_pick", function(env)
	ws_ctl:close()
	-- custom triggers can fire while the trio is hidden (drawing=off)
	-- or mid hot-swap - never dereference a nil adapter
	local a = AD()
	if not a then
		return
	end
	-- selecting the current ws = no-op close (no churn)
	if env.TARGET and env.TARGET ~= "" and env.TARGET ~= a.get_state().focused.ws then
		a.switch_ws(env.TARGET)
	end
end)

local mon_ctl = popup.new(monitor_item)

local function build_monitor_menu(b)
	-- hot-swap race: builds run in popup's ASYNC stale-sweep callback
	local a = AD()
	if not a then
		return
	end
	local st = a.get_state()
	if #st.topology.monitors == 0 then
		return
	end
	b.header("Displays")
	for _, m in ipairs(st.topology.monitors) do
		local is_current = (m.id == st.focused.monitor_id)
		-- row glyph = the monitor pill's own icon grammar (mirror /
		-- Built-in laptop / external display); active = accent (the
		-- check mark retired with the ws picker rework, 2026-09-04)
		local glyph = ICON_MIRROR
		if not st.topology.mirrored and not m.name:find("Built-in", 1, true) then
			glyph = ICON_DISPLAY
		elseif not st.topology.mirrored then
			glyph = ICON_LAPTOP
		end
		b.action(glyph, m.name,
			SB_BIN .. " --trigger monitor_menu_pick TARGET=" .. m.id,
			{ color = is_current and colors.accent or nil })
	end
	b.show()
end

monitor_item:subscribe("monitor_menu_pick", function(env)
	mon_ctl:close()
	-- custom triggers can fire while the trio is hidden (drawing=off)
	-- or mid hot-swap - never dereference a nil adapter
	local a = AD()
	if not a then
		return
	end
	-- monitor ids are OPAQUE STRINGS (aerospace: numeric strings; rift:
	-- display UUIDs; omniwm: its own) - compare as strings, pass
	-- through verbatim; NEVER tonumber (Rift UUIDs nil out)
	local current = a.get_state().focused.monitor_id
	if env.TARGET and env.TARGET ~= "" and (current == "" or env.TARGET ~= current) then
		a.focus_monitor(env.TARGET)
	end
end)

-- ============================================================================
-- MOUSE (popup.guard on every handler - facts 13/14)
-- ============================================================================

ws_item:subscribe("mouse.clicked", popup.guard(ws_item.name, function()
	local a = AD() -- hot-swap race - a click can land on an unbound trio
	if not a then
		return
	end
	ws_ctl:toggle(build_ws_menu)
end))

monitor_item:subscribe("mouse.clicked", popup.guard(monitor_item.name, function()
	local a = AD() -- hot-swap race - a click can land on an unbound trio
	if not a then
		return
	end
	mon_ctl:toggle(build_monitor_menu)
end))

-- MERGED exited.global handlers (one subscription: popup close + hover
-- collapse - the established no_global_exit pattern)
ws_item:subscribe("mouse.exited.global", popup.guard(ws_item.name, function()
	ws_ctl:close()
	hov_ws.collapse()
end))
monitor_item:subscribe("mouse.exited.global", popup.guard(monitor_item.name, function()
	mon_ctl:close()
	hov_monitor.collapse()
end))

-- ============================================================================
-- Bar-hover app-menu strip - hovering ANYWHERE over the bar reveals the
-- front app's macOS menu-bar titles as an inline text strip immediately
-- AFTER the window pill (left side grows rightward into the gap before
-- the right wing); leaving the bar collapses it.
--
-- Architecture:
--   * app_menu.1 .. app_menu.N (N=12) - position LEFT, created AFTER
--     aerospace.window so they render after it (left side = ADD order,
--     fact 2). Born label width = 0 + icon off → zero footprint at rest
--     (the reveal-mode pattern). Each chip's click_script clicks the REAL
--     macOS menu (`menus -s N` - plugins/menus, Accessibility-granted)
--     then fires `app_menu_hover_off` to collapse the strip.
--   * bar.hover.observer - hidden always-on item (aerospace.observer
--     idiom) subscribing the GLOBAL mouse events:
--       mouse.entered.global → EXPAND  (cached titles → labels, dynamic)
--       mouse.exited.global  → COLLAPSE (widths back to 0)
--       app_menu_hover_off   → COLLAPSE (post-selection)
--       front_app_switched   → async titles refresh (`menus -l`)
--     NO popup.guard on these handlers - DELIBERATE (fact-14 corollary,
--     source-verified in bar_manager.c v2.24.0): the .global variants are
--     broadcast via bar_manager_custom_events_trigger to EVERY subscribed
--     item on bar-enter/bar-leave transitions - fanning out IS the
--     feature; a NAME guard would break it. Forced synthetic triggers
--     take the same fan-out path, so CLI validation behaves identically.
--   * Titles cache: fetched once at module load + refreshed async on
--     front_app_switched (the exec never blocks the event handler).
--     Truncated to 24 chars Lua-side at render time.
-- ============================================================================

local MENUS_BIN = os.getenv("HOME") .. "/.config/sketchybar/plugins/menus"
local MENU_CHIPS = 12

-- "SF Pro Text:Regular:14.0" → family/style parts for the 9pt chip font

sbar.add("event", "app_menu_hover_off")

local menu_titles = {}

local function refresh_menu_titles()
	sbar.exec(MENUS_BIN .. " -l 2>/dev/null | /usr/bin/head -n " .. MENU_CHIPS, function(out)
		local t = {}
		for line in string.gmatch(out or "", "[^\r\n]+") do
			local s = line:gsub("^%s+", ""):gsub("%s+$", "")
			if s ~= "" then
				t[#t + 1] = s
			end
		end
		menu_titles = t
	end)
end

local menu_chips = {}
for i = 1, MENU_CHIPS do
	menu_chips[i] = sbar.add("item", "app_menu." .. i, {
		position = "left",
		icon = { drawing = false },
		label = {
			string = "",
			width = 0, -- zero footprint at rest; expand sets dynamic
			-- SAME font as every other pill label (settings.font.text,
			-- 14pt) - the 9pt mini-style is retired per user preference
			font = settings.font.text,
			color = colors.fg,
			-- (label pl is inert on width-0 chips - the INSET comes from
			-- the item pl below; kept 0 here)
			padding_left = 0,
			padding_right = 8, -- gap between titles when expanded (= label pr convention)
		},
		background = { drawing = false },
		-- first chip's ITEM padding = the title's inset from the strip
		-- pill's left edge (w=0 chips: item pl shifts content inside the
		-- bg; the pill GAP itself comes from window's pr=8 above)
		padding_left = i == 1 and 8 or 0,
		padding_right = 0,
		click_script = MENUS_BIN .. " -s " .. i .. " && "
			.. SB_BIN .. " --trigger app_menu_hover_off",
	})
end

-- The strip's pill: an IN-BAR bracket around the chips (brackets are
-- bar-layer groups - correct here, unlike popup windows which draw their
-- own background). GATED: drawing off while collapsed so the width-0
-- chips never draw an empty pill; on during expansion only.
local menu_bracket = sbar.add("bracket", "app_menu.bracket", (function()
	local members = {}
	for i = 1, MENU_CHIPS do
		members[i] = menu_chips[i].name
	end
	return members
end)(), {
	drawing = "off",
	background = pill.background(),
	padding_left = 0,
	padding_right = 0,
	-- NO bracket paddings: bracket padding EXTENDS the bg beyond the
	-- member cells (cancels island gaps / doubles content insets -
	-- measured). Left gap + title inset come from chip 1's item/label
	-- paddings; right inset from every chip's label pr=8.
})

local bar_hover = sbar.add("item", "bar.hover.observer", { drawing = "off", updates = true })

bar_hover:subscribe("mouse.entered.global", function()
	if #menu_titles == 0 then
		return
	end
	menu_bracket:set({ drawing = "on" }) -- pill bounds the same items; immediate toggle
	sbar.animate("tanh", 20, function()
		for i = 1, MENU_CHIPS do
			local t = menu_titles[i]
			if t then
				menu_chips[i]:set({ label = { string = t:sub(1, 24), width = "dynamic" } })
			end
		end
	end)
end)

local function collapse_menu_strip()
	menu_bracket:set({ drawing = "off" })
	sbar.animate("tanh", 20, function()
		for i = 1, MENU_CHIPS do
			menu_chips[i]:set({ label = { width = 0 } })
		end
	end)
end

bar_hover:subscribe("mouse.exited.global", collapse_menu_strip)
bar_hover:subscribe("app_menu_hover_off", collapse_menu_strip)
bar_hover:subscribe("front_app_switched", refresh_menu_titles)

refresh_menu_titles()

-- ============================================================================
-- SUPERVISE - hand the trio to the WM supervisor: it detects which
-- supported WM is running (active-first probe, then prefer order every
-- 30s), binds/unbinds the matching adapter, and hides the trio entirely
-- when none runs (user choice: degraded states live in logs, not in bar
-- furniture).
-- ============================================================================
local function set_trio_visible(show)
	ws_item:set({ drawing = show and "on" or "off" })
	if not show then
		-- window/monitor manage their own drawing on the next bind's
		-- render - force them off while hidden (no sweep will run)
		window_item:set({ drawing = "off" })
		monitor_item:set({ drawing = "off" })
	end
end

wm.supervise({
	render = render_all,
	set_visible = set_trio_visible,
	prefer = { "aerospace", "rift", "omniwm" },
})
