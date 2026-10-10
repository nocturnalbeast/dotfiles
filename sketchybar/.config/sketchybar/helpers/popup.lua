-- helpers/popup.lua - the ONE popup lifecycle idiom for every click-popup
-- in the bar (bluetooth / clock / cpu / weather / power / battery / uptime
-- / disk). Replaces five divergent open/close implementations.
--
-- Usage:
--   local popup = require("helpers.popup")
--   local ctl = popup.new(anchor_item)   -- anchor carries popup={align=...}
--   -- (bluetooth passes { prefix = "bt." } - legacy row names)
--
--   local function build(b)              -- called synchronously by ctl:open
--     b.add("item.pop.row", { ... })     -- full item name; anchored at
--                                        -- popup.<anchor> automatically
--     b.show()                           -- reveal (call AFTER rows exist;
--                                        -- async builds may defer it)
--   end
--
--   anchor:subscribe("mouse.clicked", ctl:clicked(build))
--   anchor:subscribe("mouse.exited.global", ctl:exited())
--
--   -- EXTERNALLY-owned rows (created by the caller, e.g. tray's permanent
--   -- detail rows): hidden with the popup and joined to its pill, but
--   -- NEVER removed by close() - the owning module manages their lifetime:
--   ctl:track("wifi.ssid.t")
--
-- Pill treatment: the anchor's NATIVE popup background is styled once at
-- controller creation (popup.background = pill + 10pt corner) - popup
-- windows draw their own background; BRACKETS CANNOT style them
-- (group_calculate_bounds runs in the bar layout loop and collapses around
-- popup-positioned members - the failed first attempt). Row breathing room
-- comes from b.add injecting transparent per-row background padding.
--
-- Semantics:
--   * ctl:open(build)  marks open, bumps a generation counter, then (after
--                      the stale-row sweep below) runs build
--   * ctl:close()      hides the popup AND removes every child row this
--                      controller created - by EXACT name, tracked in
--                      Lua. Varying-length lists never leave stale rows.
--   * b.add / b.show   are no-ops once a newer open/close has superseded
--                      the build's generation (async-safe: clock/cpu
--                      rows arrive from sbar.exec AFTER the click)
--
-- WHY tracked exact names instead of sbar.remove("/regex/"): sketchybar
-- compiles /…/ arguments as POSIX ERE, where `%` is a LITERAL - the old
-- Lua-escaped forms like sbar.remove("/bt%.dev%.*/") matched nothing
-- (silent no-ops; rows silently accumulated). (AGENT.md machine fact 13.)
--
-- ============================================================================
-- Broadcast-event NAME guard (mouse.* events)
-- ============================================================================
-- mouse.clicked / mouse.scrolled / mouse.exited.global are BROADCAST
-- events: EVERY subscriber's callback fires, with env.NAME identifying
-- the item that was actually clicked/scrolled/exited. An unguarded
-- handler therefore runs on EVERY interaction in the bar - observed
-- live: a clock click toggled the bar MODE via mode_switch's unguarded
-- handler, and any popup-anchor click fired every other popup at once
-- (exec storm + EPIPE noise). ALWAYS wrap mouse.* handlers:
--
--   item:subscribe("mouse.clicked", popup.guard(item.name, function() ... end))
--
-- (or use the ctl:clicked/ctl:exited conveniences for popup anchors).
local pill = require("helpers.pill")

local M = {}

function M.guard(name, fn)
	return function(env)
		if env.NAME == name then
			fn(env)
		end
	end
end

-- ============================================================================
-- Reload-race hardening
-- ============================================================================
-- A theme switch reloads the config (mode toggles have been reload-free
-- since 2026-09-04); if a popup build's async exec callback was still
-- in flight in the dying process, its sbar.add calls can land on the
-- freshly reloaded bar → orphan rows anchored to dead/replaced items,
-- and the NEXT open collides with them → sketchybar auto-names
-- duplicates (observed live as `item_1` plus a duplicate `battery`
-- row). Two defenses:
--
--   1. OPEN-TIME sweep (LAZY since 2026-09-15: the former load-time
--      exec ran once per controller - a dozen serialized `--query bar |
--      grep` pipes per reload for rows nobody sees until a popup opens;
--      the first open() sweep covers the same reload race):
--      one `sketchybar --query bar | grep` exec discovers any item
--      whose name starts with this controller's row prefix (e.g.
--      "battery.pop."), and each discovered row is removed BY EXACT
--      NAME. Removing an item that provably exists is silent - unlike
--      removing a missing name, which prints
--      `[!] Remove: Item ... not found` to stderr (noise gate).
--   2. anchor liveness: before building, sbar.query(anchor) must return
--      a table - a mode-exclusive anchor (clock in monitor mode) is gone
--      after a reload and the build aborts instead of orphaning rows.

local COLORS = require("colors")
local SETTINGS = require("settings")
local SKETCHYBAR_BIN = "/opt/homebrew/bin/sketchybar"
local TIMEOUT_BIN = "/opt/homebrew/bin/timeout"

local function ere_escape(s)
	return (s:gsub("[%^%$%.%[%]%*%+%?%(%)%%|%\\]", "\\%0"))
end

local function item_exists(name)
	-- type-safe: a real --query returns a decoded table; a missing item
	-- yields nil (or an error, caught by pcall)
	local ok, res = pcall(sbar.query, name)
	return ok and type(res) == "table"
end

--- Create a popup lifecycle controller bound to an anchor item.
--- opts.prefix: row-name prefix for stale-row sweeps (defaults to
--- "<anchor.name>."); bluetooth passes "bt." for its legacy row names.
function M.new(anchor, opts)
	opts = opts or {}
	local row_prefix = opts.prefix or (anchor.name .. ".")

	local ctl = {
		anchor = anchor,
		prefix = row_prefix,
		open_flag = false,
		rows = {}, -- exact names of popup child items WE created
		external = {}, -- externally-owned rows (ctl:track) - hidden, never removed
		epoch = 0, -- bumped on every open/close; stale builds die against it
	}

	-- Pill treatment (CENTRAL - the only correct hook): popup windows draw
	-- their OWN popup->background (popup.c: popup_draw clears/draws it;
	-- defaults are a near-invisible 0x44000000 with no border). Style the
	-- ANCHOR's popup.background once, at controller creation:
	--   anchor:set({ popup = { background = <pill> } })
	-- routes through background_parse_sub_domain (popup.c:475-484) - the
	-- SAME property tree as item backgrounds. BRACKETS CANNOT DO THIS:
	-- group_calculate_bounds runs in the BAR layout loop and collapses
	-- around popup-positioned members (the failed first attempt).
	-- Shape: standard pill, softer 10pt corner. The horizontal padding
	-- keys are accepted but VISUALLY INERT here (popup window bounds
	-- derive from content - background_draw renders bounds as-is, padding
	-- does not inflate them); the visible breathing room comes from b.add
	-- injecting transparent per-row background padding instead. height=26
	-- is harmless: popup_calculate_bounds overwrites bounds from content.
	local popup_bg = pill.background()
	popup_bg.corner_radius = 10
	popup_bg.padding_left = 10
	popup_bg.padding_right = 10
	-- Pill↔popup gap = 8pt, matching the inter-pill island spacing
	-- (popup y_offset is a DOWNWARD shift; default 0 sits ~1pt under the
	-- pill - pixel-measured, 2026-09-04)
	anchor:set({ popup = { background = popup_bg, y_offset = 7 } })

	-- ONE compact exec: lists the anchor + any rows carrying our prefix.
	-- timeout 5 (2026-09-27): a wedged `--query bar` must not stall the
	-- popup open path indefinitely (same exec-hang hardening pass).
	-- Patterns are single-quoted in the shell; they contain only double
	-- quotes + ERE-escaped name dots. grep output = the matched pretty-
	-- JSON lines, e.g. `  "name": "bt.dev.1",`
	local discover_cmd = TIMEOUT_BIN .. " 5 " .. SKETCHYBAR_BIN .. [[ --query bar 2>/dev/null ]]
		.. [[| /usr/bin/grep -E -e ']]
		.. [["name": *"]] .. ere_escape(anchor.name) .. [["' -e ']]
		.. [["name": *"]] .. ere_escape(row_prefix) .. [["']]

	local function sweep_stale(cb)
		sbar.exec(discover_cmd, function(out)
			for name in string.gmatch(out or "", [["name": *"([^"]+)"]]) do
				if name ~= ctl.anchor.name then
					sbar.remove(name) -- just discovered → exists → silent
				end
			end
			if cb then
				cb()
			end
		end)
	end

	-- No load-time sweep_stale() (removed 2026-09-15): it ran once per
	-- controller on every bar load - a dozen serialized `--query bar |
	-- grep` pipes for rows nobody sees until a popup opens. Deferred to
	-- ctl:open() below, whose sweep covers the same reload race.

	local function remove_rows()
		for i = 1, #ctl.rows do
			sbar.remove(ctl.rows[i])
		end
		ctl.rows = {}
	end

	function ctl:is_open()
		return self.open_flag
	end

	function ctl:close()
		if not self.open_flag then
			return
		end
		self.open_flag = false
		self.epoch = self.epoch + 1
		self.anchor:set({ popup = { drawing = false } })
		remove_rows()
	end

	function ctl:open(build)
		if self.open_flag then
			return
		end
		self.open_flag = true
		self.epoch = self.epoch + 1
		local generation = self.epoch

		-- sweep first (async): the build's adds then run collision-free,
		-- so sketchybar can never auto-name a duplicate row
		sweep_stale(function()
			if ctl.epoch ~= generation then
				return -- superseded while sweeping
			end
			-- reload-race guard: anchor gone (e.g. mode-exclusive item
			-- after a mode-toggle reload) → abort, add nothing
			if not item_exists(ctl.anchor.name) then
				ctl.open_flag = false
				ctl.epoch = ctl.epoch + 1
				return
			end

			local b = {}
			function b.add(name, props)
				if ctl.epoch ~= generation then
					return -- superseded (closed/re-opened meanwhile) - drop row
				end
				props = props or {}
				props.position = "popup." .. ctl.anchor.name
				-- Breathing room inside the popup pill: each row's own
				-- (transparent) background padding pads its computed
				-- length, so the popup's drawn background extends past the
				-- text. The popup background itself cannot pad - its bounds
				-- derive from content and background_draw renders as-is.
				if type(props.background) ~= "table" then
					props.background = {}
				end
				if props.background.drawing ~= false then
					props.background.padding_left = props.background.padding_left or 12
					props.background.padding_right = props.background.padding_right or 12
				end
				-- RETURNED: the DSL helpers (b.kv/b.chip) attach click
				-- subscriptions (copy-on-click) to the row handle
				local item = sbar.add("item", name, props)
				ctl.rows[#ctl.rows + 1] = name
				return item
			end
			-- ── Unified row DSL (styling unification 2026-09-04) ──────
			-- Class A (data popups):   header / kv / chip / empty
			-- Class B (action menus):  action / divider
			-- Grammar: muted = keys/glyphs · yellow = percent chips ·
			-- accent = active/selected only · values copy-on-click.
			-- Row names embed ctl.epoch: names must NEVER repeat across
			-- opens - SBarLua subscriptions survive sbar.remove keyed by
			-- name, so a recreated name ACCUMULATES duplicate handlers
			-- (measured: one click → N× handler runs, 2026-09-04).
			-- NOTE: these locals MUST precede b.show - b.show centers the
			-- header over ui_max_w, and a local declared after a function
			-- is invisible to it (Lua upvalue scoping; broke once already).
			local epoch_tag = ctl.epoch
			local ui_seq = 0
			-- widest kv column span; the header label is widened to this at
			-- show-time so align="center" actually centers over the data
			-- (a dynamic-width label centers within ITSELF = renders left)
			local ui_max_w = 0
			local ui_header_item = nil
			local function ui_name(kind)
				ui_seq = ui_seq + 1
				return ctl.prefix .. "ui." .. epoch_tag .. "." .. kind .. "." .. ui_seq
			end

			--- Muted title (data popups). Centered over the kv columns at
			-- show-time (width = widest kv span); with no kv rows it stays
			-- dynamic-width (renders left - nothing to center over).
			function b.header(text)
				ui_header_item = b.add(ui_name("hdr"), {
					icon = { drawing = false },
					label = {
						string = text,
						color = COLORS.muted,
						align = "center",
						font = SETTINGS.font.bold,
					},
				})
			end

			--- Inert rule between row groups.
			function b.divider()
				b.add(ui_name("div"), {
					icon = { drawing = false },
					label = { string = "────────────", color = COLORS.muted },
				})
			end

			--- Muted centered fallback row (uniform empty state - popups
			-- open even with no data; they never refuse).
			function b.empty(text)
				b.add(ui_name("empty"), {
					icon = { drawing = false },
					label = { string = text, color = COLORS.muted, align = "center" },
				})
			end

			--- key:value row; value copies on click (flash "copied").
			-- opts: key_w (default 90), val_w (default 160), value_color
			function b.kv(key, value, opts)
				opts = opts or {}
				local name = ui_name("kv")
				ui_max_w = math.max(ui_max_w, (opts.key_w or 90) + (opts.val_w or 160))
				local item = b.add(name, {
					icon = {
						string = key,
						color = COLORS.muted,
						align = "left",
						width = opts.key_w or 90,
						-- TEXT, not a glyph: the icon slot inherits the
						-- bar's icon font (VictorMono, monospace) unless
						-- overridden - set the label font explicitly
						font = SETTINGS.font.text,
					},
					label = {
						string = value,
						color = opts.value_color or COLORS.fg,
						align = "right",
						width = opts.val_w or 160,
					},
				})
			if opts.copy ~= false and value ~= "" then
				-- "'\\''" is the POSIX \' escape (the old "'\''" collapsed
				-- to "'''" - copy broke on values containing ', leaking the
				-- trailing text to the shell); identical to b.chip below
				local esc = value:gsub("'", "'\\''")
					item:subscribe("mouse.clicked", M.guard(name, function()
						local gen = ctl.epoch -- restore dies with the popup
						sbar.exec("/usr/bin/printf '%s' '" .. esc .. "' | /usr/bin/pbcopy")
						item:set({ label = { string = "copied" } })
						sbar.delay(1.0, function()
							if ctl.epoch == gen and ctl.open_flag then
								item:set({ label = { string = value } })
							end
						end)
					end))
				end
				return item
			end

			--- percent-chip row (disk/cpu): right-aligned yellow chip +
			-- label; label copies on click.
			function b.chip(chip_text, label)
				local name = ui_name("chip")
				local item = b.add(name, {
					icon = {
						string = chip_text,
						color = COLORS.yellow,
						width = 45,
						align = "right",
						font = SETTINGS.font.text,
					},
					label = { string = label, color = COLORS.fg },
				})
				if label ~= "" then
					local esc = label:gsub("'", "'\\''")
					item:subscribe("mouse.clicked", M.guard(name, function()
						local gen = ctl.epoch
						sbar.exec("/usr/bin/printf '%s' '" .. esc .. "' | /usr/bin/pbcopy")
						item:set({ label = { string = "copied" } })
						sbar.delay(1.0, function()
							if ctl.epoch == gen and ctl.open_flag then
								item:set({ label = { string = label } })
							end
						end)
					end))
				end
				return item
			end

			--- action-menu row (Class B): muted glyph + label, click_script
			-- round-trip (color override for destructive/active rows).
			function b.action(icon, label, click_script, opts)
				opts = opts or {}
				b.add(ui_name("act"), {
					icon = {
						string = icon,
						color = opts.color or COLORS.muted,
						-- glyph→text gap, pill convention (icon pr 6)
						padding_left = 0,
						padding_right = 6,
					},
					label = { string = label, color = opts.color or COLORS.fg },
					click_script = click_script,
				})
			end

			function b.show()
				if ctl.epoch ~= generation then
					return
				end
				-- center the header over the kv columns (see ui_max_w)
				if ui_header_item and ui_max_w > 0 then
					ui_header_item:set({ label = { width = ui_max_w } })
				elseif ui_header_item then
					-- action menus have natural-width rows: measure the
					-- popup's content span after layout, then widen the
					-- header to it (deferred - the popup must draw first)
					local gen = ctl.epoch
					sbar.delay(0.15, function()
						if ctl.epoch ~= gen or not ctl.open_flag then
							return
						end
						local min_x, max_x = nil, nil
						for _, r in ipairs(ctl.rows) do
							local ok, res = pcall(sbar.query, r)
							if ok and type(res) == "table" then
								for _, br in pairs(res.bounding_rects or {}) do
									local x0 = br.origin[1]
									local x1 = x0 + br.size[1] -- 1-BASED arrays
									min_x = math.min(min_x or x0, x0)
									max_x = math.max(max_x or x1, x1)
								end
							end
						end
						if min_x and max_x and max_x > min_x then
							ui_header_item:set({ label = { width = max_x - min_x } })
						end
					end)
				end
				ctl.anchor:set({ popup = { drawing = true } })
			end

			build(b)
		end)
	end

	function ctl:toggle(build)
		if self:is_open() then
			self:close()
		else
			self:open(build)
		end
	end

	--- Register an EXTERNALLY-owned popup row (created by the caller -
	--- e.g. tray's permanent detail rows): it joins the popup's pill and
	--- hides with the popup, but close() NEVER removes it - the owning
	--- module manages its lifetime. Call once per row at the row's
	--- creation site.
	function ctl:track(name)
		self.external[#self.external + 1] = name
	end

	--- Guarded mouse.clicked handler that toggles this popup.
	function ctl:clicked(build)
		return M.guard(self.anchor.name, function()
			self:toggle(build)
		end)
	end

	--- Guarded mouse.exited.global handler that closes this popup.
	function ctl:exited()
		return M.guard(self.anchor.name, function()
			self:close()
		end)
	end

	return ctl
end

return M
