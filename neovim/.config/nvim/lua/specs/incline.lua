-- Floating per-window navigation badge (b0o/incline.nvim) with LSP symbol
-- breadcrumbs (SmiteshP/nvim-navic). Replaces the former heirline winbar:
-- no top-line cost, per-window, and the navic chain provides the symbol
-- navigation the winbar never had. API facts used here are verified against
-- incline@debd628 and navic@455808f (doc/incline.txt, lua/nvim-navic/init.lua).
local helpers = require("incline.helpers")

-- Palette + shading follow the live tinted-nvim theme (same trick as the
-- heirline spec: pcall the palette, keep a static fallback). shade() is the
-- bufferline.nvim darkening formula, duplicated here to keep spec files
-- self-contained (see specs/heirline.lua for the original).
local FALLBACK_PALETTE = {
    base00 = "#101010",
    base03 = "#767676",
    base04 = "#9e9e9e",
    base05 = "#d0d0d0",
    base0B = "#b5bd68",
}

local function palette()
    local ok, tinted = pcall(require, "tinted-nvim")
    if ok then
        local ok_pal, pal = pcall(tinted.get_palette)
        if ok_pal and type(pal) == "table" and pal.base00 then
            return pal
        end
    end
    return FALLBACK_PALETTE
end

local function shade(hexcolor, pct)
    local function channel(s)
        local v = math.floor(tonumber(s, 16) * (100 + pct) / 100 + 0.5)
        return string.format("%02x", math.min(255, math.max(0, v)))
    end
    return "#" .. channel(hexcolor:sub(2, 3)) .. channel(hexcolor:sub(4, 5)) .. channel(hexcolor:sub(6, 7))
end

-- navic supplies the symbol chain; segments are consumed via get_data()
-- (structured) rather than get_location() because incline floats render
-- plain text and get_location(highlight=true) embeds statusline %-codes.
require("nvim-navic").setup({})

require("incline").setup({
    ignore = {
        -- buftypes/wintypes "special" already covers terminals, quickfix,
        -- floating dashboards; oil buffers are normal-filetype, so list them.
        filetypes = { "oil" },
    },
    window = {
        padding = 0,
        margin = { horizontal = 0, vertical = 1 },
        placement = { vertical = "top", horizontal = "right" },
    },
    -- No highlight.groups override: incline validates that field against
    -- static strings/tables only. Theme-following chip colors come from
    -- the nvim_set_hl calls below (ours beat incline's default=true groups
    -- and are refreshed on ColorScheme).
    render = function(props)
        local name = vim.api.nvim_buf_get_name(props.buf)
        if name == "" then
            return nil
        end

        local pal = palette()
        local tail = vim.fn.fnamemodify(name, ":t")

        -- git-root-relative directory run (nil outside repos → "~"-style)
        local root = vim.fs.root(props.buf, { ".git" })
        local dir = root and vim.fn.fnamemodify(name, ":.:h") or vim.fn.fnamemodify(name, ":~:h")
        if dir == "." or dir == "/" then
            dir = nil
        else
            dir = dir .. "/"
        end

        local icon, icon_hl
        local ok, icons = pcall(require, "mini.icons")
        if ok then
            local ok_icon, i, hl = pcall(icons.get, "filetype", vim.bo[props.buf].filetype)
            if ok_icon and i then
                icon, icon_hl = i, hl
            end
        end

        local res = {
            { " " },
            icon and { icon .. " ", group = icon_hl } or "",
            dir and { dir, guifg = pal.base03 } or "",
            { tail, gui = vim.bo[props.buf].modified and "bold,italic" or "bold", guifg = pal.base05 },
            vim.bo[props.buf].modified and { " \u{25CF}", guifg = pal.base0B } or "",
        }

        -- Symbol breadcrumbs on the focused window only: navic's context
        -- tracks the CURRENT window's cursor (lib.lua:314), so background
        -- badges would show stale chains -- the official pairing recipe
        -- gates the navic segment on props.focused for exactly this reason.
        if props.focused then
            local ok_navic, navic = pcall(require, "nvim-navic")
            if ok_navic and navic.is_available(props.buf) then
                for _, item in ipairs(navic.get_data(props.buf) or {}) do
                    res[#res + 1] = {
                        { " \u{203A} ", group = "NavicSeparator" },
                        { item.icon, group = "NavicIcons" .. item.type },
                        { item.name, group = "NavicText" },
                    }
                end
            end
        end

        res[#res + 1] = { " " }
        return res
    end,
})

-- Chip colors: the badge window's Normal rides these groups (incline's
-- default winhighlight mapping), so painting them here skins the whole
-- float. Recomputed on every theme switch; tinty live-switching included.
local function refresh_incline_highlights()
    local bg = shade(palette().base00, -45)
    vim.api.nvim_set_hl(0, "InclineNormal", { bg = bg })
    vim.api.nvim_set_hl(0, "InclineNormalNC", { bg = bg })
end

refresh_incline_highlights()
vim.api.nvim_create_augroup("Incline_colors", { clear = true })
vim.api.nvim_create_autocmd("ColorScheme", {
    group = "Incline_colors",
    desc = "incline: re-derive badge chip colors after theme switch",
    callback = refresh_incline_highlights,
})
