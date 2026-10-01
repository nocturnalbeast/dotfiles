-- Colorscheme: tinted-nvim following the tinty selector (same theme system
-- as tmux/kitty/fzf). watch=true auto-switches when tinty changes schemes.
-- Wallpaper-palette generation is intentionally dropped (plan decision #16).
-- No highlight overrides here: heirline reads live theme groups.

-- Static dark fallback palette (ported from the nvim-mac harvest), used
-- whenever tinty's current_scheme file cannot be resolved.
local fallback_scheme = {
    variant = "dark",
    base00 = "#101010",
    base01 = "#181818",
    base02 = "#212121",
    base03 = "#2a2a2a",
    base04 = "#8a8a8a",
    base05 = "#d0d0d0",
    base06 = "#e0e0e0",
    base07 = "#f5f5f5",
    base08 = "#cc6666",
    base09 = "#de935f",
    base0A = "#f0c674",
    base0B = "#b5bd68",
    base0C = "#8abeb7",
    base0D = "#81a2be",
    base0E = "#b294bb",
    base0F = "#a3685a",
}

local ok, tinted = pcall(require, "tinted-nvim")
if not ok then
    vim.notify("tinted-nvim not available, colorscheme stays default", vim.log.levels.WARN)
    return
end

-- apply_scheme_on_startup defaults to true, so setup() both configures and
-- applies the resolved scheme; no explicit :colorscheme call is needed.
tinted.setup({
    default_scheme = "base16-nvim-unified-fallback",
    schemes = {
        ["base16-nvim-unified-fallback"] = fallback_scheme,
    },
    selector = {
        enabled = true,
        mode = "file",
        path = "~/.local/share/tinted-theming/tinty/current_scheme",
        watch = true,
    },
})
