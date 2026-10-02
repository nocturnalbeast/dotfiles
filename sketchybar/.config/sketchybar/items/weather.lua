-- items/weather.lua — IP-geolocated weather (plan §4a).
--   * geoip: ipinfo.io → ~/.cache/sketchybar/geo.json with embedded
--     `fetched` timestamp; refreshed only when >24h old (travel-safe)
--   * weather: open-meteo `current=temperature_2m,weather_code`
--     (LONG param names latitude=/longitude= — P1-5)
--   * both curls piped through jq to COMPACT output (raw open-meteo JSON
--     ~400B flirts with the sbar.exec output-transport limit)
--   * WMO code → Nerd Font glyph; failure → dim "—", never crash
-- 15min poll.
local colors = require("colors")
local settings = require("settings")
local pill = require("helpers.pill")
local popup = require("helpers.popup")
local hover = require("helpers.hover")
local mode = require("helpers.mode")

local CURL = "/usr/bin/curl"

-- jq portability: pick the first existing of the known absolute paths
-- (one-time io.open probe at module load). If none exist, keep the stock
-- path — the pipe then yields empty output and the pill degrades to the
-- dim "—" exactly as before.
local JQ = "/usr/bin/jq"
for _, candidate in ipairs({ "/usr/bin/jq", "/opt/homebrew/bin/jq", "/usr/local/bin/jq" }) do
	local probe = io.open(candidate, "r")
	if probe then
		probe:close()
		JQ = candidate
		break
	end
end

-- Temperature unit (settings.weather.unit): "c" default, "f" optional.
-- Drives the open-meteo temperature_unit param and the °C/°F suffix.
local UNIT_FAHRENHEIT = (settings.weather and settings.weather.unit) == "f"
local UNIT_PARAM = UNIT_FAHRENHEIT and "&temperature_unit=fahrenheit" or ""
local UNIT_SUFFIX = UNIT_FAHRENHEIT and "°F" or "°C"

local CACHE_DIR = os.getenv("HOME") .. "/.cache/sketchybar"
local CACHE = CACHE_DIR .. "/geo.json"

os.execute('/bin/mkdir -p "' .. CACHE_DIR .. '"')

local ICON_UNKNOWN = "󰖕"

-- ============================================================================
-- WMO weather_code → glyph + description
-- ============================================================================
local function wmo_glyph(code)
	if code == 0 then
		return "󰖔" -- clear
	elseif code == 1 or code == 2 then
		return "󰖅" -- mostly clear / partly cloudy
	elseif code == 3 then
		return "󰖕" -- overcast
	elseif code == 45 or code == 48 then
		return "󰖑" -- fog
	elseif (code >= 51 and code <= 57) or (code >= 61 and code <= 67) or (code >= 80 and code <= 82) then
		return "󰖖" -- drizzle / rain / showers
	elseif (code >= 71 and code <= 77) or code == 85 or code == 86 then
		return "󰖜" -- snow
	elseif code >= 95 then
		return "󰖝" -- thunderstorm
	end
	return ICON_UNKNOWN
end

local function wmo_desc(code)
	if code == 0 then
		return "Clear"
	elseif code == 1 then
		return "Mostly clear"
	elseif code == 2 then
		return "Partly cloudy"
	elseif code == 3 then
		return "Overcast"
	elseif code == 45 or code == 48 then
		return "Fog"
	elseif code >= 51 and code <= 57 then
		return "Drizzle"
	elseif code >= 61 and code <= 67 then
		return "Rain"
	elseif code >= 80 and code <= 82 then
		return "Showers"
	elseif code >= 71 and code <= 77 or code == 85 or code == 86 then
		return "Snow"
	elseif code >= 95 then
		return "Thunderstorm"
	end
	return "Unknown"
end

-- ============================================================================
-- Item (monitor-exclusive: born hidden + updates off in main mode —
-- reload-free swap via mode_changed, see AGENT.md facts 16–18)
-- ============================================================================
local visible = mode.get() == "monitor"

local weather = sbar.add("item", "weather", {
	position = "right",
	drawing = visible and "on" or "off",
	updates = visible,
	icon = {
		string = ICON_UNKNOWN,
		color = colors.muted,
		padding_left = 8,
		-- +1: NF glyph ink sits ~1.7pt low in its em-box
		-- (pixel-measured); nudge up to meet the text baseline
		y_offset = 1,
		padding_right = 6,
	},
	label = {
		string = "—",
		font = settings.font.numbers,
		color = colors.muted,
		padding_right = 8,
	},
	background = pill.background(),
	padding_left = settings.paddings,
	padding_right = settings.paddings,
	popup = { align = "center" },
})

local cache_state = { city = "", loc = "", temp = nil, code = nil }

local function render_dim()
	weather:set({
		icon = { string = ICON_UNKNOWN, color = colors.muted },
		label = { string = "—", color = colors.muted },
	})
end

-- ============================================================================
-- Geoip cache ({"loc":"lat,lon","city":"…","fetched":<unix-ts>})
-- ============================================================================

local function read_cache()
	local f = io.open(CACHE, "r")
	if not f then
		return nil
	end
	local content = f:read("*a") or ""
	f:close()
	return {
		loc = content:match('"loc"%s*:%s*"([^"]+)"'),
		city = content:match('"city"%s*:%s*"([^"]+)"'),
		fetched = tonumber(content:match('"fetched"%s*:%s*(%d+)')),
	}
end

local function write_cache(loc, city)
	-- sanitize: no quotes/backslashes/control chars in the JSON we emit
	loc = loc:gsub('[%"\\%c]', "")
	city = city:gsub('[%"\\%c]', "")
	local tmp = CACHE .. ".tmp"
	local w = io.open(tmp, "w")
	if not w then
		return
	end
	w:write(string.format('{"loc":"%s","city":"%s","fetched":%d}', loc, city, os.time()))
	w:close()
	os.rename(tmp, CACHE)
end

local function ensure_geo(cb)
	local c = read_cache()
	if c and c.loc and c.fetched and (os.time() - c.fetched) < settings.intervals.geoip then
		cb(c.loc, c.city or "")
		return
	end
	sbar.exec(CURL .. " -s --max-time 5 https://ipinfo.io/json 2>/dev/null | " .. JQ .. [[ -r '[.loc, .city] | @tsv' 2>/dev/null]], function(out)
		local o = (out or ""):gsub("^%s+", ""):gsub("%s+$", "")
		local new_loc = o:match("^(%-?%d+%.%d+,%-?%d+%.%d+)")
		if new_loc then
			local new_city = o:match("\t(.+)$") or ""
			write_cache(new_loc, new_city)
			cb(new_loc, new_city)
		elseif c and c.loc then
			cb(c.loc, c.city or "") -- stale cache beats nothing
		else
			cb(nil, nil)
		end
	end)
end

-- ============================================================================
-- Weather fetch + render
-- ============================================================================

local function fetch_weather()
	ensure_geo(function(loc, city)
		cache_state.loc = loc or ""
		cache_state.city = city or ""
		if not loc then
			render_dim()
			return
		end
		local lat = loc:match("^([^,]+)")
		local lon = loc:match(",([^,]+)$")
		sbar.exec(
			CURL .. " -s --max-time 10 'https://api.open-meteo.com/v1/forecast?latitude=" .. lat
				.. "&longitude=" .. lon .. "&current=temperature_2m,weather_code" .. UNIT_PARAM .. "' 2>/dev/null | " .. JQ
				.. [[ -c '.current | {t: .temperature_2m, c: .weather_code}' 2>/dev/null]],
			function(out)
				-- SBarLua auto-decodes JSON exec output into a Lua TABLE
				-- (verified live: this callback receives a table, while
				-- plain-text commands receive strings).
				local t, code
				if type(out) == "table" then
					t = tonumber(out.t)
					code = tonumber(out.c)
				else
					local o = out or ""
					t = tonumber(o:match('"t"%s*:%s*([%-%d%.]+)'))
					code = tonumber(o:match('"c"%s*:%s*(%d+)'))
				end
				if not t or not code then
					render_dim()
					return
				end
				cache_state.temp = math.floor(t + 0.5)
				cache_state.code = code
				weather:set({
					icon = { string = wmo_glyph(code), color = colors.fg },
					label = { string = cache_state.temp .. UNIT_SUFFIX, color = colors.fg },
				})
			end
		)
	end)
end

-- ============================================================================
-- Click popup: location details (from cache — no fetch on the click path;
-- helpers/popup lifecycle, rows tracked + removed on close)
-- ============================================================================

local ctl = popup.new(weather)

local function build_popup(b)
	b.header("Weather")
	b.kv("Location:", cache_state.city ~= "" and cache_state.city or cache_state.loc)
	if cache_state.temp then
		b.kv("Now:", cache_state.temp .. UNIT_SUFFIX .. " · " .. wmo_desc(cache_state.code or 3))
	end
	b.show()
end

weather:subscribe("mouse.clicked", ctl:clicked(build_popup))

-- Hover append — condition text from the cached weather_code (no
-- feels-like: the existing fetch doesn't request apparent_temperature,
-- and hover must not add execs — see AGENT.md hover convention)
local hov = hover.new(weather, function()
	return cache_state.code ~= nil and wmo_desc(cache_state.code) or ""
end, { base = function()
	return cache_state.temp ~= nil and (cache_state.temp .. UNIT_SUFFIX) or "—"
end, no_global_exit = true })

-- merged exited.global: popup close + hover collapse (hover.lua note)
weather:subscribe("mouse.exited.global", popup.guard(weather.name, function()
	ctl:close()
	hov.collapse()
end))

-- Refetch on wake (pill would otherwise sit stale after a long sleep
-- until the next 15min tick) — same pattern as battery.lua. Hidden in
-- main mode, updates=false stops the server-side dispatch (fact 16).
weather:subscribe({ "system_woke", "forced" }, fetch_weather)

-- ============================================================================
-- Mode gating: the 15min poll is a Lua sbar.delay chain — updates=false
-- does NOT stop it (fact 16), so gate it with a `polling` flag. apply_mode
-- flips drawing/updates, kills/restarts the chain, closes the popup.
-- ============================================================================

local polling = false

local function tick()
	if not polling then
		return
	end
	fetch_weather()
	sbar.delay(settings.intervals.weather, tick)
end

local function apply_mode()
	local show = mode.get() == "monitor"
	if show and not polling then
		polling = true
		tick()
	elseif not show then
		polling = false
		ctl:close()
	end
	weather:set({ drawing = show and "on" or "off", updates = show })
end

mode.on_change(apply_mode)

-- Initial fetch + poll (only when born visible)
if visible then
	polling = true
	tick()
end
