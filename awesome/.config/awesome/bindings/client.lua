-- Client keybindings with DWIM (Do What I Mean) pattern
-- Floating clients get move/resize, tiled clients get swap/master-width

local gears = require("gears")
local awful = require("awful")
local vars = require("vars")
local tabbed = require("bling.module.tabbed")

local _M = {}

local function move_dwim(c, direction)
    if c.floating then
        if direction == "left" then
            c:relative_move(-vars.floating_move_amount, 0, 0, 0)
        elseif direction == "right" then
            c:relative_move(vars.floating_move_amount, 0, 0, 0)
        elseif direction == "up" then
            c:relative_move(0, -vars.floating_move_amount, 0, 0)
        elseif direction == "down" then
            c:relative_move(0, vars.floating_move_amount, 0, 0)
        end
    else
        awful.client.swap.bydirection(direction, c, nil)
    end
end

local function resize_dwim(c, direction)
    if c.floating then
        if direction == "left" then
            c:relative_move(0, 0, -vars.floating_move_amount, 0)
        elseif direction == "right" then
            c:relative_move(0, 0, vars.floating_move_amount, 0)
        elseif direction == "up" then
            c:relative_move(0, 0, 0, -vars.floating_move_amount)
        elseif direction == "down" then
            c:relative_move(0, 0, 0, vars.floating_move_amount)
        end
    else
        if direction == "left" then
            awful.tag.incmwfact(-vars.tiling_resize_factor)
        elseif direction == "right" then
            awful.tag.incmwfact(vars.tiling_resize_factor)
        elseif direction == "up" then
            awful.client.incwfact(-vars.tiling_resize_factor)
        elseif direction == "down" then
            awful.client.incwfact(vars.tiling_resize_factor)
        end
    end
end

_M._move_dwim = move_dwim
_M._resize_dwim = resize_dwim

function _M.get()
    return gears.table.join(
        awful.key({
            modifiers = { vars.modkey, "Shift" },
            key = "h",
            on_press = function(c)
                move_dwim(c, "left")
            end,
            description = "move left (floating) / swap left (tiled)",
            group = "client",
        }),
        awful.key({
            modifiers = { vars.modkey, "Shift" },
            key = "j",
            on_press = function(c)
                move_dwim(c, "down")
            end,
            description = "move down (floating) / swap down (tiled)",
            group = "client",
        }),
        awful.key({
            modifiers = { vars.modkey, "Shift" },
            key = "k",
            on_press = function(c)
                move_dwim(c, "up")
            end,
            description = "move up (floating) / swap up (tiled)",
            group = "client",
        }),
        awful.key({
            modifiers = { vars.modkey, "Shift" },
            key = "l",
            on_press = function(c)
                move_dwim(c, "right")
            end,
            description = "move right (floating) / swap right (tiled)",
            group = "client",
        }),
        awful.key({
            modifiers = { vars.modkey, "Shift" },
            key = "Left",
            on_press = function(c)
                move_dwim(c, "left")
            end,
            description = "move left (floating) / swap left (tiled)",
            group = "client",
        }),
        awful.key({
            modifiers = { vars.modkey, "Shift" },
            key = "Down",
            on_press = function(c)
                move_dwim(c, "down")
            end,
            description = "move down (floating) / swap down (tiled)",
            group = "client",
        }),
        awful.key({
            modifiers = { vars.modkey, "Shift" },
            key = "Up",
            on_press = function(c)
                move_dwim(c, "up")
            end,
            description = "move up (floating) / swap up (tiled)",
            group = "client",
        }),
        awful.key({
            modifiers = { vars.modkey, "Shift" },
            key = "Right",
            on_press = function(c)
                move_dwim(c, "right")
            end,
            description = "move right (floating) / swap right (tiled)",
            group = "client",
        }),

        awful.key({
            modifiers = { vars.modkey, "Control" },
            key = "h",
            on_press = function(c)
                resize_dwim(c, "left")
            end,
            description = "shrink width (floating) / decrease master factor (tiled)",
            group = "client",
        }),
        awful.key({
            modifiers = { vars.modkey, "Control" },
            key = "j",
            on_press = function(c)
                resize_dwim(c, "down")
            end,
            description = "grow height (floating) / decrease slave factor (tiled)",
            group = "client",
        }),
        awful.key({
            modifiers = { vars.modkey, "Control" },
            key = "k",
            on_press = function(c)
                resize_dwim(c, "up")
            end,
            description = "shrink height (floating) / increase slave factor (tiled)",
            group = "client",
        }),
        awful.key({
            modifiers = { vars.modkey, "Control" },
            key = "l",
            on_press = function(c)
                resize_dwim(c, "right")
            end,
            description = "grow width (floating) / increase master factor (tiled)",
            group = "client",
        }),
        awful.key({
            modifiers = { vars.modkey, "Control" },
            key = "Left",
            on_press = function(c)
                resize_dwim(c, "left")
            end,
            description = "shrink width (floating) / decrease master factor (tiled)",
            group = "client",
        }),
        awful.key({
            modifiers = { vars.modkey, "Control" },
            key = "Down",
            on_press = function(c)
                resize_dwim(c, "down")
            end,
            description = "grow height (floating) / decrease slave factor (tiled)",
            group = "client",
        }),
        awful.key({
            modifiers = { vars.modkey, "Control" },
            key = "Up",
            on_press = function(c)
                resize_dwim(c, "up")
            end,
            description = "shrink height (floating) / increase slave factor (tiled)",
            group = "client",
        }),
        awful.key({
            modifiers = { vars.modkey, "Control" },
            key = "Right",
            on_press = function(c)
                resize_dwim(c, "right")
            end,
            description = "grow width (floating) / increase master factor (tiled)",
            group = "client",
        }),

        awful.key({
            modifiers = { vars.modkey },
            key = "y",
            on_press = function(c)
                tabbed.pick(c)
            end,
            description = "pick window to tab",
            group = "client",
        }),
        awful.key({
            modifiers = { vars.modkey, "Shift" },
            key = "y",
            on_press = function(c)
                tabbed.pop(c)
            end,
            description = "remove from tab group",
            group = "client",
        }),
        awful.key({
            modifiers = { vars.modkey },
            key = "g",
            on_press = function()
                tabbed.iter(1)
            end,
            description = "next tab",
            group = "client",
        }),
        awful.key({
            modifiers = { vars.modkey, "Shift" },
            key = "g",
            on_press = function()
                tabbed.iter(-1)
            end,
            description = "previous tab",
            group = "client",
        })
    )
end

return _M
