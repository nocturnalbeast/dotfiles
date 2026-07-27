local awful = require("awful")
local layouts = require("layouts")
local history = require("history")
local vars = require("vars")

local tag_defs = {
    { name = "main", layout = awful.layout.suit.tile },
    { name = "inet", layout = awful.layout.suit.fair, master_count = 0 },
    { name = "code", layout = awful.layout.suit.corner.nw },
    { name = "data", layout = awful.layout.suit.spiral.dwindle },
    { name = "play", layout = awful.layout.suit.tile.bottom },
    { name = "docs", layout = awful.layout.suit.tile.left },
    { name = "draw", layout = awful.layout.suit.tile.left },
    { name = "txns", layout = awful.layout.suit.fair, master_count = 0 },
    { name = "info", layout = awful.layout.suit.tile },
    { name = "misc", layout = awful.layout.suit.tile },
}

local function tag_by_name(name, s)
    s = s or awful.screen.focused()
    for _, t in ipairs(s.tags) do
        if t.name == name then
            return t
        end
    end
    return nil
end

local default_layouts = {
    awful.layout.suit.tile,
    awful.layout.suit.max,
    awful.layout.suit.tile.bottom,
    awful.layout.suit.tile.top,
    awful.layout.suit.tile.left,
    awful.layout.suit.floating,
    awful.layout.suit.fair,
    awful.layout.suit.fair.horizontal,
    awful.layout.suit.corner.nw,
    awful.layout.suit.corner.ne,
    awful.layout.suit.corner.se,
    awful.layout.suit.corner.sw,
    awful.layout.suit.spiral,
    awful.layout.suit.spiral.dwindle,
    awful.layout.suit.magnifier,
    require("bling.layout.mstab"),
    require("bling.layout.centered"),
    require("bling.layout.deck"),
    require("bling.layout.equalarea"),
}

awful.layout.layouts = default_layouts

screen.connect_signal("request::desktop_decoration", function(s)
    if #s.tags > 0 then
        return
    end
    local tags = {}
    for _, def in ipairs(tag_defs) do
        tags[#tags + 1] = awful.tag.add(def.name, {
            screen = s,
            layout = def.layout,
            layouts = default_layouts,
            gap = vars.default_gap(s),
            gap_single_client = true,
            master_count = def.master_count or 1,
        })
    end
    history.switch(tags[1])
end)

return {
    definitions = tag_defs,
    tag_by_name = tag_by_name,
}
