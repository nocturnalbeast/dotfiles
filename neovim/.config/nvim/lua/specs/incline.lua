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
    hide = {
        -- Row-based cursorline hiding (winline.lua:434-441): the focused
        -- window's badge hides whenever the cursor shares its row — the
        -- first line of the viewport — even on short lines that never
        -- reach under the top-right badge. ('smart', the default, only
        -- hides on true cell overlap, column-aware.) Unfocused badges
        -- stay: they have no visible cursorline to yield to.
        cursorline = "focused_win",
    },
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
        local modified = vim.bo[props.buf].modified

        -- TOTAL badge budget: half the window (min 40). Every component is
        -- measured (strdisplaywidth, so cellwidths-registered double-width
        -- icons count correctly; navic's nf-md icons are not registered, so
        -- each gets a manual +1) and the shrink ladder fires in priority
        -- order: dir collapses first, then the navic chain drops OUTERMOST
        -- symbols (innermost are the current context), then the tail
        -- head-truncates. Nothing may exceed the budget combined.
        local winw = vim.api.nvim_win_get_width(props.win)
        local budget = math.max(40, math.floor(winw * 0.5))

        local function width(s)
            return vim.fn.strdisplaywidth(s)
        end

        local icon, icon_hl
        local ok, icons = pcall(require, "mini.icons")
        if ok then
            local ok_icon, i, hl = pcall(icons.get, "filetype", vim.bo[props.buf].filetype)
            if ok_icon and i then
                icon, icon_hl = i, hl
            end
        end

        -- Fixed overhead: pads + icon slot + tail + modified dot.
        local fixed = 2 + (icon and width(icon) + 1 or 0) + width(tail) + (modified and 2 or 0)

        -- git-root-relative directory run (nil outside repos → "~"-style)
        local root = vim.fs.root(props.buf, { ".git" })
        local dir = root and vim.fn.fnamemodify(name, ":.:h") or vim.fn.fnamemodify(name, ":~:h")
        if dir == "." or dir == "/" then
            dir = nil
        end

        -- navic chain (focused only; see staleness note in navic comment):
        -- build items with capped names first, so its width is known before
        -- the dir decides how much room it gets.
        local navic_items = {}
        if props.focused then
            local ok_navic, navic = pcall(require, "nvim-navic")
            if ok_navic and navic.is_available(props.buf) then
                for _, item in ipairs(navic.get_data(props.buf) or {}) do
                    navic_items[#navic_items + 1] = {
                        icon = item.icon,
                        name = width(item.name) > 15 and "…" .. item.name:sub(-14) or item.name,
                        type = item.type,
                    }
                end
            end
        end

        local function navic_width(items)
            local w = 0
            for _, it in ipairs(items) do
                w = w + 3 + (width(it.icon) + 1) + width(it.name)
            end
            return w
        end

        -- Shrink ladder for the navic chain: drop leading (outermost)
        -- symbols while over budget; a leading ellipsis marks the cut.
        local navic_dropped = false
        while #navic_items > 0 and fixed + navic_width(navic_items) + 2 > budget do
            table.remove(navic_items, 1)
            navic_dropped = true
        end

        -- Dir budget = whatever remains; budget-gated shortening (full path
        -- when there is room): pathshorten only once over budget, then the
        -- first/…/last ellipsis, then drop.
        local dir_budget = budget - fixed - navic_width(navic_items) - (navic_dropped and 2 or 0)
        if dir and #dir > 1 then
            if width(dir) + 1 > dir_budget and dir:find("/") then
                dir = vim.fn.pathshorten(dir)
            end
            if width(dir) + 1 > dir_budget then
                local first = dir:match("^([^/]+)/")
                local last = dir:match("([^/]+)/%f[%z]")
                if first and last and first ~= last then
                    dir = first .. "/\u{2026}/" .. last
                end
            end
            if width(dir) + 1 > dir_budget then
                dir = nil
            else
                dir = dir .. "/"
            end
        end

        -- Tail head-truncation as the last resort.
        if fixed + navic_width(navic_items) + (dir and width(dir) or 0) > budget then
            local room = budget - (fixed - width(tail)) - navic_width(navic_items) - (dir and width(dir) or 0) - 1
            if room < 4 then
                tail = "\u{2026}"
            else
                tail = "\u{2026}" .. tail:sub(-(room - 1))
            end
        end

        local res = {
            { " " },
            icon and { icon .. " ", group = icon_hl } or "",
            dir and { dir, guifg = pal.base03 } or "",
            { tail, gui = modified and "bold,italic" or "bold", guifg = pal.base05 },
            modified and { " \u{25CF}", guifg = pal.base0B } or "",
        }

        -- Symbol breadcrumbs: innermost symbols kept by the ladder above;
        -- the ellipsis separator marks where outer symbols were dropped.
        if navic_dropped then
            res[#res + 1] = { " \u{2026}", group = "NavicSeparator" }
        end
        for _, it in ipairs(navic_items) do
            res[#res + 1] = {
                { " \u{203A} ", group = "NavicSeparator" },
                { it.icon, group = "NavicIcons" .. it.type },
                { it.name, group = "NavicText" },
            }
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
