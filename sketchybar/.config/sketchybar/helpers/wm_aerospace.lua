-- helpers/wm_aerospace.lua - AeroSpace adapter (helpers/wm registry).
--
-- OWNS the AeroSpace data plane (moved verbatim from items/aerospace.lua
-- in the 2026-09-04 adapter extraction - Phase 1, zero behavior change):
--   * commands (byte budgets: fact 3/15):
--       focused workspace ~5B · ws|apps map ≤320B · focused window ≤200B
--       monitor topology ~150B JSON · mirror state ~24B (system_profiler)
--   * sweep: 3 tiny execs, FULL RE-QUERY per event (never trust payloads,
--     aerospace 0.21.x bug window), 0.2s coalescing via generation counter
--   * monitor TOPOLOGY + mirror state: SLOW (system_profiler ~0.5s) -
--     queried ONLY at start + hs_screen, never in the sweep
--   * 120s periodic safety refresh; initial sweep at start
--   * hidden observer subscribed to the three aerospace events
--     (registered as events by init.lua BEFORE this module loads) +
--     hs_screen (topology is display-layout dependent)
--
-- NOT owned here: the trio items, glyphs, hover payloads, render
-- change-detection, menus, app-menu strip - those are the widget's
-- (items/aerospace.lua); they consume this adapter via helpers/wm.
local M = { name = "aerospace" }

local wm = require("helpers.wm")

local AEROSPACE = "/opt/homebrew/bin/aerospace"

-- Hard ceiling for the remaining sync/slow exec sites below: a wedged
-- child must die, not leak - the same hang-class hardening that took
-- io.popen off the detect loop (Lua 5.5.1 pclose reaping corruption,
-- 2026-09-15/27 incidents)
local TIMEOUT = "/opt/homebrew/bin/timeout"

local COALESCE_DELAY = 0.2
local SAFETY_REFRESH = 120

-- ============================================================================
-- Commands
-- ============================================================================

-- Focused workspace (~5B).
local FOCUSED_WS_CMD = AEROSPACE .. " list-workspaces --focused 2>/dev/null"

-- Batched window listing, collapsed per-workspace by awk: "ws|app1,app2,"
-- per line, first-seen order, dedup pairs; head -c caps the transport
-- (~160B live; ~300B at 24 unique pairs). Feeds the ws hover payload.
local WINDOWS_CMD = AEROSPACE .. [[ list-windows --all --format '%{workspace}|%{app-name}' 2>/dev/null ]]
	.. [[| /usr/bin/awk -F'|' ']]
	.. [[!seen[$1]++ { order[++n] = $1 } ]]
	.. [[!dup[$0]++ { apps[$1] = apps[$1] $2 "," } ]]
	.. [[END { for (i = 1; i <= n; i++) { nm = order[i]; print nm "|" apps[nm] } }']]
	.. [[ 2>/dev/null | /usr/bin/head -c 320]]

-- Focused window: app|title|monitor-id (title may contain "|" - parse as
-- first field | greedy middle | trailing digits). ≤200B; a title long
-- enough to hit the cap fails the trailing-digits match and is simply
-- skipped (next event/refresh catches up). monitor-id feeds the monitor
-- pill FREE - no extra exec.
local FOCUSED_WINDOW_CMD = AEROSPACE
	.. [[ list-windows --focused --format '%{app-name}|%{window-title}|%{monitor-id}' 2>/dev/null ]]
	.. [[| /usr/bin/head -c 200]]

-- Monitor topology (~150B JSON, auto-decoded - fact 4) + mirror state
-- (~24B: one "Mirror: On/Off" line per display). SLOW (system_profiler
-- ~0.5s) - start + hs_screen ONLY, never in the sweep. Both are
-- timeout-wrapped (8s ceiling: system_profiler is slow legitimately; a
-- hung aerospace/system_profiler child must not stall the topology
-- refresh path - 2026-09-27)
local MONITORS_CMD = TIMEOUT .. " 8 " .. AEROSPACE .. " list-monitors --json 2>/dev/null"
local MIRROR_CMD = TIMEOUT .. " 8 /usr/sbin/system_profiler SPDisplaysDataType 2>/dev/null"
	.. [[ | /usr/bin/grep -i mirror | /usr/bin/head -n 4]]

-- ============================================================================
-- STATE
-- ============================================================================

local workspace_list = {} -- ordered workspace names (declared toml order)
local workspace_list_loaded = false -- LAZY (2026-09-15): filled at first
-- start() - the old module-scope io.popen ran a synchronous aerospace
-- spawn on EVERY bar load even when AeroSpace was never bound; the ws
-- menu's refresh-on-empty (items/aerospace.lua) covers a WM-down load

local focused = { ws = "", app = "", title = "", monitor_id = "" }
local apps_by_ws = {} -- ws -> { app names } (WINDOWS_CMD parse)

-- topology cache (start + hs_screen only): monitors = { {id,name}, … }
local topology = { loaded = false, mirrored = false, monitors = {} }

local sweep_generation = 0 -- only the latest deferred timer sweeps
local on_sweep_cb = nil -- widget render callback (invoked post-sweep)
-- stop() bumps this: the periodic poll chain self-terminates when its
-- generation is stale (sbar.delay timers cannot be cancelled directly)
local poll_gen = 0
-- start()/stop() gate (wm_rift/wm_omniwm idiom): aerospace events and
-- hs_screen fire on the observer even while another WM is bound -
-- schedule_sweep/refresh_topology no-op until the supervisor binds us
local bound = false

-- ============================================================================
-- Workspace list (declared order parser - unchanged from the strip era)
-- ============================================================================

local function load_declared_order()
	local path = os.getenv("HOME") .. "/.config/aerospace/aerospace.toml"
	local f = io.open(path, "r")
	if not f then
		return {}
	end
	local content = f:read("*a") or ""
	f:close()
	local order = {}
	local block = content:match("persistent%-workspaces%s*=%s*%[(.-)%]")
	if block then
		for name in block:gmatch("'([^']+)'") do
			order[#order + 1] = name
		end
	end
	return order
end

local function load_workspace_list()
	-- timeout 5 (2026-09-27): this io.popen runs at first bind / ws-menu
	-- refresh - the same pclose hang class; a hung aerospace must not
	-- wedge the adapter start path
	local handle = io.popen(TIMEOUT .. " 5 " .. AEROSPACE .. " list-workspaces --all 2>/dev/null")
	if not handle then
		return {}
	end
	local out = handle:read("*a") or ""
	handle:close()
	local list = {}
	for name in out:gmatch("[^\r\n]+") do
		local ws = name:gsub("^%s+", ""):gsub("%s+$", "")
		if ws ~= "" then
			list[#list + 1] = ws
		end
	end
	-- Stable-sort by declared order; unknown workspaces keep emitted order
	local rank = {}
	for i, name in ipairs(load_declared_order()) do
		rank[name] = i
	end
	local max = #list + #rank + 1
	table.sort(list, function(a, b)
		local ra, rb = rank[a] or max, rank[b] or max
		if ra == rb then
			return a < b
		end
		return ra < rb
	end)
	return list
end

-- (workspace_list is NOT loaded at module scope - see
-- workspace_list_loaded in STATE: lazy, at first start())

-- ============================================================================
-- SWEEP (3 tiny execs; full re-query, never deltas)
-- ============================================================================

local function parse_windows_map(output)
	local map = {}
	for line in string.gmatch(output or "", "[^\r\n]+") do
		local ws, apps = line:match("^(.-)|(.*)$")
		if ws and apps then
			local ws_trimmed = ws:gsub("^%s+", ""):gsub("%s+$", "")
			if ws_trimmed ~= "" then
				local bucket = map[ws_trimmed]
				if not bucket then
					bucket = {}
					map[ws_trimmed] = bucket
				end
				for app in string.gmatch(apps, "[^,]+") do
					local app_trimmed = app:gsub("^%s+", ""):gsub("%s+$", "")
					if app_trimmed ~= "" then
						bucket[#bucket + 1] = app_trimmed
					end
				end
			end
		end
	end
	return map
end

local function sweep()
	-- 1. focused workspace (ALWAYS re-queried, never from the event)
	sbar.exec(FOCUSED_WS_CMD, function(ws_output)
		local ws = (ws_output or ""):gsub("^%s+", ""):gsub("%s+$", "")
		if ws ~= "" then
			focused.ws = ws
		end
		-- 2. batched ws→apps map (ws hover payload)
		sbar.exec(WINDOWS_CMD, function(windows_output)
			apps_by_ws = parse_windows_map(windows_output)
			-- 3. focused window: app | title | monitor-id (title = greedy
			-- middle so "|" inside titles survives)
			sbar.exec(FOCUSED_WINDOW_CMD, function(fw_output)
				local line = (fw_output or ""):gsub("^%s+", ""):gsub("%s+$", "")
				if line == "" then
					-- no focused window (native-fullscreen edge): keep the
					-- last known focused monitor, hide the window pill
					focused.app, focused.title = "", ""
				else
					local app, title, mon = line:match("^(.-)|(.*)|(%d+)$")
					if app then
						focused.app = app
						focused.title = title
						focused.monitor_id = mon
					end
				end
				if on_sweep_cb then
					on_sweep_cb()
				end
			end)
		end)
	end)
end

local function schedule_sweep()
	if not bound then
		return -- unbound: stale triggers are skipped (no churn)
	end
	sweep_generation = sweep_generation + 1
	local generation = sweep_generation
	sbar.delay(COALESCE_DELAY, function()
		if generation == sweep_generation and bound then
			sweep()
		end
	end)
end

-- ============================================================================
-- TOPOLOGY (start + hs_screen ONLY - system_profiler is ~0.5s, never in
-- the sweep; both execs are event-gated)
-- ============================================================================

local function refresh_topology()
	sbar.exec(MONITORS_CMD, function(out)
		if type(out) ~= "table" then -- JSON auto-decode (fact 4)
			return
		end
		local monitors = {}
		for _, m in ipairs(out) do
			local id = tostring(m["monitor-id"] or "")
			local name = tostring(m["monitor-name"] or "")
			if id ~= "" then
				monitors[#monitors + 1] = { id = id, name = name }
			end
		end
		topology.monitors = monitors
		-- mirror probe second: render only once both caches land (render
		-- is idempotent - safe if this fires between the two)
		sbar.exec(MIRROR_CMD, function(mirror_out)
			topology.mirrored = (mirror_out or ""):find("Mirror:%s*On", 1) ~= nil
			topology.loaded = true
			if on_sweep_cb then
				on_sweep_cb()
			end
		end)
		if on_sweep_cb then
			on_sweep_cb()
		end
	end)
end

-- ============================================================================
-- OBSERVER (hidden item subscribed to the aerospace events; hs_screen
-- ALSO refreshes topology - the slow probe is event-gated. Both are
-- gated on `bound`: no-op while the supervisor has another WM bound)
-- ============================================================================

local observer = sbar.add("item", "aerospace.observer", { drawing = "off", updates = true })
observer:subscribe("aerospace_workspace_change", schedule_sweep)
observer:subscribe("aerospace_focus_change", schedule_sweep)
observer:subscribe("aerospace_update_windows", schedule_sweep)
observer:subscribe("hs_screen", function()
	if not bound then
		return -- unbound: stale triggers are skipped (no churn)
	end
	refresh_topology()
	schedule_sweep()
end)

-- ============================================================================
-- ACTIONS
-- ============================================================================

--- Refresh workspace_list (sync io.popen; cb optional). The list loads
-- lazily at first start() (2026-09-15 - was a synchronous spawn at
-- module scope on every bar load); a bar load while the WM is down
-- bakes an EMPTY list - the ws menu refreshes on open (2026-09-04).
function M.refresh_workspace_list(cb)
	workspace_list = load_workspace_list()
	if cb then
		cb(workspace_list)
	end
end

function M.switch_ws(name)
	if name and name ~= "" then
		sbar.exec(AEROSPACE .. " workspace " .. name, function() end)
	end
end

function M.focus_monitor(id)
	if id then
		sbar.exec(AEROSPACE .. " focus-monitor -- " .. id, function() end)
	end
end

-- ============================================================================
-- ADAPTER API (helpers/wm contract)
-- ============================================================================

function M.start(cb)
	on_sweep_cb = cb
	bound = true
	-- lazy workspace-list load (first bind only): keeps the aerospace
	-- spawn off the module require path - every bar load, WM or not
	if not workspace_list_loaded then
		workspace_list_loaded = true
		workspace_list = load_workspace_list()
	end
	poll_gen = poll_gen + 1
	local gen = poll_gen
	-- Initial sweep at start - aerospace fires nothing at login.
	sweep()
	refresh_topology()
	local function periodic_refresh()
		if gen ~= poll_gen or not bound then
			return -- superseded by stop()/re-start
		end
		sweep()
		sbar.delay(SAFETY_REFRESH, periodic_refresh)
	end
	periodic_refresh()
end

function M.stop()
	-- late sweep callbacks no-op (on_sweep_cb nil), the poll chain
	-- self-terminates via the stale generation, and observer triggers
	-- are skipped while unbound (bound = false)
	bound = false
	on_sweep_cb = nil
	poll_gen = poll_gen + 1
end

function M.detect(cb)
	-- ASYNC process probe (2026-09-27): the sync io.popen form ran on
	-- the supervisor's detect TIMER - a proven hang vector (Lua 5.5.1
	-- pclose reaping corruption; 2026-09-15/27 incidents), so the
	-- contract is now async-boolean-callback (helpers/wm header). Safe
	-- where the 2026-09-04 nil-cb crash came from: that callback was
	-- NOT always invoked - this one always is. AeroSpace is a GUI app
	-- (bobko.aerospace); app running == backend usable. pgrep stdout
	-- is a plain string in sbar.exec (non-JSON) - empty/nil/false =
	-- not running.
	sbar.exec("/usr/bin/pgrep -x AeroSpace 2>/dev/null", function(out)
		cb(out ~= nil and out ~= "" and out ~= false)
	end)
end

function M.get_state()
	return {
		workspace_list = workspace_list,
		focused = focused,
		apps_by_ws = apps_by_ws,
		topology = topology,
	}
end

wm.register(M)

return M
