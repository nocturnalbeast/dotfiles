-- init.lua — entry point (required by sketchybarrc after package.cpath setup).
-- Stateless-rebuild idiom: everything below re-runs cleanly on --reload.
sbar = require("sketchybar")

local colors = require("colors")
local settings = require("settings")

-- Bundle the entire initial configuration into a single message to sketchybar
sbar.begin_config()

-- ============================================================================
-- Bar — FLOATING OVERLAY geometry (plan §2, from archived config's dimens)
-- ============================================================================
sbar.bar({
	height = 32,
	topmost = "window",
	y_offset = 5,
	margin = 10,
	corner_radius = 5,
	-- Disconnected-module look (quickshell ShadowedModule style): the bar
	-- itself is invisible; each item renders its own frosted pill.
	color = colors.with_alpha(colors.bg, 0.0),
	blur_radius = 0,
	position = "top",
	-- 0 = outermost pills sit flush on the bar's own edge (the floating
	-- overlay's margin=10 is then the ONLY screen inset; the outermost
	-- items' own outer padding is trimmed to 0 too — mode_switch left,
	-- power right — see those files). Inter-pill island gaps elsewhere
	-- come from item paddings and are unchanged.
	padding_left = 0,
	padding_right = 0,
	border_width = 0,
})

-- ============================================================================
-- Defaults
-- ============================================================================
sbar.default({
	padding_left = settings.paddings,
	padding_right = settings.paddings,
	icon = {
		font = settings.font.icons,
		color = colors.fg,
	},
	label = {
		font = settings.font.text,
		color = colors.fg,
	},
	background = {
		color = colors.transparent,
	},
})

-- ============================================================================
-- Events
-- ============================================================================

-- AeroSpace event contract (plan §5): registered BEFORE any item subscribes.
sbar.add("event", "aerospace_workspace_change")
sbar.add("event", "aerospace_focus_change")
sbar.add("event", "aerospace_update_windows")

-- Reload-free mode swap (AGENT.md facts 15–17): mode.toggle() writes the
-- mode file then triggers this; every mode-exclusive item subscribes and
-- flips its own drawing/updates. Registered BEFORE items, same contract
-- as the aerospace events above.
sbar.add("event", "mode_changed")

-- Hammerspoon bridge events (~/.hammerspoon/init.lua — see AGENT.md
-- "Hammerspoon event bridge"). The bridge registers these too
-- (idempotent no-op when they exist); registering here guarantees they
-- exist BEFORE item subscription regardless of boot order. system_woke
-- is BUILTIN and deliberately NOT registered. media_update is the push
-- channel from plugins/media_control_reader.
sbar.add("event", "hs_battery")
sbar.add("event", "hs_audio")
sbar.add("event", "hs_lock")
sbar.add("event", "hs_wifi")
sbar.add("event", "hs_screen")
sbar.add("event", "media_update")

-- ============================================================================
-- Items
-- ============================================================================

-- Left side renders in ADD order → mode_switch leftmost, then the
-- aerospace TRIO: [monitor] [active-ws] [active-window] (items/
-- aerospace.lua adds them in exactly that order — fact 2). front_app was
-- DELETED; its role is the trio's active-window pill.
require("items.mode_switch")
require("items.aerospace")

-- Right wing — RIGHT-side items render in REVERSE add order (first added
-- = rightmost at the screen edge; fact 2). ONE canonical UNION order
-- serves BOTH modes: hidden items leave NO layout slot (fact 15), so
-- flipping drawing alone re-flows the bar — no reload, no --move.
--
-- UNION add order:   power caffeine battery tray weather uptime clock
--                     bluetooth brightness vol media disk memory cpu
-- monitor-visible subset (power battery tray weather uptime disk memory
--   cpu) reversed → cpu memory disk uptime weather wifi battery power
--   (caffeine is main-mode-only — unchanged by the 2026-09-04 move)
-- main-visible subset (power caffeine battery tray clock bluetooth
--   brightness vol media) reversed → media vol bright bt clock wifi
--   battery caffeine power — caffeine sits BETWEEN battery and power
--   (user request 2026-09-04; quickshell main-bar right-wing order was
--   volume brightness bluetooth clock keepAwake tray sessionPower;
--   battery adjacent to power — we keep battery always: P0-1).
-- (battery ADJACENT TO POWER in both modes. Derivation, not taste:
--   enumerate the union, filter by mode, reverse. Keep this comment in
--   sync with any order change — it is the fact-2 trap solution.)
require("items.power")
require("items.caffeine") -- between power+battery visually (reverse add order)
require("items.battery")
require("items.tray")
require("items.weather")
require("items.uptime")
require("items.clock")
require("items.bluetooth")
require("items.brightness")
require("items.vol")
require("items.media")
require("items.disk")
require("items.memory")
require("items.cpu")

-- ============================================================================
-- hs_lock consumption — one-shot refresh burst on unlock (screen state
-- may be stale after lock/sleep: media, wifi, battery, focused window).
-- Hidden always-on observer (mode.relay / aerospace.observer idiom —
-- fact 17: delivery must not depend on gated items' updates flags).
--   * system_woke (builtin, forced bare) reaches battery + wifi (both
--     subscribe it) and media (via its media.sync observer, polling-gated)
--   * aerospace_focus_change re-queries the aerospace TRIO (the observer
--     item is updates=true forever — window/ws/monitor resync; replaces
--     the old front_app osascript re-query, deleted with front_app.lua)
-- On STATE=locked: nothing (by contract).
-- ============================================================================
local lock_observer = sbar.add("item", "lock.observer", { drawing = "off", updates = true })
lock_observer:subscribe("hs_lock", function(env)
	if env.STATE ~= "unlocked" then
		return
	end
	sbar.trigger("system_woke")
	sbar.trigger("aerospace_focus_change")
end)

-- ============================================================================
-- Bridge resync — a config RELOAD starts with empty HS-event caches
-- (wifi RSSI/txrate/SSID, battery watts/health, vol device). The bridge
-- is push-only (watchers fire on CHANGE), so we ask it to re-emit its
-- snapshots shortly after every load: `hs -c 'hsbridge.resync()'` (see
-- ~/.hammerspoon/init.lua emitter registry). Fire-and-forget — HS down
-- → exec fails silently, items' fallback polls cover the gap. The
-- second (15s) attempt covers fresh boot, where HS starts after us.
-- ============================================================================
local RESYNC_CMD = "/opt/homebrew/bin/hs -c 'hsbridge.resync()' 2>/dev/null"
-- 2>/dev/null: if HS is mid-(re)load, `hsbridge.resync` can briefly be
-- nil — the IPC error lands on stderr; silenced, the 15s retry covers it.
sbar.delay(2, function()
	sbar.exec(RESYNC_CMD, function() end)
end)
sbar.delay(15, function()
	sbar.exec(RESYNC_CMD, function() end)
end)

sbar.end_config()
sbar.event_loop()
