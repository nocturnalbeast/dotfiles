-- helpers/wm.lua — WM supervisor / adapter registry.
--
-- The trio widget (items/aerospace.lua) is WM-AGNOSTIC: it renders state
-- delivered by the active ADAPTER and never talks to a WM CLI directly.
-- Adapters implement the per-WM data plane:
--
--   adapter.name           string id ("aerospace" | "rift" | "omniwm")
--   adapter.start(on_sweep)  begin producing state; MUST call on_sweep()
--                          after every state change (initial render at
--                          start included)
--   adapter.stop()         cancel timers/poll chains; late on_sweep
--                          callbacks must no-op afterwards
--   adapter.detect(cb)     ASYNC liveness probe ("is this WM alive
--                          right now?"): MUST invoke cb(boolean)
--                          exactly once, promptly — pgrep via
--                          sbar.exec, empty output = not running.
--                          Async BY CONTRACT (2026-09-27): the sync
--                          io.popen probe ran inside the supervisor's
--                          detect TIMER callback — a proven hang
--                          vector (Lua 5.5.1 pclose reaping corruption
--                          wedges the interpreter's main thread in
--                          wait4 and freezes the daemon via
--                          mach_send — 2026-09-15/27 incidents). NO
--                          io.popen on recurring timer/event paths,
--                          ever. (The old 2026-09-04 nil-cb crash came
--                          from a callback that was NOT always invoked;
--                          the async form is safe BECAUSE the callback
--                          is always invoked.)
--   adapter.get_state()    LIVE state tables — workspace_list, focused,
--                          apps_by_ws, topology. Tables may be REASSIGNED
--                          by the adapter on refresh → re-fetch via
--                          get_state() at every render/payload use; never
--                          cache the returned tables.
--   adapter.switch_ws(name) / adapter.focus_monitor(id)   actions
--
--   MONITOR IDS ARE OPAQUE STRINGS, never numbers (aerospace: numeric
--   strings from its CLI json; rift: display UUIDs; omniwm: its own
--   ids) — compare them as strings and pass them through verbatim;
--   never tonumber.
--
-- SUPERVISOR (Phase 2, 2026-09-04; hardened 2026-09-15; probes ASYNC
-- since 2026-09-27): the detect loop probes the ACTIVE adapter first
-- (early-return while it answers — zero extra forks) and otherwise
-- scans registered adapters every
-- DETECT_INTERVAL seconds in prefer order, binding the FIRST live one.
-- On transitions it stops the previous adapter and flips the trio's
-- visibility (opts.set_visible). Probe/bind/render calls are
-- error-contained (pcall/xpcall + logs) so the loop ALWAYS re-arms.
-- With no WM running the trio hides entirely (user choice: degraded
-- states live in logs, not in bar furniture).

local M = { adapters = {}, active = nil, active_name = nil }

local DETECT_INTERVAL = 30 -- seconds between liveness probes (WM
-- switches are login-time events; hot-switch latency ≤30s is fine —
-- adapter events and safety refreshes cover the gaps)

-- Supervision-loop error log. sbar.log is NOT part of this SBarLua
-- build's API surface (verified: add/animate/begin_config/delay/
-- end_config/exec/query/remove/set_bar_name/subscribe/trigger), so
-- fall back to print — the Lua host's stdout, i.e. sketchybar's log.
-- Guarded so an error path can never cascade.
local function log_err(msg)
	if type(sbar.log) == "function" then
		pcall(sbar.log, "[wm] " .. msg)
	else
		print("[wm] " .. msg)
	end
end

function M.register(adapter)
	M.adapters[adapter.name] = adapter
	return adapter
end

--- The currently bound adapter (nil when no WM is running).
function M.active_adapter()
	return M.active
end

-- internal state (set by M.supervise)
local render_cb, set_visible_cb, prefer_order = nil, nil, nil
local detect_running = false
-- detect-loop generation (the adapters' poll_gen idiom): async probe
-- results can land after a newer tick has started (slow exec, stalled
-- machine) — a stale chain must neither bind nor re-arm, or the loop
-- would fork into duplicate detect timers
local detect_gen = 0

local function apply(name, live)
	-- same backend already bound → no churn (re-applying every detect
	-- tick stop/started the adapter each cycle, killing in-flight query
	-- chains before their render — the "trio stuck empty" bug).
	-- (M.active in the guard: a FAILED bind keeps active_name set but
	-- no adapter bound — a later tick must be allowed to re-apply)
	if name == M.active_name and M.active then
		return
	end
	-- teardown previous (late sweep callbacks no-op via adapter.stop)
	if M.active then
		M.active.stop()
		M.active = nil
	end
	local usable = false
	if name then
		local a = M.adapters[name]
		-- liveness was probed by the CALLER (detect_tick) — the probe
		-- result is passed through; no second fork here
		usable = live == true
		if usable then
			-- bind BEFORE start: adapters may sweep synchronously at
			-- start (initial render) and the widget resolves the
			-- active adapter live on every render
			M.active = a
			-- containment: a throwing start must not kill the detect
			-- loop — log, unbind, mark unusable (next tick retries)
			local ok_start, err = pcall(a.start, function()
				if render_cb then
					xpcall(render_cb, function(e)
						log_err("render callback failed (" .. tostring(name) .. "): " .. tostring(e))
					end)
				end
			end)
			if not ok_start then
				M.active = nil
				usable = false
				log_err("adapter start failed (" .. tostring(name) .. "): " .. tostring(err))
			end
		end
	end
	M.active_name = name
	if set_visible_cb then
		set_visible_cb(usable)
	end
end

local function detect_tick()
	if not detect_running then
		return
	end
	detect_gen = detect_gen + 1
	local gen = detect_gen

	local finished = false
	-- FINAL function: with async probes, every path (live keep-alive,
	-- scan terminal, contained error) simply calls this last — the
	-- re-arm ALWAYS executes, so supervision survives until sketchybar
	-- reloads. The flag makes it idempotent (an error path can finish a
	-- chain that is still pending — the pending end then no-ops)
	local function finish()
		if finished then
			return
		end
		finished = true
		-- unconditional re-arm — the supervision loop must never die
		sbar.delay(DETECT_INTERVAL, detect_tick)
	end

	-- containment for async continuations: a throw inside a probe
	-- result handler is logged and swallowed, and the chain STILL
	-- finishes (re-arms)
	local function contained(fn)
		return function(...)
			local ok, err = pcall(fn, ...)
			if not ok then
				log_err("detect_tick failed: " .. tostring(err))
				finish()
			end
		end
	end

	-- ASYNC liveness probe: adapter.detect(cb) with a boolean callback
	-- (contract in the header). A sync throw while LAUNCHING a broken
	-- adapter.detect is logged and reported as not-live — the same
	-- containment the old sync probes had, never a dead supervision
	-- loop. `once` keeps the callback single-shot against pathological
	-- adapters and drops results from superseded chains (generation
	-- guard above)
	local function probe(name, cb)
		local adapter = M.adapters[name]
		if not adapter then
			cb(false)
			return
		end
		local answered = false
		local function once(live)
			if answered or gen ~= detect_gen then
				return -- duplicate answer or stale chain — drop it
			end
			answered = true
			cb(live)
		end
		local ok, err = pcall(adapter.detect, once)
		if not ok then
			log_err("detect probe failed (" .. tostring(name) .. "): " .. tostring(err))
			once(false)
		end
	end

	-- probe in prefer order; first live adapter wins (the binding that
	-- just probed dead is skipped — no double probe). The recursion is
	-- a CHAIN (max depth = registry size, 3), not a tree
	local function scan(i, probed_dead)
		local name = prefer_order[i]
		if not name then
			apply(nil) -- no supported WM running → trio hides
			finish()
			return
		end
		if name == probed_dead then
			scan(i + 1, probed_dead) -- already probed dead this tick
			return
		end
		probe(name, contained(function(live)
			if live then
				apply(name, true) -- probe result passed through
				finish()
				return
			end
			scan(i + 1, probed_dead)
		end))
	end

	-- containment: any throw in the SYNC launch below is logged and
	-- swallowed — finish() ALWAYS runs, from the chain or from here
	local ok, err = pcall(function()
		-- ACTIVE-FIRST: probe the bound adapter and stop while it
		-- answers (zero extra forks, zero wasted probes). Only a
		-- dead/absent binding falls through to the prefer-order scan.
		if M.active and M.active_name then
			local active_name = M.active_name
			probe(active_name, contained(function(live)
				if live then
					finish() -- still alive — keep the binding (no churn)
					return
				end
				-- dead: scan the prefer order, skipping the just-probed
				scan(1, active_name)
			end))
			return
		end
		scan(1, nil)
	end)
	if not ok then
		log_err("detect_tick failed: " .. tostring(err))
		finish()
	end
end

--- Start supervising. opts:
---   render       fn()                       re-render the trio
---   set_visible  fn(show)                   hide/show the trio pills
---   prefer       { "name", … }              probe order (first live binds)
function M.supervise(opts)
	opts = opts or {}
	render_cb = opts.render
	set_visible_cb = opts.set_visible
	prefer_order = opts.prefer or {}
	if detect_running then
		return
	end
	detect_running = true
	-- slight delay: the caller's items must exist before the first
	-- apply/render cycle touches them
	sbar.delay(0.2, detect_tick)
end

return M
