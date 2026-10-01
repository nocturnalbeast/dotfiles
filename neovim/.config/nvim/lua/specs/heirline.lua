-- heirline.nvim statusline — fresh build porting rev3 concepts:
-- luminance-contrast mode colors, width-adaptive filename, git branch via
-- gitsigns status dict, diagnostics counts, LSP server names, position.
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

local ViMode = {
    init = function(self)
        self.mode = vim.fn.mode(1)
        local slot = slot_by_mode[self.mode] or slot_by_mode[self.mode:sub(1, 1)] or "base0D"
        self.mode_bg = c(slot)
        self.mode_fg = contrast_fg(self.mode_bg, c("base00"), c("base07"))
        self.label = label_by_mode[self.mode] or label_by_mode[self.mode:sub(1, 1)] or self.mode:upper()
    end,
    provider = function(self)
        return " " .. self.label .. " "
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
        flags[#flags + 1] = ""
    end
    return table.concat(flags, " ")
end

-- Progressive shortening as the window narrows: full path → pathshorten →
-- basename. Modern flexible API (statusline.lua:344): the parent carries
-- `flexible = <priority>`; child 1 renders by default and, when the
-- statusline overflows winwidth, next_child() walks toward the last child.
local FileName = {
    flexible = 5,
    init = function(self)
        local name = vim.api.nvim_buf_get_name(0)
        self.filename = name ~= "" and name or "[No Name]"
    end,
    {
        provider = function(self)
            return " " .. vim.fn.fnamemodify(self.filename, ":~") .. " " .. file_flags() .. " "
        end,
    },
    {
        provider = function(self)
            return " " .. vim.fn.pathshorten(vim.fn.fnamemodify(self.filename, ":~")) .. " " .. file_flags() .. " "
        end,
    },
    {
        provider = function(self)
            return " " .. vim.fn.fnamemodify(self.filename, ":t") .. " " .. file_flags() .. " "
        end,
    },
    hl = function()
        return { fg = c("base05"), bold = true }
    end,
}

-- Branch + changed count from the buffer-local dict gitsigns maintains.
local Git = {
    condition = conditions.is_git_repo,
    init = function(self)
        local dict = vim.b.gitsigns_status_dict
        self.head = dict and dict.head or nil
        if self.head then
            self.changed = (dict.added or 0) + (dict.removed or 0) + (dict.changed or 0)
        end
    end,
    provider = function(self)
        if not self.head or self.head == "" then
            return ""
        end
        return "  " .. self.head .. (self.changed > 0 and (" ~" .. self.changed) or "") .. " "
    end,
    hl = function()
        return { fg = c("base0E") }
    end,
}

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
            return self.errors > 0 and (" " .. self.errors) or ""
        end,
        hl = function()
            return { fg = c("base08") }
        end,
    },
    {
        provider = function(self)
            return self.warns > 0 and ("  " .. self.warns) or ""
        end,
        hl = function()
            return { fg = c("base09") }
        end,
    },
    {
        provider = function(self)
            return self.hints > 0 and (" 󰌵 " .. self.hints) or ""
        end,
        hl = function()
            return { fg = c("base0D") }
        end,
    },
}

local Lsp = {
    condition = conditions.lsp_attached,
    provider = function()
        local names = {}
        for _, client in ipairs(vim.lsp.get_clients({ bufnr = 0 })) do
            names[#names + 1] = client.name
        end
        return "  " .. table.concat(names, "·") .. " "
    end,
    hl = function()
        return { fg = c("base0C") }
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
        return (" %d:%d %d%%%% "):format(cursor[1], cursor[2] + 1, percent)
    end,
    hl = function()
        return { fg = c("base04") }
    end,
}

local Spring = { provider = "%=" }

local StatusLine = {
    hl = function()
        if conditions.is_active() then
            return utils.get_highlight("StatusLine")
        end
        return utils.get_highlight("StatusLineNC")
    end,
    ViMode,
    Git,
    FileName,
    Spring,
    Diagnostics,
    Lsp,
    Position,
}

-- Global statusline is a UI concern owned here, not by config/options.lua.
vim.o.laststatus = 3

vim.api.nvim_create_autocmd("ColorScheme", {
    desc = "heirline: re-derive palette-contrast colors after theme switch",
    callback = function()
        refresh_palette()
        vim.cmd("redrawstatus")
    end,
})

require("heirline").setup({ statusline = StatusLine })
