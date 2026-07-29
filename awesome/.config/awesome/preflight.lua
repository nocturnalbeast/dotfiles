local awful = require("awful")
local naughty = require("naughty")

local critical = {
    "terminal",
    "menu-apps",
    "screenshot",
    "volume",
    "brightness",
    "lockctl",
    "dunstctl",
}

local function check()
    local missing = {}
    for _, cmd in ipairs(critical) do
        awful.spawn.easy_async("command -v " .. cmd, function(stdout, _, _, exit_code)
            if exit_code ~= 0 then
                missing[#missing + 1] = cmd
                if #missing == 1 then
                    naughty.notify({
                        title = "Awesome WM — missing scripts",
                        text = table.concat(missing, ", ") .. " not found on $PATH",
                        timeout = 10,
                        urgency = "normal",
                    })
                end
            end
        end)
    end
end

return { check = check }
