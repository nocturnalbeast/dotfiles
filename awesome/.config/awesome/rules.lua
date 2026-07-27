local awful = require("awful")
local ruled = require("ruled.client")
local tag_by_name = require("tags").tag_by_name

local M = {}

function M.setup()
    ruled.connect_signal("request::rules", function()
        ruled.append_rule({
            id = "global",
            rule = {},
            properties = {
                size_hints_honor = false,
                focus = awful.client.focus.filter,
                raise = true,
                screen = awful.screen.focused,
                placement = awful.placement.no_overlap + awful.placement.no_offscreen,
            },
        })

        ruled.append_rule({
            id = "dock",
            rule = { type = "dock" },
            properties = { border_width = 0, honors_size_hints = true },
        })

        ruled.append_rule({
            id = "floating_apps",
            rule_any = { class = { "Nitrogen", "Lxappearance" } },
            properties = { floating = true, ontop = true, placement = awful.placement.centered, focus = true },
        })

        ruled.append_rule({
            id = "inet",
            rule_any = {
                class = {
                    "qutebrowser",
                    "firefox",
                    "Firefox",
                    "chromium-browser",
                    "Chromium-browser",
                    "librewolf",
                    "LibreWolf",
                },
            },
            properties = { tag = tag_by_name("inet"), focus = true, switch_to_tags = true },
        })

        ruled.append_rule({
            id = "code",
            rule_any = { class = { "Gnvim", "Neovide", "neovide", "VSCodium", "codium", "Cursor", "Sublime_merge" } },
            properties = { tag = tag_by_name("code"), focus = true, switch_to_tags = true },
        })

        ruled.append_rule({
            id = "code_terminal",
            rule = { class = "kitty", name = "Neovim" },
            properties = { tag = tag_by_name("code"), focus = true, switch_to_tags = true },
        })

        ruled.append_rule({
            id = "info",
            rule = { class = "kitty", name = "System Monitor" },
            properties = { tag = tag_by_name("info"), focus = true, switch_to_tags = true },
        })

        ruled.append_rule({
            id = "data",
            rule_any = {
                class = { "thunar", "Thunar", "nemo", "Nemo", "gparted", "GParted" },
                instance = { "gnome-disks" },
            },
            except = { type = "dialog" },
            properties = { tag = tag_by_name("data"), focus = true, switch_to_tags = true },
        })

        ruled.append_rule({
            id = "data_floating",
            rule = { class = "thunar", name = "File.*" },
            properties = { tag = tag_by_name("data"), floating = true, focus = true, switch_to_tags = true },
        })

        ruled.append_rule({
            id = "play",
            rule = { class = "mpv" },
            properties = { tag = tag_by_name("play"), focus = true, switch_to_tags = true, honors_size_hints = false },
        })

        ruled.append_rule({
            id = "docs",
            rule_any = {
                class = { "libreoffice", "LibreOffice", "soffice", "Zathura" },
                instance = { "libreoffice", "libreoffice-startcenter" },
            },
            properties = { tag = tag_by_name("docs"), focus = true, switch_to_tags = true },
        })

        ruled.append_rule({
            id = "draw_apps",
            rule_any = { class = { "Gimp", "Gimp-2.10", "pinta", "Pinta", "Inkscape" } },
            properties = { tag = tag_by_name("draw"), floating = true, focus = true, switch_to_tags = true },
        })

        ruled.append_rule({
            id = "txns",
            rule_any = {
                class = {
                    "TelegramDesktop",
                    "telegramdesktop",
                    "Uget-gtk",
                    "deluge",
                    "Deluge",
                    "Transmission-gtk",
                    "Transmission-qt",
                },
                instance = { "transmission-qt" },
                name = { "Syncthing GTK" },
            },
            properties = { tag = tag_by_name("txns"), focus = true, switch_to_tags = true },
        })

        ruled.append_rule({
            id = "misc",
            rule = { class = "Meld" },
            properties = { tag = tag_by_name("misc"), focus = true, switch_to_tags = true },
        })

        ruled.append_rule({
            id = "dialog",
            rule = { type = "dialog" },
            properties = { floating = true, ontop = true, placement = awful.placement.centered, focus = true },
        })

        ruled.append_rule({
            id = "splash",
            rule = { type = "splash" },
            properties = { floating = true, ontop = true, placement = awful.placement.centered, focus = true },
        })

        ruled.append_rule({
            id = "utility",
            rule = { type = "utility" },
            properties = { floating = true, ontop = true, placement = awful.placement.centered, focus = true },
        })
    end)
end

return M
