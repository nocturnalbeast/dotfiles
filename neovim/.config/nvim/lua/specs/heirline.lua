-- heirline.nvim statusline, wired against the installed API (heirline@fae936a):
-- table-only setup, hl-as-string resolution, palette aliases via opts.colors,
-- canonical on_colorscheme refresh. Visual design: chip chain on the theme's
-- StatusLine bg (solid-bg segments, single-space inner padding, single-space
-- gaps, zero powerline glyphs), luminance-contrast mode chip with per-mode
-- icons, width-adaptive filename with dim-dir/bright-tail, gitsigns branch +
-- colored counts, transient center column (search count / macro recording).
-- The winbar was replaced by the incline floating badge (specs/incline.lua).
local conditions = require("heirline.conditions")
local utils = require("heirline.utils")

-- Pick black-ish or white-ish fg for any bg hex (luminance, ~10 lines).
local function contrast_fg(bg_hex, dark, light)
    local r = tonumber(bg_hex:sub(1, 2), 16)
    local g = tonumber(bg_hex:sub(3, 4), 16)
    local b = tonumber(bg_hex:sub(5, 6), 16)
    if not (r and g and b) then
        return light or "#ffffff"
    end
    local luminance = (0.299 * r + 0.587 * g + 0.114 * b) / 255
    if luminance > 0.5 then
        return dark or "#000000"
    end
    return light or "#ffffff"
end

-- Static dark fallback palette (ported from the tinted harvest); replaced
-- by the live tinted-nvim palette when available, refreshed on ColorScheme
-- so the statusline follows tinty scheme switches.
local fallback = {
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

local palette = fallback

local function refresh_palette()
    local ok, tinted = pcall(require, "tinted-nvim")
    if ok then
        local got_it, live = pcall(tinted.get_palette)
        if got_it and type(live) == "table" and live.base00 and live.base0D then
            palette = live
        end
    end
end

refresh_palette()

-- Direct hex lookup, only needed where the color is computed rather than
-- declared (ViMode derives its fg from the mode bg via contrast_fg, so the
-- fg cannot be a palette alias). Static hl fields below use opts.colors
-- aliases instead ("fg = base0D"-style slots resolved by highlights.lua).
local function c(slot)
    return palette[slot] or fallback[slot]
end

-- Palette slot per mode; matched on full mode first, then first character,
-- so variants like "no", "niI" or "Rv" still resolve.
local slot_by_mode = {
    n = "base0D",
    i = "base0B",
    v = "base0E",
    V = "base0E",
    ["\22"] = "base0E", -- visual block (ctrl-v)
    R = "base08",
    r = "base08",
    c = "base0A",
    t = "base0C",
    s = "base0E",
    S = "base0E",
    ["\19"] = "base0E", -- select block (ctrl-s)
}

local label_by_mode = {
    n = "NORMAL",
    no = "OP",
    i = "INSERT",
    v = "VISUAL",
    V = "V-LINE",
    ["\22"] = "V-BLOCK",
    R = "REPLACE",
    c = "COMMAND",
    t = "TERMINAL",
    s = "SELECT",
    S = "S-LINE",
    ["\19"] = "S-BLOCK",
}

-- Per-mode icons (the kyoh86/yasunori dictionary). Nerd-font PUA glyphs
-- are ALWAYS written as \u{} escapes: literal PUA bytes do not survive the
-- edit pipeline.
local icon_by_mode = {
    n = "\u{E7C5}",
    i = "\u{F246}",
    v = "\u{F09A8}",
    V = "\u{F039}",
    ["\22"] = "\u{F0FE6}",
    R = "\u{F027C}",
    c = "\u{F423}",
    t = "\u{F120}",
}

local ViMode = {
    init = function(self)
        self.mode = vim.fn.mode(1)
        local slot = slot_by_mode[self.mode] or slot_by_mode[self.mode:sub(1, 1)] or "base0D"
        self.mode_bg = c(slot)
        self.mode_fg = contrast_fg(self.mode_bg, c("base00"), c("base07"))
        self.label = label_by_mode[self.mode] or label_by_mode[self.mode:sub(1, 1)] or self.mode:upper()
        self.icon = icon_by_mode[self.mode] or icon_by_mode[self.mode:sub(1, 1)] or ""
    end,
    provider = function(self)
        -- Single space around icon and label; common modes (NORMAL/INSERT/
        -- VISUAL) are all six chars so the chip width rarely shifts.
        return " " .. self.icon .. " " .. self.label .. " "
    end,
    hl = function(self)
        return { bg = self.mode_bg, fg = self.mode_fg, bold = true }
    end,
}

local function file_flags()
    local flags = {}
    if vim.bo.modified then
        flags[#flags + 1] = "+"
    end
    if not vim.bo.modifiable or vim.bo.readonly then
        flags[#flags + 1] = "RO"
    end
    return table.concat(flags, " ")
end

---mini.icons lookup per buffer; pcall so a missing mini.icons costs the
---icon, never the render. Glyphs arrive at runtime -- no literal PUA
---bytes live in this source. Shared by the statusline chip and the
---tabline BufferBlock.
---@param bufnr integer
---@return string icon, string|nil hl_group
local function filetype_icon(bufnr)
    local ft = vim.bo[bufnr].filetype
    if ft == "" then
        return "", nil
    end
    local ok, icons = pcall(require, "mini.icons")
    if not ok then
        return "", nil
    end
    local got_it, icon, hl = pcall(icons.get, "filetype", ft)
    if got_it and icon then
        return icon .. " ", hl
    end
    return "", nil
end

-- ── Chip chain ────────────────────────────────────────────────────────
-- Every statusline segment renders as a solid-bg chip: one space of inner
-- padding on each side, single-space gaps on the theme's StatusLine bg,
-- no powerline glyphs anywhere. chip(bg, ...) wraps one or more components
-- in that frame; a wrapped component's condition is hoisted onto the
-- wrapper (with its gap) so a hidden chip cannot leave stray padding or
-- double gaps behind (all hoisted conditions here are self-free, they only
-- probe editor state).
local function chip(bg, ...)
    local inner = {
        hl = { bg = bg },
        { provider = " " },
    }
    local hoisted
    for i = 1, select("#", ...) do
        local component = select(i, ...)
        hoisted = hoisted or component.condition
        inner[#inner + 1] = component
    end
    inner[#inner + 1] = { provider = " " }
    if hoisted then
        return { condition = hoisted, { provider = " " }, inner }
    end
    return { { provider = " " }, inner }
end

-- Width-adaptive filename (modern flexible API, statusline.lua:344): the
-- parent carries `flexible = <priority>`; child 1 renders by default and,
-- when the statusline overflows winwidth, next_child() walks toward the
-- last child. Every variant is a dir child + tail child so the chip bg is
-- inherited from the wrapping block while dir/tail override only the fg:
-- dim base04 directory portion, bold base05 tail, flags after the tail.
local FileNameTail = {
    provider = function(self)
        return self.tail
    end,
    hl = function()
        return { fg = "base05", bold = true }
    end,
}

local FileNameFlags = {
    provider = function()
        local flags = file_flags()
        return flags ~= "" and (" " .. flags) or nil
    end,
    hl = function()
        return { fg = "base04" }
    end,
}

local function dir_child(shorten)
    return {
        provider = function(self)
            if self.filename == "[No Name]" then
                return nil
            end
            return shorten(vim.fn.fnamemodify(self.filename, ":~:h")) .. "/"
        end,
        hl = function()
            return { fg = "base04" }
        end,
    }
end

local FileName = {
    flexible = 5,
    init = function(self)
        local name = vim.api.nvim_buf_get_name(0)
        self.filename = name ~= "" and name or "[No Name]"
        self.tail = self.filename ~= "[No Name]" and vim.fn.fnamemodify(name, ":t") or self.filename
    end,
    { dir_child(function(dir)
        return dir
    end), FileNameTail, FileNameFlags },
    { dir_child(vim.fn.pathshorten), FileNameTail, FileNameFlags },
    { FileNameTail, FileNameFlags },
}

-- Filetype icon for the filename chip. It carries its own init because it
-- sits BEFORE the flexible filename in the chip and component inits run in
-- child order; the empty-icon case is a nil provider (conditions run
-- before init, so a condition could not see the icon it would test).
local FileIcon = {
    init = function(self)
        self.icon, self.icon_hl = filetype_icon(0)
    end,
    provider = function(self)
        return self.icon ~= "" and self.icon or nil
    end,
    hl = function(self)
        return self.icon_hl
    end,
}

-- Branch + colored counts from the buffer-local dict gitsigns maintains.
-- Branch chip content: icon + head name, hidden when the dict has no head.
-- The condition reads the buffer dict directly (self-free) so the chip
-- factory can hoist it and hide gap+chip together.
local GitBranch = {
    condition = function()
        if not conditions.is_git_repo() then
            return false
        end
        local dict = vim.b.gitsigns_status_dict
        return dict ~= nil and dict.head ~= nil and dict.head ~= ""
    end,
    provider = function()
        return "\u{E0A0} " .. vim.b.gitsigns_status_dict.head
    end,
    hl = function()
        return { fg = "base05" }
    end,
}

-- Diff-stats chip content: +n ~n -n, each colored, zero counts omitted
-- individually; the whole chip hides on a clean tree. Condition is
-- self-free (reads the dict directly) for chip-factory hoisting.
local GitStats = {
    condition = function()
        if not conditions.is_git_repo() then
            return false
        end
        local dict = vim.b.gitsigns_status_dict
        return dict ~= nil and ((dict.added or 0) + (dict.changed or 0) + (dict.removed or 0)) > 0
    end,
    init = function(self)
        local dict = vim.b.gitsigns_status_dict
        self.added = (dict and dict.added) or 0
        self.changed = (dict and dict.changed) or 0
        self.removed = (dict and dict.removed) or 0
    end,
    {
        condition = function(self)
            return self.added > 0
        end,
        provider = function(self)
            return "+" .. self.added
        end,
        hl = function()
            return { fg = "base0B" }
        end,
    },
    {
        condition = function(self)
            return self.changed > 0
        end,
        provider = function(self)
            return " ~" .. self.changed
        end,
        hl = function()
            return { fg = "base0A" }
        end,
    },
    {
        condition = function(self)
            return self.removed > 0
        end,
        provider = function(self)
            return " -" .. self.removed
        end,
        hl = function()
            return { fg = "base08" }
        end,
    },
}

-- E/W/H counts, each prefixed with its icon (\u escapes: the literal PUA
-- glyphs are stripped by the edit pipeline). First item carries no leading
-- space; later items separate themselves (same convention as GitStats).
local Diagnostics = {
    condition = conditions.has_diagnostics,
    init = function(self)
        local counts = vim.diagnostic.count(0)
        self.errors = counts[vim.diagnostic.severity.ERROR] or 0
        self.warns = counts[vim.diagnostic.severity.WARN] or 0
        self.hints = (counts[vim.diagnostic.severity.HINT] or 0) + (counts[vim.diagnostic.severity.INFO] or 0)
    end,
    {
        provider = function(self)
            return self.errors > 0 and ("\u{F057} " .. self.errors) or ""
        end,
        hl = function()
            return { fg = "base08" }
        end,
    },
    {
        provider = function(self)
            return self.warns > 0 and (" \u{F071} " .. self.warns) or ""
        end,
        hl = function()
            return { fg = "base09" }
        end,
    },
    {
        provider = function(self)
            return self.hints > 0 and (" \u{F0375} " .. self.hints) or ""
        end,
        hl = function()
            return { fg = "base0D" }
        end,
    },
}

local Lsp = {
    condition = conditions.lsp_attached,
    provider = function()
        -- 0.12: get_clients is correct (heirline's own lsp_attached uses it);
        -- 0.13 renames it to vim.lsp.clients -- a one-line swap when that lands.
        local names = {}
        for _, client in ipairs(vim.lsp.get_clients({ bufnr = 0 })) do
            names[#names + 1] = client.name
        end
        return "\u{F233} " .. table.concat(names, "·")
    end,
    hl = function()
        return { fg = "base0C" }
    end,
}

-- Row:col plus scroll percent through the buffer. The percent sign must be
-- emitted as %% because providers are embedded raw into the statusline
-- format string, where a bare "% " is an illegal item (E539).
local Position = {
    provider = function()
        local cursor = vim.api.nvim_win_get_cursor(0)
        local total = math.max(vim.api.nvim_buf_line_count(0), 1)
        local percent = math.floor((cursor[1] / total) * 100)
        return ("\u{F041} %d:%d %d%%%%"):format(cursor[1], cursor[2] + 1, percent)
    end,
    hl = function()
        return { fg = "base04" }
    end,
}

-- Transient center column (cookbook.md:1246-1260): the search count only
-- renders while hlsearch is live; recompute is forced so the numbers track
-- the pattern under the cursor.
local SearchCount = {
    condition = function()
        return vim.v.hlsearch == 1
    end,
    init = function(self)
        local ok, search = pcall(vim.fn.searchcount, { recompute = 1 })
        if ok and type(search) == "table" and search.total then
            self.search = search
        end
    end,
    provider = function(self)
        if not self.search then
            return nil
        end
        return ("[%d/%d]"):format(self.search.current, math.min(self.search.total, self.search.maxcount or 99))
    end,
    hl = function()
        return { fg = "base0D" }
    end,
}

-- Macro-recording indicator (cookbook.md:1264-1280); the leading space
-- separates it from SearchCount when both render mid-line.
local MacroRec = {
    condition = function()
        return vim.fn.reg_recording() ~= ""
    end,
    update = {
        "RecordingEnter",
        "RecordingLeave",
    },
    provider = function()
        return "\u{25CF} rec @" .. vim.fn.reg_recording()
    end,
    hl = function()
        return { fg = "base08", bold = true }
    end,
}

local Spring = { provider = "%=" }

-- ╆─ Tabline: bufferline + tabpage list (phase 2) ─────────────────────
-- Buffer cells MUST read buffer state through self.bufnr -- the tabline
-- renders every listed buffer and plain vim.bo would read the *current*
-- buffer for each cell (cookbook.md:1912-1913). self.is_active is set by
-- make_buflist by comparing against vim.g.actual_curbuf (utils.lua:262),
-- never nvim_get_current_buf(): during tabline drawing the "current"
-- buffer belongs to whichever window Vim is redrawing for.

-- Shared emphasis: base0D fill with a luminance-contrasted fg. The fg is
-- computed from the raw hex, so it cannot be a color alias; the bg stays
-- an alias and resolves through loaded_colors at hl-name time.
-- bufferline.nvim's shading model (lua/bufferline/colors.lua:15-30): darken
-- a hex by a percentage of each channel, clamped.
local function shade(hexcolor, pct)
    local function channel(s)
        local v = math.floor(tonumber(s, 16) * (100 + pct) / 100 + 0.5)
        return string.format("%02x", math.min(255, math.max(0, v)))
    end
    return "#" .. channel(hexcolor:sub(2, 3)) .. channel(hexcolor:sub(4, 5)) .. channel(hexcolor:sub(6, 7))
end

-- Tabline shades derived from the editor bg exactly like bufferline.nvim
-- (config.lua:259-276): fill -45, inactive blocks -25, visible -8, and the
-- active block IS the editor bg (the raised-tab-connected-to-editor look).
-- Recomputed at eval time so tinted-nvim theme switches re-derive them.
local function tabline_shades()
    local editor = c("base00")
    return {
        editor = editor,
        visible = shade(editor, -8),
        inactive = shade(editor, -25),
        fill = shade(editor, -45),
    }
end

-- Pick-mode letter overlay (cookbook.md:2102-2140): hidden unless the
-- keymap below flips _show_picker on the buflist root; init then claims
-- the first letter of each buffer name not already taken.
local TablinePicker = {
    condition = function(self)
        return self._show_picker
    end,
    init = function(self)
        local bufname = vim.fn.fnamemodify(vim.api.nvim_buf_get_name(self.bufnr), ":t")
        local label = bufname:sub(1, 1)
        local i = 2
        while self._picker_labels[label] do
            if i > #bufname then
                break
            end
            label = bufname:sub(i, i)
            i = i + 1
        end
        self._picker_labels[label] = self.bufnr
        self.label = label
    end,
    provider = function(self)
        return self.label .. " "
    end,
    hl = function()
        return { fg = "base08", bold = true }
    end,
}

-- One buffer cell, styled after bufferline.nvim's default preset:
--   active  = editor bg, base05 fg, bold+italic, accent indicator bar
--   visible = shade(editor,-8), comment fg
--   inactive = shade(editor,-25), comment fg
--   suffix = modified dot (replaces the close x, like bufferline)
--   separator = fill-colored notch (thin style: U+258F after focused
--   blocks, U+2595 after inactive ones) cut into the block's own bg
local BufferBlock = {
    init = function(self)
        self.filename = vim.api.nvim_buf_get_name(self.bufnr)
        self.icon, self.icon_hl = filetype_icon(self.bufnr)
        local s = tabline_shades()
        if self.is_active then
            self.block_hl = { bg = s.editor, fg = "base05", bold = true, italic = true }
        elseif self.is_visible then
            self.block_hl = { bg = s.visible, fg = "base03" }
        else
            self.block_hl = { bg = s.inactive, fg = "base03" }
        end
    end,
    hl = function(self)
        return self.block_hl
    end,
    on_click = {
        -- Left click selects, middle ("m") button closes via the API
        -- bdelete inside vim.schedule (cookbook.md:1982-1996), with a
        -- redrawtabline chaser so paging recomputes after the delete
        -- (cookbook.md:2013-2017).
        callback = function(_, minwid, _, button)
            if button == "m" then
                vim.schedule(function()
                    vim.api.nvim_buf_delete(minwid, { force = false })
                    vim.cmd("redrawtabline")
                end)
            else
                vim.api.nvim_win_set_buf(0, minwid)
            end
        end,
        minwid = function(self)
            return self.bufnr
        end,
        name = "heirline_tabline_buffer_callback",
    },
    TablinePicker,
    {
        condition = function(self)
            return self.is_active
        end,
        provider = "\u{258F}",
        hl = function()
            return { fg = "base0D" }
        end,
    },
    { provider = " " },
    {
        condition = function(self)
            return self.icon ~= ""
        end,
        provider = function(self)
            return self.icon .. " "
        end,
        hl = function(self)
            return self.icon_hl
        end,
    },
    {
        provider = function(self)
            local name = self.filename
            return (name == "" and "[No Name]" or vim.fn.fnamemodify(name, ":t")) .. " "
        end,
    },
    {
        condition = function(self)
            return vim.api.nvim_get_option_value("modified", { buf = self.bufnr })
        end,
        provider = "\u{25CF} ",
        hl = function()
            return { fg = "base0B" }
        end,
    },
    {
        condition = function(self)
            return not vim.api.nvim_get_option_value("modified", { buf = self.bufnr })
        end,
        provider = "\u{F00D} ",
        hl = function()
            return { fg = "base04" }
        end,
        on_click = {
            callback = function(_, minwid)
                vim.schedule(function()
                    vim.api.nvim_buf_delete(minwid, { force = false })
                    vim.cmd("redrawtabline")
                end)
            end,
            minwid = function(self)
                return self.bufnr
            end,
            name = "heirline_tabline_close_callback",
        },
    },
    {
        provider = function(self)
            return (self.is_active or self.is_visible) and "\u{258F}" or "\u{2595}"
        end,
        hl = function()
            return { fg = tabline_shades().fill }
        end,
    },
}

-- Paging markers for when the buffer row overflows; make_buflist grafts
-- its own on_click paging handlers onto these (utils.lua:199-215), so
-- never set on_click here. Chevrons are PUA glyphs written as \u{}
-- escapes -- literal PUA characters do not survive the edit pipeline.
local BufferLine = utils.make_buflist(
    BufferBlock,
    { provider = "\u{F053} ", hl = { fg = "base04" } },
    { provider = "\u{F054} ", hl = { fg = "base04" } }
)

-- Left-sidebar offset (cookbook.md:2185-2219). No persistent sidebar in
-- this config (oil is transient), so SIDEBARS is empty and this never
-- renders; adding one later is a single entry, e.g.
-- { filetype = "neo-tree", title = "Explorer" }.
local SIDEBARS = {}

local TablineOffset = {
    condition = function(self)
        local win = vim.api.nvim_tabpage_list_wins(0)[1]
        local bufnr = vim.api.nvim_win_get_buf(win)
        self.winid = win
        local ft = vim.bo[bufnr].filetype
        for _, sidebar in ipairs(SIDEBARS) do
            if ft == sidebar.filetype then
                self.title = sidebar.title
                return true
            end
        end
        return false
    end,
    provider = function(self)
        local width = vim.api.nvim_win_get_width(self.winid)
        local pad = math.max(0, math.floor((width - vim.api.nvim_strwidth(self.title)) / 2))
        return string.rep(" ", pad) .. self.title .. string.rep(" ", pad)
    end,
    hl = function(self)
        if vim.api.nvim_get_current_win() == self.winid then
            return "TabLineSel"
        end
        return "TabLine"
    end,
}

-- Real tabpages, right-aligned behind a spring (cookbook.md:2156-2182).
-- "%{tabnr}T ... %T" makes the item natively clickable; %999X is the
-- builtin close button. make_tablist takes only the component -- the old
-- min_tab/close args were removed upstream. Shown only with 2+ tabpages.
local TabpageBlock = {
    provider = function(self)
        return "%" .. self.tabnr .. "T " .. self.tabnr .. " %T"
    end,
    hl = function(self)
        local s = tabline_shades()
        if self.is_active then
            return { bg = s.editor, fg = "base0D", bold = true }
        end
        return { fg = "base03" }
    end,
}

local TabPages = {
    condition = function()
        return #vim.api.nvim_list_tabpages() >= 2
    end,
    { provider = "%=" },
    utils.make_tablist(TabpageBlock),
    {
        provider = "%999X\u{F00D} %X",
        hl = { fg = "base04" },
    },
}

local TabLine = {
    -- Fill = the darkest shade (bufferline's separator_background_color),
    -- on which inactive (-25) and visible (-8) blocks climb toward the
    -- active block at full editor bg.
    hl = function()
        return { bg = tabline_shades().fill }
    end,
    TablineOffset,
    BufferLine,
    TabPages,
}

-- showtabline is OURS to drive: heirline only sets vim.o.tabline
-- (init.lua:95) and never touches the visibility option. Dynamic per
-- cookbook.md:2045-2091 -- the tabline appears only when more than one
-- listed buffer or tabpage exists, so single-file sessions stay clean.
local function listed_buffers()
    return vim.tbl_filter(function(bufnr)
        return vim.api.nvim_get_option_value("buflisted", { buf = bufnr })
    end, vim.api.nvim_list_bufs())
end

local function refresh_showtabline()
    local wanted = #listed_buffers() > 1 or #vim.api.nvim_list_tabpages() > 1
    vim.o.showtabline = wanted and 2 or 0
end

refresh_showtabline()

vim.api.nvim_create_augroup("Heirline_tabline", { clear = true })
vim.api.nvim_create_autocmd({ "VimEnter", "UIEnter", "BufAdd", "BufDelete", "TabNew", "TabClosed" }, {
    group = "Heirline_tabline",
    desc = "heirline: show tabline only with multiple listed buffers or tabpages",
    callback = function()
        vim.schedule(refresh_showtabline)
    end,
})

-- Transient buffers (bufhidden=wipe/delete, e.g. oil scratch) stay out
-- of the bufferline (cookbook.md:2235, lua form).
vim.api.nvim_create_autocmd("FileType", {
    group = "Heirline_tabline",
    desc = "heirline: unlist transient (bufhidden=wipe/delete) buffers",
    callback = function(args)
        if vim.tbl_contains({ "wipe", "delete" }, vim.bo[args.buf].bufhidden) then
            vim.bo[args.buf].buflisted = false
        end
    end,
})

-- Buffer pick mode (cookbook.md:2127-2140): overlay a letter on every
-- buffer cell, read one keypress, jump to that buffer. The heirline
-- machinery lives in this spec (same ownership rule as oil/gitsigns
-- maps); <leader>bp verified free in lua/config/keymaps.lua.
vim.keymap.set("n", "<leader>bp", function()
    local tabline = require("heirline").tabline
    local buflist = tabline and tabline._buflist[1]
    if not buflist then
        return
    end
    buflist._picker_labels = {}
    buflist._show_picker = true
    vim.cmd("redrawtabline")
    local char = vim.fn.getcharstr()
    local bufnr = buflist._picker_labels[char]
    if bufnr then
        vim.api.nvim_win_set_buf(0, bufnr)
    end
    buflist._show_picker = false
    vim.cmd("redrawtabline")
end, { desc = "Buffer pick" })

-- Transparent bar: bg = "NONE" passes through heirline's hex()/get_color()
-- untouched (highlights.lua:66-80), so only the chips paint — gaps, springs
-- and the trailing region show the editor background.
-- Zone order: mode·position || file·git-stats || branch·diag·lsp·search·macro.
local StatusLine = {
    hl = { bg = "NONE" },
    ViMode,
    chip("base01", Position),
    Spring,
    chip("base01", FileIcon, FileName),
    chip("base01", GitStats),
    Spring,
    chip("base01", GitBranch),
    chip("base01", Diagnostics),
    chip("base01", Lsp),
    chip("base01", SearchCount),
    chip("base01", MacroRec),
}

-- Global statusline is a UI concern owned here, not by config/options.lua.
vim.o.laststatus = 3

-- Table-only setup (init.lua:72-102): one call drives statusline and
-- tabline (winbar was replaced by the incline badge, specs/incline.lua).
-- statuscolumn is deliberately never passed: snacks owns it
-- and setup() would overwrite it (init.lua:98-101).
require("heirline").setup({
    statusline = StatusLine,
    tabline = TabLine,
    opts = {
        -- palette registered as color aliases (highlights.lua:74-80) so hl
        -- fields above may use slots like fg = "base05"; reloaded on theme
        -- switches via on_colorscheme below.
        colors = palette,
    },
})

-- Canonical theme refresh (utils.lua:355-373): on_colorscheme resets the
-- generated-highlight cache, reloads the alias table, and invalidates
-- per-window _win_cache -- none of which a bare redrawstatus ever did.
vim.api.nvim_create_augroup("Heirline_colors", { clear = true })
vim.api.nvim_create_autocmd("ColorScheme", {
    group = "Heirline_colors",
    desc = "heirline: reload palette aliases and reset hl caches after theme switch",
    callback = function()
        refresh_palette()
        utils.on_colorscheme(palette)
        -- tinted-nvim watch-based switching may not trigger a full UI redraw
        vim.cmd("redrawstatus")
        vim.cmd("redrawtabline")
    end,
})
