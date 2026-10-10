-- Global settings: fonts, paddings, intervals, paths.
return {
	font = {
		-- "SF Pro:Text:..." silently resolves to HELVETICA (family is
		-- "SF Pro Text", style "Text" doesn't exist under "SF Pro") -
		-- Helvetica rides ~1pt high, making centered icons LOOK low.
		text = "SF Pro Text:Regular:14.0", -- bar label text
		bold = "SF Pro Text:Bold:14.0", -- popup headers (b.header)
		numbers = "SF Pro Text:Regular:14.0", -- numeric readouts
		icons = "VictorMono Nerd Font:Regular:16.0", -- the ONE icon font: generic glyphs AND app icons (helpers/icons.lua NF map)
	},
	-- font FAMILIES (no :size suffix) for sub-14pt surfaces (wifi chips)
	font_family = {
		text = "SF Pro Text",
		numbers = "SF Pro Text",
		icons = "VictorMono Nerd Font",
	},

	paddings = 3, -- inter-item gaps (disconnected-pill look: islands, not a strip) - each pill carries this on both sides → 6px visual gap

	-- click/binding mode toggle machinery (helpers/mode.lua)
	MODE_FILE = os.getenv("HOME") .. "/.cache/sketchybar/mode",

	-- weather wing (plan §4a)
	intervals = {
		geoip = 86400, -- 1×/day, cached in ~/.cache/sketchybar/geo.json
		weather = 900, -- 15min
	},

	weather = {
		unit = "c", -- temperature unit: "c" (°C) or "f" (°F) - open-meteo request + display suffix
	},
}
