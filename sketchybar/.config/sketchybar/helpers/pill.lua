-- helpers/pill.lua — single source of truth for the bar's frosted-pill
-- background spec (previously copy-pasted into every items/*.lua).
--
-- Standard pill: frosted bg @ 0.75 alpha, hairline fg border @ 0.08,
-- height 26, corner_radius 6 — the "disconnected module" look (the bar
-- itself is invisible; each item renders its own pill, see init.lua).
--
-- opts (optional table):
--   accent = <color>  accent-tinted pill state (focused workspace,
--                     active caffeine): bg = accent tinted at `tint`
--                     (default 0.18), border = SOLID accent
--   tint   = <alpha>  alpha override for the accent bg tint (0–1)
local colors = require("colors")

local pill = {}

--- Return a fresh pill background table (safe to pass straight into
--- sbar.add(...) creation props or an item:set({ background = ... })).
function pill.background(opts)
	opts = opts or {}
	if opts.accent then
		return {
			color = colors.with_alpha(opts.accent, opts.tint or 0.18),
			border_width = 1,
			border_color = opts.accent,
			height = 26,
			corner_radius = 6,
			drawing = true,
		}
	end
	return {
		color = colors.with_alpha(colors.bg, 0.75),
		border_width = 1,
		border_color = colors.with_alpha(colors.fg, 0.08),
		height = 26,
		corner_radius = 6,
		drawing = true,
	}
end

return pill
