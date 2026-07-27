local awful = require("awful")

local autostart = {}

function autostart.run()
    awful.spawn.with_shell("~/.config/wm/autostart")
end

return autostart
