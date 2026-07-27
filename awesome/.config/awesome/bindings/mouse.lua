local awful = require("awful")
local vars = require("vars")

local _M = {}

function _M.set_global()
    awful.mouse.append_global_mousebindings({
        awful.button({}, 4, function()
            local t = awful.screen.focused().selected_tag
            if t and #t:clients() == 0 then
                awful.tag.viewnext()
            end
        end),
        awful.button({}, 5, function()
            local t = awful.screen.focused().selected_tag
            if t and #t:clients() == 0 then
                awful.tag.viewprev()
            end
        end),
    })
end

function _M.set_client()
    client.connect_signal("request::default_mousebindings", function()
        awful.mouse.append_client_mousebindings({
            awful.button({}, 1, function(c)
                c:activate({ context = "mouse_click" })
            end),
            awful.button({ vars.modkey }, 1, function(c)
                c:activate({ context = "mouse_click", action = "mouse_move" })
            end),
            awful.button({ vars.modkey }, 3, function(c)
                c:activate({ context = "mouse_click", action = "mouse_resize" })
            end),
        })
    end)
end

return _M
