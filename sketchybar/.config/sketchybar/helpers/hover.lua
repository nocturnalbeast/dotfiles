-- helpers/hover.lua — reusable hover-reveal for pill labels (archive
-- pattern, modernized for this bar's helpers).
--
-- Usage:
--   local hover = require("helpers.hover")
--
--   -- APPEND mode (item already shows a label — hover widens the pill
--   -- with extra text after the separator, collapse restores the base):
--   local hov = hover.new(item, get_payload, { base = get_base })
--
--   -- REVEAL mode (icon-only item — label born width=0; hover sets the
--   -- string + width="dynamic", collapse re-zeroes the width):
--   local hov = hover.new(item, get_payload, { reveal = true })
--   (the item's label must be PRE-CREATED with width = 0 and drawing on)
--
--   -- REPLACE mode (label's RESTING string is kept truncated by the
--   -- item itself, Lua-side — hover swaps in the full payload string,
--   -- collapse restores base()):
--   local hov = hover.new(item, get_payload, {
--     mode = "replace", base = get_base })
--   NOTE: label.max_chars is parsed at item CREATION only — runtime
--   --set/set of it silently no-ops (not in the query schema either) —
--   so the resting truncation MUST be baked into base() by the caller.
--
--   get_payload()  → the extra/current string to reveal; "" = no-op reveal
--   opts.base()    → (append/replace modes) the RESTING label string,
--                    called fresh at reveal AND at collapse so a base that
--                    changed mid-hover (clock tick) still restores correctly
--
--   hov.refresh(payload) — event-driven items push a new payload string
--   from their existing update path (no new execs — cache-only); while
--   hovered, the label re-renders live. Pass nil to drop the cache and
--   defer to get_payload() again.
--
-- Mechanics: reveal/collapse are ATOMIC item:set calls — do NOT tween
-- them (sbar.animate) : a tweened width change slides the window frame
-- across the cursor and Carbon synthesizes a phantom mouse.entered that
-- latches the hover (regression 2026-09-04, clock pill). All mouse
-- subscriptions are popup.guard-ed (fact 14: handlers must filter on
-- env.NAME). mouse.exited.global is the collapse safety net.
--
-- opts.no_global_exit = true: skip hover's own mouse.exited.global
-- subscription — for items whose exited.global is ALREADY owned by a
-- popup controller (ctl:exited()). SBarLua's same-(item,event) double-
-- subscription dispatch is unverified; rather than bet on it, those
-- items subscribe ONCE with a merged handler calling ctl:close() +
-- hov:collapse(). (h.collapse is exposed for exactly that.)
--
-- Mode-gating: mouse events cannot hit an undrawn item (safe by
-- construction); get_payload/base must be pure cache reads — put NO
-- execs in them (refresh hooks come from existing update paths).
local popup = require("helpers.popup")

local M = {}


M.SEP = "  ·  " -- two spaces · two spaces

function M.new(item, get_payload, opts)
	opts = opts or {}
	local replace = (opts.mode == "replace")
	local h = { cached = nil }
	local hovered = false

	local function payload()
		if h.cached ~= nil then
			return h.cached
		end
		if type(get_payload) == "function" then
			return get_payload() or ""
		end
		return ""
	end

	local function base()
		if type(opts.base) == "function" then
			return opts.base() or ""
		end
		return ""
	end

	local function revealed_string(extra)
		if opts.reveal then
			return extra
		end
		-- opts.sep: per-item separator between base and payload (default
		-- M.SEP). Items whose base already ends in a separator glyph
		-- (tray's "SSID ·") pass a narrow sep to avoid doubling it.
		return base() .. (opts.sep or M.SEP) .. extra
	end

	-- Atomic (untweened) transitions — regression 2026-09-04: the old
	-- sbar.animate("tanh", 20, …) tween slid the item window frame
	-- (append items grow/shrink ~200pt) across the cursor's position.
	-- Carbon kEventMouseEntered fires when a tracking region sweeps over
	-- a cursor, so a leftward exit's collapse tween synthesized a
	-- PHANTOM mouse.entered right after the real mouse.exited — the
	-- hover latched expanded until the next real crossing. Atomic sets
	-- jump the frame in one transaction; a region that no longer
	-- contains the cursor cannot fire entered.
	local function apply_reveal(extra)
		if opts.reveal then
			item:set({ label = { string = extra, width = "dynamic" } })
		elseif replace then
			-- payload REPLACES the resting string outright (the item
			-- keeps its own resting truncation Lua-side — max_chars
			-- is add-time-only, see header note)
			item:set({ label = { string = extra } })
		else
			item:set({ label = { string = revealed_string(extra) } })
		end
	end

	local function reveal()
		local extra = payload()
		hovered = true
		if extra == "" then
			return -- no-op reveal (no data cached yet)
		end
		apply_reveal(extra)
	end

	local function collapse()
		if not hovered then
			return
		end
		hovered = false
		if opts.reveal then
			-- keep the string set (invisible at width 0); next hover
			-- just re-sets string first
			item:set({ label = { width = 0 } })
		else
			item:set({ label = { string = base() } })
		end
	end

	--- Push a fresh payload from an item's existing update path.
	function h.refresh(p)
		h.cached = p
		if hovered and p ~= nil and p ~= "" then
			apply_reveal(p)
		end
	end

	--- Is the pointer currently on this item (expansion active)? For items
	--- whose BASE label is rewritten by a frequent event (tray's 2s
	--- bandwidth tick): route every label render through one item-owned
	--- render() that branches on this — while true, hov.refresh(p)
	--- recomposes base() + payload (base called fresh, so the tick's new
	--- data lands INSIDE the expansion); while false, the item renders
	--- its base directly. Without this gate a tick-written base string
	--- would visually collapse an active hover. Additive — existing
	--- callers unaffected.
	function h.is_hovered()
		return hovered
	end

	--- Collapse now (idempotent). For merged exited.global handlers on
	--- popup-anchor items (opts.no_global_exit).
	function h.collapse()
		collapse()
	end

	item:subscribe("mouse.entered", popup.guard(item.name, reveal))
	item:subscribe("mouse.exited", popup.guard(item.name, collapse))
	if not opts.no_global_exit then
		item:subscribe("mouse.exited.global", popup.guard(item.name, collapse))
	end

	return h
end

return M
