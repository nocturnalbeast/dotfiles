-- helpers/wm_rift.lua - Rift adapter (helpers/wm registry, Phase 3).
--
-- Event-driven refresh via plugins/rift_bridge (registers
-- rift_bridge_evt sketchybar triggers for workspace/window/focus/title
-- events; idempotent - leaves dotfile subscriptions alone) + a 30s
-- safety refresh. Every trigger re-QUERIES full state (never-trust-
-- payloads invariant).
--
-- ⚠ SEGFAULT history (2026-09-14): the config SEGFAULTED (exit 139) once
-- with this adapter bound; root cause was never isolated - bridging/
-- queries/detect were all suspects. The queries stay jq→TSV deliberately
-- (raw JSON never reaches sbar.exec's auto-decoder - a segfault suspect
-- on nested/null JSON, unconfirmed). Rift quirks (v0.5.8.1): workspace
-- ids are opaque strings ("VirtualWorkspaceId(1v1)"); CLI subscriptions
-- do NOT survive a Rift restart (the supervisor's re-bind re-runs the
-- idempotent bridge, and the 30s periodic re-arms dead subscribers);
-- the user's dotfile Rift subscriptions must never be unsubscribed
-- (no unsub-cli).
local M = { name = "rift" }

local wm = require("helpers.wm")

local RC = "/opt/homebrew/bin/rift-cli"
local JQ = "/usr/bin/jq"
local BRIDGE = "/bin/sh /Users/betranttitus/.config/sketchybar/plugins/rift_bridge"
local BRIDGE_ANCHOR = "sketchybar --trigger rift_bridge_evt" -- unique to OUR subscribers' trigger argv
local COALESCE_DELAY = 0.2
local SAFETY_REFRESH = 30

-- ============================================================================
-- STATE
-- ============================================================================

local ws_list = {} -- ordered workspace names
local ws_ids = {} -- name → rift workspace id (opaque string)
local ws_index = {} -- name → numeric WORKSPACE_ID (what `workspace switch` takes)
local focused_ws = "" -- active workspace name
local apps_by_ws = {} -- ws name → { app names }
local focused_window = { app = "", title = "" }
local focused_mon = "" -- uuid of the active-context display (stage 4 sets it)
local workspaces = {} -- rift-native workspace rows (get_state reads these)
local displays = {} -- rift-native display rows (get_state's monitor view reads these)

local refresh_generation = 0
local on_sweep_cb = nil
local bound = false

local function split_tsv(line)
	local parts = {}
	local pos = 1
	while true do
		local t = line:find("\t", pos, true)
		if not t then
			parts[#parts + 1] = line:sub(pos)
			break
		end
		parts[#parts + 1] = line:sub(pos, t - 1)
		pos = t + 1
	end
	return parts
end

-- TSV query: output is deliberately NOT JSON - sbar.exec passes the raw
-- string through and we parse Lua-side (see the segfault note above).
local function query_tsv(subcmd, jq_filter, k)
	sbar.exec(RC .. " " .. subcmd .. " 2>/dev/null | " .. JQ .. " -r " .. jq_filter, function(out)
		k(tostring(out or ""))
	end)
end

local function refresh_all()
	local gen = refresh_generation

	-- 1. workspaces: name | active | id
	query_tsv("query workspaces", [['.[] | [.name, (.is_active|tostring), .id] | @tsv']], function(tsv)
		if refresh_generation ~= gen then
			return
		end
		ws_list, ws_ids, focused_ws, apps_by_ws = {}, {}, "", {}
		ws_index = {}
		workspaces = {}
		for line in tsv:gmatch("[^\r\n]+") do
			local p = split_tsv(line)
			if p[1] and p[1] ~= "" then
				local name, active, id = p[1], p[2], p[3]
				-- jq emits 3 columns (name|active|id); `workspace switch`
				-- takes the row's 0-based index - enumerated HERE (the
				-- pre-insert #ws_list IS that row's 0-based position),
				-- never a 4th TSV column.
				ws_index[name] = #ws_list
				ws_list[#ws_list + 1] = name
				ws_ids[name] = id
				-- PUBLISH to the module table: get_state() reads THIS table
				-- (the parsed rows must never stay stage-local - that kept
				-- the trio permanently empty, 2026-09-14)
				workspaces[#workspaces + 1] = {
					name = name,
					id = id,
					is_active = (active == "true"),
				}
				if active == "true" then
					focused_ws = name
				end
			end
		end
		-- 2. per-ws apps (windows nested under each workspace)
		query_tsv("query workspaces", [['.[] | .name as $ws | .windows[] | [$ws, .app_name] | @tsv']], function(t2)
			if refresh_generation ~= gen then
				return
			end
			for line in t2:gmatch("[^\r\n]+") do
				local ws, app = line:match("^([^\t]*)\t(.*)$")
				if ws and app and app ~= "" then
					apps_by_ws[ws] = apps_by_ws[ws] or {}
					apps_by_ws[ws][#apps_by_ws[ws] + 1] = app
				end
			end
			-- 3. focused window: app | title (is_focused row)
			query_tsv("query windows", [['.[] | select(.is_focused) | [.app_name, .title] | @tsv']], function(t3)
				if refresh_generation ~= gen then
					return
				end
				for line in t3:gmatch("[^\r\n]+") do
					local app, title = line:match("^([^\t]*)\t(.*)$")
					if app and app ~= "" then
						focused_window = { app = app, title = title }
					end
				end
				-- 4. displays: uuid | name | active-context | screen-id
				query_tsv("query displays", [['.[] | [.uuid, .name, (.is_active_context|tostring), (.screen_id|tostring)] | @tsv']], function(t4)
					if refresh_generation ~= gen then
						return
					end
					displays = {}
					for line in t4:gmatch("[^\r\n]+") do
						local p = split_tsv(line)
						if p[1] and p[1] ~= "" then
							-- PUBLISH to the module table (same rule as the
							-- workspaces stage - get_state() reads it)
							displays[#displays + 1] = {
								uuid = p[1],
								name = p[2],
								is_active_context = (p[3] == "true"),
								screen_id = tonumber(p[4]),
							}
							if p[3] == "true" then
								focused_mon = p[1]
							end
						end
					end
					if on_sweep_cb then
						on_sweep_cb()
					end
				end)
			end)
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
-- OBSERVER (hidden item; rift_bridge_evt fires from the bridge)
-- ============================================================================

sbar.add("event", "rift_bridge_evt")
local bridge_observer = sbar.add("item", "rift.bridge_observer", { drawing = "off", updates = true })
bridge_observer:subscribe("rift_bridge_evt", schedule_refresh)

-- ============================================================================
-- ACTIONS
-- ============================================================================

function M.switch_ws(name)
	-- `workspace switch` takes the NUMERIC workspace id - empirically the
	-- query row's 0-based index (NOT the opaque VirtualWorkspaceId string:
	-- "switch 'VirtualWorkspaceId(2v1)'" → "invalid digit found in string";
	-- switch 2 → inet ✓ 2026-09-14). Keep ws_index as the source of truth.
	local idx = ws_index[name]
	if idx then
		sbar.exec(RC .. " execute workspace switch " .. idx, function() end)
	end
end

function M.focus_monitor(id)
	if id then
		sbar.exec(RC .. " execute display focus --uuid '" .. id .. "'", function() end)
	end
end

-- ============================================================================
-- ADAPTER API
-- ============================================================================

function M.detect(cb)
	-- ASYNC process probe (2026-09-27): the sync io.popen form ran on
	-- the supervisor's detect TIMER - a proven hang vector (Lua 5.5.1
	-- pclose reaping corruption; 2026-09-15/27 incidents), so the
	-- contract is now async-boolean-callback (helpers/wm header). Safe
	-- where the 2026-09-04 nil-cb crash came from: that callback was
	-- NOT always invoked - this one always is. The daemon binary is
	-- `rift`; `rift-cli` may exist while Rift is stopped. pgrep stdout
	-- is a plain string in sbar.exec (non-JSON) - empty/nil/false =
	-- stopped.
	sbar.exec("/usr/bin/pgrep -x rift 2>/dev/null", function(out)
		cb(out ~= nil and out ~= "" and out ~= false)
	end)
end

function M.start(cb)
	on_sweep_cb = cb
	bound = true
	refresh_generation = refresh_generation + 1
	sbar.exec(BRIDGE, function()
		refresh_all()
	end)
	local gen = refresh_generation
	local function periodic()
		if gen ~= refresh_generation or not bound then
			return
		end
		refresh_all()
		-- Re-arm insurance: Rift subscribers have no --reconnect and die
		-- with the WM - without this, event delivery silently degrades to
		-- this 30s poll after a mid-window Rift restart. Probe liveness by
		-- the bridge's anchor (the trigger argv only OUR subscribers carry)
		-- and re-run the idempotent bridge when they're gone.
		sbar.exec("/usr/bin/pgrep -f '" .. BRIDGE_ANCHOR .. "' 2>/dev/null", function(out)
			if gen == refresh_generation and bound and not (out and out:match("%d")) then
				sbar.exec(BRIDGE, function() end)
			end
		end)
		sbar.delay(SAFETY_REFRESH, periodic)
	end
	sbar.delay(SAFETY_REFRESH, periodic)
end

function M.stop()
	bound = false
	on_sweep_cb = nil
	refresh_generation = refresh_generation + 1
	-- NOTE: our Rift-side cli subscriptions stay registered (removing them
	-- would require unsub-cli, which nukes the user's dotfile subs).
	-- Rebind re-registers nothing (idempotent bridge) and stale triggers
	-- are skipped while unbound.
end

function M.get_state()
	local monitors_view = {}
	for _, d in ipairs(displays) do
		monitors_view[#monitors_view + 1] = { id = d.uuid, name = d.name }
	end
	return {
		workspace_list = ws_list,
		focused = {
			ws = focused_ws,
			app = focused_window.app,
			title = focused_window.title,
			monitor_id = focused_mon,
		},
		apps_by_ws = apps_by_ws,
		topology = { loaded = true, mirrored = false, monitors = monitors_view },
	}
end

wm.register(M)

return M
