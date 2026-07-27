-- awesome WM configuration

-- Standard awesome libraries
local gears = require("gears")
local awful = require("awful")

local gfs = gears.filesystem
local extlib_dir = gfs.get_configuration_dir() .. "extlib/"

if not gfs.file_readable(extlib_dir .. "bling/module/flash_focus.lua") then
    pcall(os.execute, "git clone --depth 1 https://github.com/BlingCorp/bling.git " .. extlib_dir .. "bling")
end
if not gfs.file_readable(extlib_dir .. "rubato/init.lua") then
    pcall(os.execute, "git clone --depth 1 https://github.com/andOrlando/rubato.git " .. extlib_dir .. "rubato")
end

package.path = package.path .. ";" .. extlib_dir .. "?.lua;" .. extlib_dir .. "?/init.lua"

local permissions = require("awful.permissions")
local permissions_common = require("awful.permissions._common")
permissions_common.set("client", "autoactivate", "switch_tag", true)
permissions_common.set("client", "autoactivate", "history", true)

-- Block _NET_ACTIVE_WINDOW focus stealing from GTK/Qt apps.
-- When a dialog is visible, deny "ewmh" context activation requests for
-- normal windows so the parent can't raise itself above the dialog.
permissions.add_activate_filter(function(c, context, hints)
    if context ~= "ewmh" then
        return nil
    end
    if c.type == "dialog" or c.type == "splash" or c.type == "utility" then
        return nil
    end
    if c.screen then
        for _, other in ipairs(c.screen.all_clients) do
            if
                other ~= c
                and (other.type == "dialog" or other.type == "splash" or other.type == "utility")
                and other.floating
                and other:isvisible()
            then
                return false
            end
        end
    end
    return nil
end, "ewmh")

local beautiful = require("beautiful")
local wibox = require("wibox")
package.loaded["naughty.dbus"] = {}
local naughty = require("naughty")

-- Error logging
local log_file = os.getenv("XDG_CACHE_HOME") or os.getenv("HOME") .. "/.cache"
log_file = log_file .. "/awesome/log"

local log_dir = log_file:match("(.*/)")
pcall(os.execute, "mkdir -p " .. log_dir)

if awesome.startup_errors then
    local f = io.open(log_file, "a")
    if f then
        f:write("\n=== " .. os.date() .. " STARTUP ERRORS ===\n")
        f:write(awesome.startup_errors .. "\n")
        f:close()
    end
end

do
    local in_error = false
    awesome.connect_signal("debug::error", function(err)
        if in_error then
            return
        end
        in_error = true
        pcall(function()
            local f = io.open(log_file, "a")
            if f then
                f:write("\n=== " .. os.date() .. " RUNTIME ERROR ===\n")
                f:write(tostring(err) .. "\n")
                f:close()
            end
        end)
        in_error = false
    end)
end

naughty.connect_signal("request::display_error", function(message, startup)
    naughty.notification({
        urgency = "critical",
        title = "Awesome WM error" .. (startup and " during startup!" or "!"),
        message = message,
    })
end)

-- Load theme
local theme = require("theme")
beautiful.init(theme)

-- bling modules (must load after beautiful.init)
local bling_ok, flash_focus = pcall(require, "bling.module.flash_focus")
if bling_ok and flash_focus then
    flash_focus.enable()
elseif bling_ok then
    naughty.notify({ title = "Awesome WM", text = "bling flash_focus failed to load", timeout = 5 })
else
    naughty.notify({ title = "Awesome WM", text = "bling module not found — check installation", timeout = 5 })
end

-- rubato
local rubato_ok = pcall(require, "rubato")
if not rubato_ok then
    naughty.notify({ title = "Awesome WM", text = "rubato module not found — check installation", timeout = 5 })
end

-- Load tags (workspaces)
require("tags")

local restore_floats = require("modules")

-- Load window rules
require("rules").setup()

-- Load keybindings
local vars = require("vars")
local bindings = require("bindings")
local history = require("history")
bindings.set()

-- Scratchpads (depends on bling + rubato + bindings)
local scratchpads_ok, scratchpads = pcall(require, "scratchpads")
if not scratchpads_ok then
    scratchpads = { toggle = function() end }
    naughty.notify({ title = "Awesome WM", text = "scratchpads module failed to load", timeout = 5 })
end

-- Window switcher (depends on bling)
if bling_ok then
    pcall(function()
        require("bling.widget.window_switcher").enable({
            type = "thumbnail",
            hide_window_switcher_key = "Escape",
            select_client_key = 1,
            minimize_key = "n",
            unminimize_key = "N",
            kill_client_key = "q",
            cycle_key = "Tab",
            previous_key = "Left",
            next_key = "Right",
            vim_previous_key = "h",
            vim_next_key = "l",
            filterClients = awful.widget.tasklist.filter.currenttags,
        })
    end)
end

-- GC tuning for long-running sessions
collectgarbage("setpause", 110)
collectgarbage("setstepmul", 1000)
gears.timer({
    timeout = 5,
    autostart = true,
    callback = function()
        collectgarbage("collect")
    end,
})

require("autostart").run()
require("preflight").check()

local function needs_titlebar(c)
    return c.floating or c.type == "dialog" or c.type == "splash" or c.type == "utility"
end

local function titlebar_btn(c, icon, on_click)
    local btn = wibox.widget.textbox()
    btn.font = beautiful.titlebar_icon_font
    btn.markup = string.format('<span foreground="%s">%s </span>', beautiful.fg_normal, icon)
    btn.buttons = gears.table.join(awful.button({}, 1, on_click))

    btn:connect_signal("mouse::enter", function()
        btn.markup = string.format('<span foreground="%s">%s </span>', beautiful.fg_focus, icon)
    end)
    btn:connect_signal("mouse::leave", function()
        btn.markup = string.format('<span foreground="%s">%s </span>', beautiful.fg_normal, icon)
    end)

    return wibox.container.margin(btn, 6, 6, 0, 0)
end

local function create_titlebar(c)
    if c.type == "dock" then
        return
    end

    local titlebar_buttons = gears.table.join(
        awful.button({}, 1, function()
            client.focus = c
            c:raise()
            awful.mouse.client.move(c)
        end),
        awful.button({ vars.modkey }, 1, function()
            awful.mouse.client.resize(c)
        end)
    )

    local bar = awful.titlebar(c, { size = beautiful.titlebar_floating_size })
    bar:setup({
        nil,
        {
            buttons = titlebar_buttons,
            widget = wibox.container.background,
        },
        {
            titlebar_btn(c, "\u{f2d2}", function()
                awful.client.floating.toggle(c)
            end),
            titlebar_btn(c, "\u{f2d0}", function()
                c.maximized = not c.maximized
                c:raise()
            end),
            titlebar_btn(c, "\u{f00d}", function()
                c:kill()
            end),
            layout = wibox.layout.fixed.horizontal,
        },
        layout = wibox.layout.align.horizontal,
    })

    if not needs_titlebar(c) then
        awful.titlebar.hide(c)
    end
end

client.connect_signal("request::manage", function(c)
    c.keys = bindings.client.get()
    if c.type == "dock" then
        c.border_width = 0
    end
    if not c.icon and beautiful.awesome_icon then
        c.icon = beautiful.awesome_icon
    end

    if awesome.startup and not c.size_hints.user_position and not c.size_hints.program_position then
        awful.placement.no_offscreen(c)
    end

    if needs_titlebar(c) then
        create_titlebar(c)
        if not c.size_hints.user_position and not c.size_hints.program_position then
            awful.placement.centered(c, { honor_padding = true, honor_workarea = true })
        end
    end
end)

client.connect_signal("property::floating", function(c)
    if c.type == "dock" then
        return
    end
    if c.fullscreen then
        return
    end
    if c.floating then
        restore_floats(c)
        c.ontop = true
        c:raise()
        create_titlebar(c)
        awful.titlebar.show(c, beautiful.titlebar_floating_size)
    else
        c.ontop = false
        awful.titlebar.hide(c)
    end
end)

client.connect_signal("property::maximized", function(c)
    c.border_width = c.maximized and vars.border_width_maximized or vars.border_width
end)

client.connect_signal("property::fullscreen", function(c)
    if c.fullscreen then
        c.border_width = vars.border_width_fullscreen
        awful.titlebar.hide(c)
    else
        c.border_width = vars.border_width
        if needs_titlebar(c) then
            awful.titlebar.show(c, beautiful.titlebar_floating_size)
        end
    end
end)

client.connect_signal("unmanage", function(c)
    if c.type == "dock" then
        return
    end
    local s = awful.screen.focused()
    local t = s.selected_tag
    if not t then
        return
    end
    local has_clients = false
    for _, cl in ipairs(t:clients()) do
        if cl ~= c then
            has_clients = true
            break
        end
    end
    if not has_clients then
        if not history.pop_to_nonempty(s) then
            s.tags[1]:view_only()
        end
    end
end)

client.connect_signal("request::geometry", function(c, context)
    if c.maximized and context == "ewmh" then
        return
    end
end)
