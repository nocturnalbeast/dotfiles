-- items/media.lua — now-playing pill (right wing — this display has a
-- notch covering center).
--
-- Source: /opt/homebrew/bin/media-control (macOS 26 MediaRemote shim —
-- supersedes nowplaying-cli, whose `get playback_state` was broken (fact 7)
-- which is why paused-dimming never worked; media-control's `playing` /
-- `playbackRate` DO work).
--
-- Update paths (belt and suspenders — AGENT.md "Hammerspoon event bridge"
-- + reload-semantics contract):
--   * PUSH: plugins/media_control_reader (spawned detached below, the
--     network_load idiom) reads `media-control stream` and fires
--     `media_update` per change. Stream lines are PARTIAL diffs
--     (`{"diff":true,"payload":{"playing":true}}`), so ABSENT env vars
--     mean "unchanged" — only present vars update the cache. A BARE
--     media_update (no vars) is a ping → full `get` re-query.
--   * POLL: ≥30s fallback via jq-narrowed `media-control get` (raw get is
--     ~309B — over the ~300B exec budget, facts 3/15) so the pill stays
--     correct if the reader dies.
--
-- `get` output is JSON → SBarLua auto-decodes (fact 4). Idle = empty
-- title, or the Firefox pseudo-title ("Firefox is playing media" + empty
-- artist + org.mozilla.firefox + playing=false) → whole cluster
-- drawing=off (the old nowplaying-cli "null" UX, preserved).
--
-- Rendering: ONE pill (bracket) around an icon item + title/artist
-- STACKED (the wifi-counter pattern): two width=0 chips anchored at the
-- same right edge (adjacent zero-width slots coincide), y_offset ±6,
-- small text — title on top (bright; dim-when-paused wired via
-- media-control `playing`), artist below (muted). The bracket draws the
-- ONE pill surface; the icon item carries the play state color.
local colors = require("colors")
local settings = require("settings")
local pill = require("helpers.pill")
local popup = require("helpers.popup")
local mode = require("helpers.mode")

local MEDIA_CONTROL = "/opt/homebrew/bin/media-control"
local CONFIG_DIR = os.getenv("HOME") .. "/.config/sketchybar"

local POLL_INTERVAL = 30 -- slow fallback (push events are the primary driver)

-- Scrolling text: NATIVE item-level `scroll_texts` on a FIXED-width,
-- right-aligned label box. The daemon animates a sub-pixel text offset
-- (text.c: CTLineDraw at bounds.x - text->scroll) re-kicked by its 1s
-- refresh clock — smooth, CoreText-correct for UTF-8 (a Lua byte-sub
-- marquee corrupted multi-byte chars). Fixed label boxes of EQUAL width
-- keep the zero-width-slot stack coincident (verified on the wifi chips).
-- Pause freezes: scroll_texts toggled off in apply().
local TITLE_BOX = 140 -- pt, fixed scroll window (9pt font ≈ 28 chars)
local ARTIST_BOX = 96 -- pt (8pt font ≈ 22 chars)
-- Below these CHAR counts the chip hugs its text instead (dynamic width,
-- no scroll) — short tracks shrink the pill; long ones scroll in place.
local TITLE_HUG_AT = 24
local ARTIST_HUG_AT = 20

local PSEUDO_TITLE = "Firefox is playing media"
local FIREFOX_BUNDLE = "org.mozilla.firefox"

-- Main-exclusive cluster (reload-free mode swap via mode_changed — AGENT.md
-- facts 16–18). Note the interplay with the idle-hidden drawing cache
-- below: the mode gate WINS — set_drawing forces off while hidden, and
-- apply_mode restores cache.drawing on re-show.
local visible = mode.get() == "main"

-- Item creation order: right-side items render REVERSE of add order, so
-- media.main (icon) is added LAST → renders LEFTMOST of the cluster.
-- Visual: [󰝚] [title / artist stacked] — title & artist are width=0
-- chips whose adjacent zero-width slots coincide at one x; their labels
-- right-align to it (each padding_right from the shared anchor), giving
-- the vertical stack (wifi.up/wifi.down mechanics, AGENT.md fact 2).
local media_title = sbar.add("item", "media.title", {
	position = "right",
	drawing = "off",
	updates = visible,
	width = 0,
	scroll_texts = "on", -- daemon-side smooth scroll in the fixed box
	icon = { drawing = false },
	label = {
		string = "",
		font = { family = settings.font_family.text, size = 9.0 },
		color = colors.fg,
		-- FIXED scroll window + right align: the box pins to the anchor
		-- (equal padding_right across chips); text right-aligns inside,
		-- long text scrolls. Equal fixed boxes keep the stack coincident.
		width = TITLE_BOX,
		align = "right",
		padding_right = 6,
	},
	y_offset = 6,
	background = { drawing = false }, -- ONE pill: the bracket draws it
	-- RIGHT edge of the cluster (chips share the anchor; equal padding on
	-- both keeps the stack coincident) — 2 = matches media.title (was 6:
	-- right inner read 12 vs the 8pt module convention)
	padding_left = 0,
	padding_right = 2,
})

local media_artist = sbar.add("item", "media.artist", {
	position = "right",
	drawing = "off",
	updates = visible,
	width = 0,
	scroll_texts = "on",
	icon = { drawing = false },
	label = {
		string = "",
		font = { family = settings.font_family.text, size = 8.0 },
		color = colors.muted,
		width = ARTIST_BOX,
		align = "right",
		padding_right = 6, -- equal to media.title — same right edge
	},
	y_offset = -6,
	background = { drawing = false },
	padding_left = 0,
	padding_right = 2, -- MUST equal media.title — the shared right anchor
	-- (a drift here skews the stack; regression 2026-08-27). 2 (not 6):
	-- right inner was 12 (label.pr 6 + this 6), now 8 — and the −4
	-- offsets the icon.pr +4 slot shift, keeping the vol gap at 8pt
})

local media = sbar.add("item", "media.main", {
	position = "right",
	drawing = "off",
	updates = visible,
	icon = {
		string = "󰝚",
		color = colors.muted,
		padding_left = 8,
		padding_right = 3, -- icon-text gap (visual ≈2× config through the
		-- band retune: 2→5.5, 5→12.5; 3 targets the ~8pt module rhythm)
		y_offset = 1, -- NF ink ~1.7pt low (see battery.lua note)
	},
	-- RESERVED BAND for the stacked chips (wifi-head pattern): the chips
	-- are width=0 overlays whose ink overflows LEFTWARD from their slots
	-- (right of this one) — without a reserve it draws across the icon.
	-- Empty-string label + padding: only the padding occupies the slot.
	-- Band is RETUNED dynamically (retune_band below) to hug the wider
	-- chip per track. Add-time 70 = safe floor until first retune.
	label = {
		string = "",
		font = settings.font.text,
		color = colors.fg,
		padding_right = 70,
	},
	-- LEFT edge of the cluster (icon item renders leftmost): 5 =
	-- pixel-calibrated for the standard 8pt visual inter-pill gap
	padding_left = 0, -- 7 was junk from the 8pt-gap calibration (inert for
	-- bracket bg edges but DOUBLE-counted here as left inner: 7+8=15)
})

-- One frosted pill wrapping icon + stacked chips (explicit name: unnamed
-- brackets get daemon auto-names like "item_1", which read as bugs)
local media_bracket = sbar.add("bracket", "media.bracket",
	{ media.name, media_title.name, media_artist.name }, {
		drawing = "off",
		background = pill.background(),
		padding_left = 0,
		padding_right = 0,
		-- NO bracket paddings (they EXTEND the bg and cancel the members'
		-- island-gap item paddings — see wifi.bracket note)
	})

-- ============================================================================
-- Reader spawn (plugins/network_load idiom: detached nohup + redirects,
-- survives reloads; the script's own pgrep guard keeps it single-instance)
-- ============================================================================

sbar.exec("nohup " .. CONFIG_DIR .. "/plugins/media_control_reader >/dev/null 2>&1 &")

-- ============================================================================
-- State
-- ============================================================================

local cache = { drawing = false, title = "", artist = "", playing = false, bundle = "" }
local polling = false

local function trim(s)
	return (s or ""):gsub("^%s+", ""):gsub("%s+$", "")
end

local function set_drawing(on)
	if not visible then
		on = false -- mode gate wins: never draw in monitor mode
	end
	if cache.drawing == on then
		return
	end
	cache.drawing = on
	local state = on and "on" or "off"
	media:set({ drawing = state })
	media_title:set({ drawing = state })
	media_artist:set({ drawing = state })
	media_bracket:set({ drawing = state })
end

local function is_idle()
	if cache.title == "" or cache.title == "null" then
		return true
	end
	-- Firefox pseudo-title with nothing actually playing = idle noise
	return cache.title == PSEUDO_TITLE
		and cache.artist == ""
		and cache.bundle == FIREFOX_BUNDLE
		and not cache.playing
end

-- ============================================================================
-- DYNAMIC reserved band (tray.lua retune_band pattern): size the icon
-- item's label padding to hug the wider chip + gutter. One-directional
-- (chip text → chip rect → icon-item padding); quantized + hysteresis so
-- per-track changes don't churn. SBarLua JSON arrays are 1-BASED:
-- rect.size[1] = width (tray.lua bug note).
-- ============================================================================

-- Deterministic-ish: the gutter biases the icon→text gap 1:1 through
-- the hug (gutter 2 → gap 10.5 with icon.pr 3; 0 → 7.5, matching the
-- module rhythm — re-measured 2026-09-04 after the inner-padding rework)
-- lands ≈6pt.
local BAND_GUTTER = 0
-- MAX must cover the widest chip at max_chars: a 28-char 9pt title runs
-- ~140pt — a 130 clamp made long-title tracks overflow the band and
-- collide with the icon (observed live). 170 gives headroom.
local BAND_MIN, BAND_MAX = 40, 170
local QUANTUM = 2
local band_current = 70 -- add-time floor; tracked for hysteresis

local function retune_band()
	local function absorb(q, widest)
		for _, r in pairs((q or {}).bounding_rects or {}) do
			local w = r and r.size and (r.size[1] or r.size[2]) or 0
			if w > widest then
				widest = w
			end
		end
		return widest
	end
	local ok_t, qt = pcall(function()
		return media_title:query()
	end)
	local ok_a, qa = pcall(function()
		return media_artist:query()
	end)
	local widest = 0
	if ok_t then
		widest = absorb(qt, widest)
	end
	if ok_a then
		widest = absorb(qa, widest)
	end
	if widest <= 0 then
		return -- no rects yet — keep current band
	end
	local desired = math.ceil((widest + BAND_GUTTER) / QUANTUM) * QUANTUM
	desired = math.min(BAND_MAX, math.max(BAND_MIN, desired))
	if math.abs(desired - band_current) < QUANTUM then
		return -- within hysteresis — no churn
	end
	band_current = desired
	media:set({ label = { padding_right = desired } })
end

local function apply()
	-- Dim-when-paused (media-control `playing`); pause ALSO freezes the
	-- native scroll (scroll_texts off — the running pass finishes, no
	-- re-kick until playback resumes)
	local dim = not cache.playing
	set_drawing(true)

	local scroll = not dim and "on" or "off"
	media:set({
		icon = { color = dim and colors.muted or colors.accent },
	})

	-- ADAPTIVE chips: short text → dynamic width (pill hugs it); long
	-- text → fixed box + native scroll. The trailing padding_right is
	-- EQUAL on both chips so their right edges stay coincident in both
	-- modes (the stack's shared anchor).
	if #cache.title > TITLE_HUG_AT then
		media_title:set({
			label = { string = cache.title, width = TITLE_BOX, align = "right",
				color = dim and colors.muted or colors.bright },
			scroll_texts = scroll,
		})
	else
		media_title:set({
			label = { string = cache.title, width = "dynamic",
				color = dim and colors.muted or colors.bright },
			scroll_texts = "off",
		})
	end
	if #cache.artist > ARTIST_HUG_AT then
		media_artist:set({
			label = { string = cache.artist, width = ARTIST_BOX, align = "right",
				color = colors.muted },
			scroll_texts = scroll,
		})
	else
		media_artist:set({
			label = { string = cache.artist, width = "dynamic",
				color = colors.muted },
			scroll_texts = "off",
		})
	end

	-- after the daemon lays out the new chip texts, re-measure and
	-- re-size the icon item's reserved band (0.1s settle; tray.lua
	-- retune_band pattern — rects are content-sized in hug mode, so the
	-- band hugs too; in scroll mode it stabilizes at box+gutter)
	sbar.delay(0.1, retune_band)
end

-- ============================================================================
-- Fallback poll — jq-narrowed `get` (stays well under the ~300B budget;
-- raw get is ~309B and grows with long titles). Decodes to a table
-- {title, artist, playing, bundle} (fact 4). Non-table output (reader/CLI
-- hiccup) keeps the last known state — no flicker on transient failure.
-- ============================================================================

local GET_CMD = MEDIA_CONTROL
	.. [[ get 2>/dev/null ]]
	.. [[| /usr/bin/jq -c '{title:(.title//""),artist:(.artist//""),playing:(.playing//false),bundle:(.bundleIdentifier//"")}']]
	.. [[ 2>/dev/null | /usr/bin/head -c 250]]

local function refresh()
	sbar.exec(GET_CMD, function(out)
		if type(out) ~= "table" then
			return
		end
		local title = trim(tostring(out.title or ""))
		local artist = trim(tostring(out.artist or ""))
		local playing = out.playing == true
		local bundle = tostring(out.bundle or "")
		-- change-detection cache: only touch the bar when something
		-- actually changed (no label churn on the periodic poll)
		local changed = title ~= cache.title or artist ~= cache.artist
			or playing ~= cache.playing or bundle ~= cache.bundle
		cache.title = title
		cache.artist = artist
		cache.playing = playing
		cache.bundle = bundle
		if is_idle() then
			set_drawing(false)
			return
		end
		if changed then
			apply()
		end
	end)
end

-- ============================================================================
-- Push path — media_update from plugins/media_control_reader. Absent vars
-- = "field unchanged" (stream partial diffs); bare trigger (no vars) =
-- ping → full re-query (wake/unlock burst via init.lua lock.observer).
-- ============================================================================

media:subscribe("media_update", function(env)
	if env.RESET == "1" then
		-- full-state line from the reader: absent fields are EXPLICITLY
		-- empty (artist-less track) — clear before applying present vars.
		-- (The transport drops empty-valued env vars, so the reader sends
		-- RESET=1 instead of ARTIST= etc. — see plugins/media_control_reader)
		cache.title = ""
		cache.artist = ""
		cache.bundle = ""
	end
	if env.TITLE == nil and env.ARTIST == nil and env.PLAYING == nil and env.BUNDLE == nil then
		refresh()
		return
	end
	if env.TITLE ~= nil then
		cache.title = trim(env.TITLE)
	end
	if env.ARTIST ~= nil then
		cache.artist = trim(env.ARTIST)
	end
	if env.PLAYING ~= nil then
		cache.playing = env.PLAYING == "1"
	end
	if env.BUNDLE ~= nil then
		cache.bundle = env.BUNDLE
	end
	-- playing with no known title = anomalous partial state (e.g.
	-- resume-from-nothing diff) — resolve with a full re-query rather
	-- than hiding while audio plays
	if cache.playing and cache.title == "" then
		refresh()
		return
	end
	if is_idle() then
		set_drawing(false)
		return
	end
	apply()
end)

-- Wake/lock resync: system_woke (real wake via the HS bridge, or the
-- unlock burst from init.lua's lock.observer) re-queries media state.
-- Separate always-on observer — the media items themselves are
-- updates-gated in monitor mode (fact 17: mode.relay / aerospace.observer
-- idiom; refresh itself gated by `polling` so hidden mode runs no execs).
local sync = sbar.add("item", "media.sync", { drawing = "off", updates = true })
sync:subscribe("system_woke", function()
	if polling then
		refresh()
	end
end)

-- Click anywhere on the cluster = play/pause (NAME-guarded: the click
-- broadcast reaches BOTH subscriptions — each must filter for itself).
-- The stream reader pushes the state change; the 0.3s re-read is
-- belt-and-suspenders for reader death.
local function toggle()
	sbar.exec(MEDIA_CONTROL .. " toggle-play-pause", function()
		sbar.delay(0.3, refresh)
	end)
end

-- RIGHT-click: reveal the player the media is reading from (cache.bundle
-- is the now-playing source's bundle id); LEFT-click: play/pause toggle.
local function click_dispatch(env)
	if env.BUTTON == "right" then
		if cache.bundle ~= "" then
			sbar.exec("/usr/bin/open -b " .. cache.bundle)
		end
		return
	end
	toggle()
end

media:subscribe("mouse.clicked", popup.guard(media.name, click_dispatch))
media_title:subscribe("mouse.clicked", popup.guard(media_title.name, click_dispatch))
media_artist:subscribe("mouse.clicked", popup.guard(media_artist.name, click_dispatch))

-- ============================================================================
-- Mode gating (Lua poll chain gated by `polling` — fact 16). Drawing is
-- restored to cache.drawing on re-show: hidden-by-mode does not count as
-- idle, playback continues while the pill is away.
-- ============================================================================

local function poll()
	if not polling then
		return
	end
	refresh()
	sbar.delay(POLL_INTERVAL, poll)
end

local function apply_mode()
	local show = mode.get() == "main"
	visible = show
	if show and not polling then
		polling = true
		poll()
	elseif not show then
		polling = false
	end
	-- re-assert drawing under the new gate (mode gate wins when hidden)
	local state = (show and cache.drawing) and "on" or "off"
	media:set({ drawing = state, updates = show })
	media_title:set({ drawing = state, updates = show })
	media_artist:set({ drawing = state, updates = show })
	media_bracket:set({ drawing = state })
end

mode.on_change(apply_mode)

-- Initial poll at load (only when born visible)
if visible then
	polling = true
	poll()
end
