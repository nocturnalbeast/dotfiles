local awful = require("awful")

local _M = {}

local rotation_groups = {
    {
        awful.layout.suit.tile,
        awful.layout.suit.tile.bottom,
        awful.layout.suit.tile.left,
        awful.layout.suit.tile.top,
    },
    { awful.layout.suit.fair, awful.layout.suit.fair.horizontal },
    {
        awful.layout.suit.corner.nw,
        awful.layout.suit.corner.ne,
        awful.layout.suit.corner.se,
        awful.layout.suit.corner.sw,
    },
    { awful.layout.suit.spiral, awful.layout.suit.spiral.dwindle },
}

function _M.rotate(direction)
    local s = awful.screen.focused()
    if not s then
        return
    end
    local tag = s.selected_tag
    if not tag then
        return
    end
    local current = tag.layout
    for _, group in ipairs(rotation_groups) do
        for i, layout in ipairs(group) do
            if layout == current then
                local next_idx
                if direction == "cw" then
                    next_idx = (i % #group) + 1
                else
                    next_idx = ((i - 2) % #group) + 1
                end
                tag.layout = group[next_idx]
                return
            end
        end
    end
end

return _M
