local xresources = require("beautiful.xresources")
local theme_assets = require("beautiful.theme_assets")
local dpi = xresources.apply_dpi

local vars = require("vars")

local ok, prism = pcall(require, "prismtheme")
local xrdb = xresources.get_current_theme()

local function color(key, fallback)
    if ok and prism[key] then
        return prism[key]
    end
    return xrdb[key] or fallback
end

local theme = {}

theme.bg_normal = color("background", "#1a1a1a")
theme.bg_focus = color("color8", "#333333")
theme.bg_urgent = color("color9", "#cc6666")
theme.fg_normal = color("foreground", "#aaaaaa")
theme.fg_focus = color("color15", "#ffffff")
theme.fg_urgent = color("color1", "#ffffff")

theme.border_width = (ok and prism.border_width) or vars.border_width
theme.border_color_normal = color("color0", "#aaaaaa")
theme.border_color_active = color("color8", "#1a1a1a")
theme.border_color_urgent = color("color1", "#cc6666")

theme.border_color_floating_active = theme.border_color_active
theme.border_color_floating_normal = theme.border_color_normal
theme.border_color_floating_urgent = theme.border_color_urgent

theme.border_color_maximized_active = "#000000"
theme.border_color_maximized_normal = "#000000"
theme.border_color_maximized_urgent = "#000000"

theme.border_color_fullscreen_active = "#000000"
theme.border_color_fullscreen_normal = "#000000"
theme.border_color_fullscreen_urgent = "#000000"

theme.font = (ok and prism.font) or "sans 8"

theme.titlebar_size = vars.titlebar_size
theme.titlebar_floating_size = vars.titlebar_floating_size
theme.titlebar_icon_font = vars.titlebar_icon_font
theme.titlebar_bg_normal = theme.bg_normal
theme.titlebar_bg_focus = theme.bg_focus
theme.titlebar_fg_normal = theme.fg_normal
theme.titlebar_fg_focus = theme.fg_focus

theme.tabbar_style = "default"
theme.tabbar_bg_normal = theme.bg_normal
theme.tabbar_fg_normal = theme.fg_normal
theme.tabbar_bg_focus = theme.bg_focus
theme.tabbar_fg_focus = theme.fg_focus
theme.tabbar_size = vars.tabbar_size
theme.tabbar_font = "sans 8"

theme.window_switcher_widget_bg = theme.bg_normal
theme.window_switcher_widget_border_width = dpi(2)
theme.window_switcher_widget_border_color = theme.fg_normal
theme.window_switcher_client_width = dpi(150)
theme.window_switcher_client_height = dpi(250)
theme.window_switcher_name_font = "sans 11"
theme.window_switcher_name_normal_color = theme.fg_normal
theme.window_switcher_name_focus_color = theme.fg_focus

theme.flash_focus_start_opacity = 0.6
theme.flash_focus_step = 0.01

theme = theme_assets.recolor_layout(theme, theme.fg_normal)

theme.taglist_squares_sel = theme_assets.taglist_squares_sel(dpi(4), theme.fg_focus)
theme.taglist_squares_unsel = theme_assets.taglist_squares_unsel(dpi(4), theme.fg_normal)

theme.awesome_icon = theme_assets.awesome_icon(dpi(16), theme.bg_focus, theme.fg_focus)

return theme
