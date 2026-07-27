local math = math
local awful = require("awful")
local rubato = require("rubato")
local scratchpad = require("bling.module.scratchpad")
local vars = require("vars")

local function detect_bar_pos(s)
    for _, c in ipairs(client.get()) do
        if c.type == "dock" and c.screen == s then
            return (c.y + c.height / 2 < s.geometry.height / 2) and "top" or "bottom"
        end
    end
    return "top"
end

local function compute_geometry(s)
    local wa = s.workarea
    local geo = s.geometry
    local bar = detect_bar_pos(s)

    local h = math.floor(wa.height * 0.3)
    local w = math.min(1200, math.floor(wa.width * 0.8))
    local x = math.floor((wa.width - w) / 2) + wa.x
    local y, offscreen

    local margin = vars.default_gap(s) * 2

    if bar == "top" then
        y = wa.y + wa.height - h - margin
        offscreen = geo.height + h + margin
    else
        y = wa.y + margin
        offscreen = -h - margin
    end

    return {
        x = x,
        y = y,
        height = h,
        width = w,
        offscreen_y = offscreen,
    }
end

local anim_y = rubato.timed({
    pos = 0,
    rate = 60,
    intro = 0.1,
    duration = 0.3,
    easing = rubato.easing.quadratic,
    awestore_compat = true,
})
anim_y._offscreen = 0
anim_y.initial = function()
    return anim_y._offscreen
end

local spad = scratchpad({
    command = vars.scratchpad_cmd,
    rule = { class = "scratchpad_term" },
    sticky = true,
    autoclose = true,
    floating = true,
    reapply = true,
    dont_focus_before_close = false,
    rubato = { y = anim_y },
})

local M = {}

function M.toggle()
    local s = awful.screen.focused()
    if not s then
        return
    end
    local g = compute_geometry(s)

    spad.geometry = { x = g.x, y = g.y, height = g.height, width = g.width }
    anim_y._offscreen = g.offscreen_y
    anim_y.pos = g.offscreen_y

    spad:toggle()
end

return M
