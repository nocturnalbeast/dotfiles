-- Environment variables, paths, and computed configuration

local gears = require("gears")
local awful = require("awful")

local vars = {}

-- Paths
vars.config_dir = gears.filesystem.get_configuration_dir()

-- Applications
vars.terminal = "terminal"
vars.scratchpad_cmd = vars.terminal .. " --class scratchpad_term"
vars.browser = os.getenv("BROWSER") or "qutebrowser"
vars.browser_private_opt = os.getenv("BROWSER_PRIVATE_OPT") or ""
vars.file_manager = os.getenv("FILES") or "thunar"
vars.editor = os.getenv("EDITOR") or "nvim"

-- Key configuration
vars.modkey = "Mod4"

-- DPI detection
function vars.dpi(screen)
    local s = screen or awful.screen.focused()
    return s and s.dpi or 96
end

-- Default opacity
vars.opacity_focus = 1.0
vars.opacity_unfocus = 0.95

-- Border behavior
vars.border_width = 2
vars.border_width_maximized = 0
vars.border_width_fullscreen = 0

-- Titlebar / tabbar sizing
vars.titlebar_size = 0
vars.titlebar_floating_size = 28
vars.titlebar_icon_font = "monospace 12"
vars.tabbar_size = 28

-- DWIM movement tuning
vars.floating_move_amount = 20
vars.tiling_resize_factor = 0.05

--- Calculate default gap for a screen.
-- Uses 0.44% of screen width (matching bspwm's gap formula).
-- bspwm gap is total (both sides), awesome gap is per-side, so we halve it.
-- Result is rounded to nearest even number before halving.
function vars.default_gap(screen)
    local geo = screen.geometry
    local raw = math.floor(geo.width * 0.0044 + 0.5) -- 0.44% of screen width
    local gap = raw - (raw % 2)
    return math.floor(gap / 2)
end

return vars
