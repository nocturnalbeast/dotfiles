local gears = require("gears")
local awful = require("awful")
local vars = require("vars")
local history = require("history")
local layouts = require("layouts")

local _M = {}

local function focus_dir(dir)
    awful.client.focus.global_bydirection(dir)
    if client.focus then
        client.focus:raise()
    end
end

local function with_focused(fn)
    return function()
        if client.focus then
            fn(client.focus)
        end
    end
end

function _M.get()
    return gears.table.join(

        awful.key({
            modifiers = { vars.modkey },
            keygroup = "numrow",
            description = "view tag",
            group = "tag",
            on_press = function(index)
                local s = awful.screen.focused()
                if not s then
                    return
                end
                local t = s.tags[index]
                if t then
                    history.switch(t)
                end
            end,
        }),

        awful.key({
            modifiers = { vars.modkey, "Shift" },
            keygroup = "numrow",
            description = "move to tag",
            group = "tag",
            on_press = function(index)
                if client.focus then
                    local t = client.focus.screen.tags[index]
                    if t then
                        client.focus:move_to_tag(t)
                    end
                end
            end,
        }),

        awful.key({
            modifiers = { vars.modkey },
            key = "grave",
            on_press = function()
                history.back()
            end,
            description = "workspace history older",
            group = "tag",
        }),
        awful.key({
            modifiers = { vars.modkey, "Shift" },
            key = "grave",
            on_press = function()
                history.forward()
            end,
            description = "workspace history newer",
            group = "tag",
        }),

        awful.key({
            modifiers = { vars.modkey },
            key = "h",
            on_press = function()
                focus_dir("left")
            end,
            description = "focus left",
            group = "client",
        }),
        awful.key({
            modifiers = { vars.modkey },
            key = "j",
            on_press = function()
                focus_dir("down")
            end,
            description = "focus down",
            group = "client",
        }),
        awful.key({
            modifiers = { vars.modkey },
            key = "k",
            on_press = function()
                focus_dir("up")
            end,
            description = "focus up",
            group = "client",
        }),
        awful.key({
            modifiers = { vars.modkey },
            key = "l",
            on_press = function()
                focus_dir("right")
            end,
            description = "focus right",
            group = "client",
        }),
        awful.key({
            modifiers = { vars.modkey },
            key = "Left",
            on_press = function()
                focus_dir("left")
            end,
            description = "focus left",
            group = "client",
        }),
        awful.key({
            modifiers = { vars.modkey },
            key = "Down",
            on_press = function()
                focus_dir("down")
            end,
            description = "focus down",
            group = "client",
        }),
        awful.key({
            modifiers = { vars.modkey },
            key = "Up",
            on_press = function()
                focus_dir("up")
            end,
            description = "focus up",
            group = "client",
        }),
        awful.key({
            modifiers = { vars.modkey },
            key = "Right",
            on_press = function()
                focus_dir("right")
            end,
            description = "focus right",
            group = "client",
        }),

        awful.key({
            modifiers = { vars.modkey },
            key = "Tab",
            on_press = function()
                history.client_back()
            end,
            description = "focus previous window",
            group = "client",
        }),
        awful.key({
            modifiers = { vars.modkey, "Shift" },
            key = "Tab",
            on_press = function()
                history.client_forward()
            end,
            description = "focus next window in history",
            group = "client",
        }),

        awful.key({
            modifiers = { vars.modkey },
            key = "c",
            on_press = function()
                awful.client.focus.byidx(1)
                if client.focus then
                    client.focus:raise()
                end
            end,
            description = "focus next in workspace",
            group = "client",
        }),
        awful.key({
            modifiers = { vars.modkey, "Shift" },
            key = "c",
            on_press = function()
                awful.client.focus.byidx(-1)
                if client.focus then
                    client.focus:raise()
                end
            end,
            description = "focus previous in workspace",
            group = "client",
        }),

        awful.key({
            modifiers = { vars.modkey },
            key = "b",
            on_press = function()
                local m = awful.client.getmaster()
                if m then
                    m:activate()
                end
            end,
            description = "focus master client",
            group = "client",
        }),
        awful.key({
            modifiers = { vars.modkey, "Shift" },
            key = "b",
            on_press = with_focused(function(c)
                c:swap(awful.client.getmaster())
            end),
            description = "swap with master client",
            group = "client",
        }),

        awful.key({
            modifiers = { vars.modkey },
            key = "comma",
            on_press = function()
                awful.tag.incnmaster(1, nil, true)
            end,
            description = "increase master count",
            group = "client",
        }),
        awful.key({
            modifiers = { vars.modkey },
            key = "period",
            on_press = function()
                awful.tag.incnmaster(-1, nil, true)
            end,
            description = "decrease master count",
            group = "client",
        }),
        awful.key({
            modifiers = { vars.modkey, "Shift" },
            key = "comma",
            on_press = function()
                awful.tag.incncol(1, nil, true)
            end,
            description = "increase column count",
            group = "client",
        }),
        awful.key({
            modifiers = { vars.modkey, "Shift" },
            key = "period",
            on_press = function()
                awful.tag.incncol(-1, nil, true)
            end,
            description = "decrease column count",
            group = "client",
        }),

        awful.key({
            modifiers = { vars.modkey },
            key = "semicolon",
            on_press = function()
                local t = awful.screen.focused().selected_tag
                if t then
                    t.gap = math.max(0, t.gap - 2)
                end
            end,
            description = "decrease gaps",
            group = "client",
        }),
        awful.key({
            modifiers = { vars.modkey },
            key = "apostrophe",
            on_press = function()
                local t = awful.screen.focused().selected_tag
                if t then
                    t.gap = t.gap + 2
                end
            end,
            description = "increase gaps",
            group = "client",
        }),
        awful.key({
            modifiers = { vars.modkey, "Shift" },
            key = "semicolon",
            on_press = function()
                local t = awful.screen.focused().selected_tag
                if t then
                    t.gap = vars.default_gap(t.screen)
                end
            end,
            description = "reset gaps",
            group = "client",
        }),

        awful.key({
            modifiers = { vars.modkey },
            key = "m",
            on_press = function()
                awful.layout.inc(1)
            end,
            description = "next layout",
            group = "client",
        }),
        awful.key({
            modifiers = { vars.modkey, "Shift" },
            key = "m",
            on_press = function()
                awful.layout.inc(-1)
            end,
            description = "previous layout",
            group = "client",
        }),
        awful.key({
            modifiers = { vars.modkey },
            key = "r",
            on_press = function()
                layouts.rotate("cw")
            end,
            description = "rotate layout clockwise",
            group = "client",
        }),
        awful.key({
            modifiers = { vars.modkey, "Shift" },
            key = "r",
            on_press = function()
                layouts.rotate("ccw")
            end,
            description = "rotate layout counter-clockwise",
            group = "client",
        }),

        awful.key({
            modifiers = { vars.modkey },
            key = "f",
            on_press = with_focused(function(c)
                c.fullscreen = not c.fullscreen
                c:raise()
            end),
            description = "toggle fullscreen",
            group = "client",
        }),
        awful.key({
            modifiers = { vars.modkey, "Shift" },
            key = "f",
            on_press = with_focused(function()
                awful.client.floating.toggle()
            end),
            description = "toggle floating",
            group = "client",
        }),
        awful.key({
            modifiers = { vars.modkey },
            key = "t",
            on_press = with_focused(function(c)
                c.maximized = not c.maximized
                c:raise()
            end),
            description = "toggle maximized",
            group = "client",
        }),
        awful.key({
            modifiers = { vars.modkey, "Shift" },
            key = "t",
            on_press = with_focused(function(c)
                c.maximized_vertical = not c.maximized_vertical
                c:raise()
            end),
            description = "toggle maximized vertical",
            group = "client",
        }),
        awful.key({
            modifiers = { vars.modkey },
            key = "u",
            on_press = with_focused(function(c)
                c.minimized = true
            end),
            description = "minimize client",
            group = "client",
        }),
        awful.key({
            modifiers = { vars.modkey, "Shift" },
            key = "u",
            on_press = function()
                awful.client.restore()
            end,
            description = "restore minimized client",
            group = "client",
        }),
        awful.key({
            modifiers = { vars.modkey },
            key = "q",
            on_press = with_focused(function(c)
                c:kill()
            end),
            description = "close client",
            group = "client",
        }),
        awful.key({
            modifiers = { vars.modkey, "Shift" },
            key = "q",
            on_press = function()
                awful.spawn("xkill")
            end,
            description = "force kill client",
            group = "client",
        }),

        awful.key({
            modifiers = { vars.modkey },
            key = "Return",
            on_press = function()
                awful.spawn(vars.terminal)
            end,
            description = "open terminal",
            group = "launcher",
        }),
        awful.key({
            modifiers = { vars.modkey, "Shift" },
            key = "Return",
            on_press = function()
                awful.spawn("menu-terminalapps")
            end,
            description = "terminal apps menu",
            group = "launcher",
        }),
        awful.key({
            modifiers = { vars.modkey },
            key = "w",
            on_press = function()
                awful.spawn(vars.browser)
            end,
            description = "open browser",
            group = "launcher",
        }),
        awful.key({
            modifiers = { vars.modkey, "Shift" },
            key = "w",
            on_press = function()
                awful.spawn(vars.browser .. " " .. vars.browser_private_opt)
            end,
            description = "open browser (private)",
            group = "launcher",
        }),
        awful.key({
            modifiers = { vars.modkey },
            key = "e",
            on_press = function()
                awful.spawn(vars.file_manager)
            end,
            description = "open file manager",
            group = "launcher",
        }),
        awful.key({
            modifiers = { vars.modkey },
            key = "space",
            on_press = function()
                awful.spawn("menu-apps launch")
            end,
            description = "application launcher",
            group = "launcher",
        }),
        awful.key({
            modifiers = { vars.modkey, "Shift" },
            key = "space",
            on_press = function()
                awful.spawn("menu-apps refresh")
            end,
            description = "application launcher (refresh)",
            group = "launcher",
        }),
        awful.key({
            modifiers = { vars.modkey },
            key = "s",
            on_press = function()
                awful.spawn("menu-allmenus")
            end,
            description = "show all menus",
            group = "launcher",
        }),
        awful.key({
            modifiers = { vars.modkey },
            key = "p",
            on_press = function()
                awful.spawn("menu-power")
            end,
            description = "power menu",
            group = "launcher",
        }),
        awful.key({
            modifiers = { vars.modkey },
            key = "o",
            on_press = function()
                awful.spawn("menu-surfraw")
            end,
            description = "web search menu",
            group = "launcher",
        }),
        awful.key({
            modifiers = { vars.modkey },
            key = "v",
            on_press = function()
                awful.spawn("menu-video")
            end,
            description = "video menu",
            group = "launcher",
        }),
        awful.key({
            modifiers = { vars.modkey },
            key = "x",
            on_press = function()
                awful.spawn("menu-clip paste")
            end,
            description = "clipboard paste",
            group = "launcher",
        }),
        awful.key({
            modifiers = { vars.modkey, "Shift" },
            key = "x",
            on_press = function()
                awful.spawn("menu-clip delete")
            end,
            description = "clipboard delete",
            group = "launcher",
        }),

        awful.key({
            modifiers = { vars.modkey },
            key = "bracketleft",
            on_press = function()
                awful.spawn("menu-window")
            end,
            description = "window menu",
            group = "menu",
        }),
        awful.key({
            modifiers = { vars.modkey, "Shift" },
            key = "bracketleft",
            on_press = function()
                awful.spawn("menu-window-hide")
            end,
            description = "window hide menu",
            group = "menu",
        }),
        awful.key({
            modifiers = { vars.modkey },
            key = "bracketright",
            on_press = function()
                awful.spawn("menu-workspace")
            end,
            description = "workspace menu",
            group = "menu",
        }),
        awful.key({
            modifiers = { vars.modkey },
            key = "equal",
            on_press = function()
                awful.spawn("menu-calc")
            end,
            description = "calculator",
            group = "menu",
        }),

        awful.key({
            modifiers = { vars.modkey },
            key = "n",
            on_press = function()
                awful.spawn("dunstctl close")
            end,
            description = "close notification",
            group = "notification",
        }),
        awful.key({
            modifiers = { vars.modkey, "Shift" },
            key = "n",
            on_press = function()
                awful.spawn("dunstctl action")
            end,
            description = "notification action",
            group = "notification",
        }),

        awful.key({
            modifiers = { vars.modkey },
            key = "Escape",
            on_press = function()
                awesome.restart()
            end,
            description = "reload awesome",
            group = "awesome",
        }),
        awful.key({
            modifiers = { vars.modkey, "Shift" },
            key = "Escape",
            on_press = function()
                awesome.quit()
            end,
            description = "quit awesome",
            group = "awesome",
        }),
        awful.key({
            modifiers = { vars.modkey },
            key = "slash",
            on_press = function()
                awful.spawn("menu-keybindings-awesomewm")
            end,
            description = "show help",
            group = "awesome",
        }),

        awful.key({
            modifiers = {},
            key = "Print",
            on_press = function()
                awful.spawn("screenshot full")
            end,
            description = "screenshot full screen",
            group = "screenshot",
        }),
        awful.key({
            modifiers = { vars.modkey },
            key = "Print",
            on_press = function()
                awful.spawn("screenshot window")
            end,
            description = "screenshot window",
            group = "screenshot",
        }),
        awful.key({
            modifiers = { vars.modkey, "Shift" },
            key = "Print",
            on_press = function()
                awful.spawn("screenshot select")
            end,
            description = "screenshot selection",
            group = "screenshot",
        }),

        awful.key({
            modifiers = {},
            key = "XF86AudioLowerVolume",
            on_press = function()
                awful.spawn("volume decrease 10")
            end,
            description = "volume down",
            group = "media",
        }),
        awful.key({
            modifiers = {},
            key = "XF86AudioRaiseVolume",
            on_press = function()
                awful.spawn("volume increase 10")
            end,
            description = "volume up",
            group = "media",
        }),
        awful.key({
            modifiers = {},
            key = "XF86AudioMute",
            on_press = function()
                awful.spawn("volume mute")
            end,
            description = "volume mute",
            group = "media",
        }),
        awful.key({
            modifiers = {},
            key = "XF86AudioPlay",
            on_press = function()
                awful.spawn("mediactl toggle")
            end,
            description = "play/pause",
            group = "media",
        }),
        awful.key({
            modifiers = {},
            key = "XF86AudioStop",
            on_press = function()
                awful.spawn("mediactl stop")
            end,
            description = "stop playback",
            group = "media",
        }),
        awful.key({
            modifiers = {},
            key = "XF86AudioNext",
            on_press = function()
                awful.spawn("mediactl next")
            end,
            description = "next track",
            group = "media",
        }),
        awful.key({
            modifiers = {},
            key = "XF86AudioPrev",
            on_press = function()
                awful.spawn("mediactl prev")
            end,
            description = "previous track",
            group = "media",
        }),

        awful.key({
            modifiers = {},
            key = "XF86MonBrightnessUp",
            on_press = function()
                awful.spawn("brightness increase")
            end,
            description = "brightness up",
            group = "brightness",
        }),
        awful.key({
            modifiers = {},
            key = "XF86MonBrightnessDown",
            on_press = function()
                awful.spawn("brightness decrease")
            end,
            description = "brightness down",
            group = "brightness",
        }),

        awful.key({
            modifiers = { vars.modkey },
            key = "backslash",
            on_press = function()
                awful.spawn("polybarctl switch")
            end,
            description = "switch bar",
            group = "bar",
        }),
        awful.key({
            modifiers = { vars.modkey, "Shift" },
            key = "backslash",
            on_press = function()
                awful.spawn("polybarctl toggle_all")
            end,
            description = "toggle all bars",
            group = "bar",
        }),

        awful.key({
            modifiers = { vars.modkey },
            key = "minus",
            on_press = function()
                awful.spawn("lockctl lock")
            end,
            description = "lock screen",
            group = "system",
        }),

        awful.key({
            modifiers = { vars.modkey },
            key = "z",
            on_press = function()
                require("scratchpads"):toggle()
            end,
            description = "dropdown terminal",
            group = "launcher",
        }),

        awful.key({
            modifiers = { vars.modkey },
            key = "a",
            on_press = function()
                awesome.emit_signal("bling::window_switcher::turn_on")
            end,
            description = "visual window switcher",
            group = "client",
        })
    )
end

return _M
