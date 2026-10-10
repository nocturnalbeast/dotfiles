-- Semantic color layer - the ONLY place Material role → meaning lives.
-- pcall pattern: try the generated Material palette first; if
-- colors_generated.lua is missing (fresh boot before first `theme` run)
-- fall back to a hardcoded Material-dark baseline so init.lua never crashes.
local ok, gen = pcall(require, "colors_generated")
if not ok or type(gen) ~= "table" or gen.primary == nil then
	gen = {
		-- Material-dark baseline fallback (neutral blue source)
		surface = 0xff111318,
		surface_container_high = 0xff282A2F,
		outline = 0xff8E9099,
		outline_variant = 0xff44474F,
		primary = 0xffADC6FF,
		on_surface_variant = 0xffC4C6D0,
		on_surface = 0xffE2E2E9,
		red = 0xffFFB2BB,
		yellow = 0xffB9CF84,
		tertiary_container = 0xff583E5B,
		green = 0xff95D5A8,
		cyan = 0xff82D3E2,
	}
end

local with_alpha = function(color, alpha)
	if alpha > 1.0 or alpha < 0.0 then
		return color
	end
	return (color & 0x00ffffff) | (math.floor(alpha * 255.0) << 24)
end

return {
	-- semantic mapping (GUI world: Material roles, not base16)
	bg = gen.surface,
	surface = gen.surface_container_high,
	muted = gen.outline,
	accent = gen.primary,
	fg = gen.on_surface_variant,
	bright = gen.on_surface,
	red = gen.red,
	yellow = gen.yellow,
	green = gen.green,
	cyan = gen.teal,
	magenta = gen.tertiary_container,
	inactive = gen.outline_variant,

	transparent = 0x00000000,
	with_alpha = with_alpha,
}
