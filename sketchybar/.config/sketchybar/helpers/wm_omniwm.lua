-- helpers/wm_omniwm.lua - OmniWM adapter (helpers/wm registry, Phase 4).
--
-- Event-driven refresh via plugins/omniwm_bridge (registers omniwmctl watch
-- processes that fire omniwm_bridge_evt sketchybar triggers; idempotent)
-- + a 120s safety refresh. Every trigger re-QUERIES full state (never-trust-
-- payloads invariant).
--
-- Display topology changes ONLY on plug/unplug - it is cached (start +
-- hs_screen ONLY, never in the sweep; cf. wm_aerospace) so the sweep stays
-- at 2 sequential queries per event.
--
-- ⚠ DATA PLANE (2026-09-14): `omniwmctl query … --format json` returns an
-- ENVELOPED payload (.result.payload.*) - and sbar.exec AUTO-DECODES it
-- into a Lua table (fact 4). The v1 adapter ran the JSON through jq→TSV
-- and tostring()'d the decoded table - the parser got "table: 0x…" and
-- the trio rendered permanently empty. This adapter consumes the decoded
-- tables DIRECTLY (no jq, no TSV). Raw JSON never round-trips as a
-- string at all.
--
-- Query schema (verified live, IPC v15): responses are enveloped
-- (.result.payload.*):
--   workspaces[] = { displayName, number, isFocused, isCurrent,
--                    counts: { total, tiled, floating },
--                    windows: { app_name, bundle_id, … } }
--   windows[]    = { app: { name, bundleId }, title, isFocused,
--                    workspace: { displayName, number } }
--   displays[]   = { id, name, isMain, isCurrent }
local M = { name = "omniwm" }

local wm = require("helpers.wm")

local OW = "/opt/homebrew/bin/omniwmctl"
local COALESCE_DELAY = 0.2
local SAFETY_REFRESH = 120

-- ============================================================================
-- STATE
-- ============================================================================

local ws_list = {} -- ordered workspace displayNames (bar labels)
local ws_number = {} -- displayName → workspace number (switch target)
local focused_ws = "" -- active workspace displayName
local apps_by_ws = {} -- ws displayName → { app names }
local focused_window = { app = "", title = "" }
local monitors = {} -- { { id, name } }
local focused_mon = "" -- id of the current display

local refresh_generation = 0
local on_sweep_cb = nil
local bound = false

-- JSON query: sbar.exec auto-decodes the enveloped JSON into a Lua table
-- (fact 4) - the raw JSON never round-trips as a string, and the decoder
-- handles OmniWM's nested shapes fine (unlike Rift's, which segfaulted).
local function query_json(subcmd, k)
	sbar.exec(OW .. " " .. subcmd .. " 2>/dev/null", function(out)
		k(type(out) == "table" and out or {})
	end)
end

local function refresh_all()
	local gen = refresh_generation

	-- 1. workspaces (+ per-ws app names nested in the same rows)
	query_json("query workspaces --format json", function(env)
		if refresh_generation ~= gen then
			return
		end
		local payload = (env.result or {}).payload or {}
		local rows = payload.workspaces or {}
		-- parse into fresh locals; commit ONLY on success (rows > 0) so a
		-- transient query failure keeps the last-known-good state instead
		-- of blanking the trio until the next event. apps_by_ws resets per
		-- commit (fresh table) - stale ws entries drop on success only.
		local new_ws_list, new_ws_number, new_apps_by_ws = {}, {}, {}
		local new_focused_ws = ""
		for _, w in ipairs(rows) do
			local name = tostring(w.displayName or "")
			if name ~= "" then
				new_ws_list[#new_ws_list + 1] = name
				new_ws_number[name] = w.number
				if w.isFocused then
					new_focused_ws = name
				end
				local apps = {}
				for _, win in ipairs(w.windows or {}) do
					apps[#apps + 1] = tostring(win.app_name or (win.app or {}).name or "")
				end
				new_apps_by_ws[name] = apps
			end
		end
		if #new_ws_list > 0 then
			ws_list, ws_number, focused_ws, apps_by_ws =
				new_ws_list, new_ws_number, new_focused_ws, new_apps_by_ws
		end
		-- 2. focused window (the isFocused row of query windows; written
		-- only when a focused row is found - failures keep last-known-good)
		query_json("query windows --format json", function(env2)
			if refresh_generation ~= gen then
				return
			end
			local payload2 = (env2.result or {}).payload or {}
			for _, w in ipairs(payload2.windows or {}) do
				if w.isFocused then
					focused_window = {
						app = tostring((w.app or {}).name or ""),
						title = tostring(w.title or ""),
					}
				end
			end
			if on_sweep_cb then
				on_sweep_cb()
			end
		end)
	end)
end

-- coalesced refresh (event storms → one query chain per 0.2s window)
local refresh_scheduled = false
local function schedule_refresh()
	if not bound then
		return -- unbound: stale triggers are skipped (no churn)
	end
	if refresh_scheduled then
		return
	end
	refresh_scheduled = true
	sbar.delay(COALESCE_DELAY, function()
		refresh_scheduled = false
		if bound then
			refresh_all()
		end
	end)
end

-- ============================================================================
-- TOPOLOGY (start + hs_screen ONLY - display layout changes on plug/unplug,
-- never in the sweep; keeps per-event cost at 2 sequential queries)
-- ============================================================================

local function refresh_topology()
	local gen = refresh_generation
	query_json("query displays --format json", function(env)
		if refresh_generation ~= gen then
			return
		end
		local payload = (env.result or {}).payload or {}
		-- displays: id | name | isCurrent - parse into fresh locals; commit
		-- ONLY on success (≥1 display) so a transient failure keeps the
		-- last-known-good topology
		local new_monitors, new_focused_mon = {}, ""
		for _, d in ipairs(payload.displays or {}) do
			local id = tostring(d.id or d.uuid or "")
			new_monitors[#new_monitors + 1] = { id = id, name = tostring(d.name or "") }
			if d.isCurrent then
				new_focused_mon = id
			end
		end
		if #new_monitors > 0 then
			monitors, focused_mon = new_monitors, new_focused_mon
		end
		if on_sweep_cb then
			on_sweep_cb()
		end
	end)
end

-- ============================================================================
-- OBSERVER (hidden item; omniwm_bridge_evt fires from the bridge)
-- ============================================================================

sbar.add("event", "omniwm_bridge_evt")
local bridge_observer = sbar.add("item", "omniwm.bridge_observer", { drawing = "off", updates = true })
bridge_observer:subscribe("omniwm_bridge_evt", schedule_refresh)
-- hs_screen (registered by init.lua BEFORE this module loads): display
-- layout changed - refresh the topology cache + a coalesced sweep (focus
-- may have moved with the display, cf. wm_aerospace)
bridge_observer:subscribe("hs_screen", function()
	if not bound then
		return -- unbound: stale triggers are skipped (no churn)
	end
	refresh_topology()
	schedule_refresh()
end)

-- ============================================================================
-- ACTIONS
-- ============================================================================

function M.switch_ws(name)
	-- focus-name takes the displayName (the trio's menus pass names);
	-- `command switch-workspace <number>` has slot semantics that did NOT
	-- map to the expected workspace (2026-09-14: 2→inet ok but 3→stayed)
	if name and name ~= "" then
		sbar.exec(OW .. " workspace focus-name '" .. name .. "'", function() end)
	end
end

function M.focus_monitor(id)
	-- omniwm focuses monitors by direction, not by id; next is the sane
	-- single-hop when the requested id isn't already current
	if id and id ~= focused_mon then
		sbar.exec(OW .. " command focus-monitor next", function() end)
	end
end

-- ============================================================================
-- ADAPTER API
-- ============================================================================

function M.detect(cb)
	-- ASYNC process probe (2026-09-27): sync io.popen on the
	-- supervisor's detect TIMER is a proven hang vector (Lua 5.5.1
	-- pclose reaping corruption; 2026-09-15/27 incidents) - the
	-- contract is now async-boolean-callback (helpers/wm header). Safe
	-- where the 2026-09-04 nil-cb crash came from: that callback was
	-- NOT always invoked - this one always is. pgrep stdout is a plain
	-- string in sbar.exec (non-JSON) - empty/nil/false = stopped.
	sbar.exec("/usr/bin/pgrep -x OmniWM 2>/dev/null", function(out)
		cb(out ~= nil and out ~= "" and out ~= false)
	end)
end

function M.start(cb)
	on_sweep_cb = cb
	bound = true
	refresh_generation = refresh_generation + 1
	-- topology cache: fetched once here (hs_screen refreshes it later) -
	-- the sweep never queries displays
	refresh_topology()
	sbar.exec("/bin/sh /Users/betranttitus/.config/sketchybar/plugins/omniwm_bridge", function()
		refresh_all()
	end)
	local gen = refresh_generation
	local function periodic()
		if gen ~= refresh_generation or not bound then
			return
		end
		refresh_all()
		sbar.delay(SAFETY_REFRESH, periodic)
	end
	sbar.delay(SAFETY_REFRESH, periodic)
end

function M.stop()
	bound = false
	on_sweep_cb = nil
	refresh_generation = refresh_generation + 1
	-- the omniwmctl watch processes keep running (--reconnect) but their
	-- triggers are skipped while unbound; rebind re-registers nothing
	-- (idempotent bridge)
end

function M.get_state()
	return {
		workspace_list = ws_list,
		focused = {
			ws = focused_ws,
			app = focused_window.app,
			title = focused_window.title,
			monitor_id = focused_mon,
		},
		apps_by_ws = apps_by_ws,
		topology = { loaded = true, mirrored = false, monitors = monitors },
	}
end

wm.register(M)

return M
