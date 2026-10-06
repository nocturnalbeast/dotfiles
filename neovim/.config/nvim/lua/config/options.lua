-- Global options. Base harvested from the old config's settings.lua,
-- plus the additions agreed in the nvim-unified plan.
local o = vim.o
local opt = vim.opt

o.number = true

o.mouse = "a"

o.showmode = false

-- No permanent command row; ":" and "/" float over the buffer when used.
-- Messages surface via snacks.notifier, mode/position via the statusline.
o.cmdheight = 0

-- Nerd-font PUA glyphs render double-width in the terminal while nvim's
-- default width math counts them as one cell, shifting everything after
-- them. Declaring them via setcellwidths() makes chip padding, mode-text
-- centering and dashboard centering math honest. Keep this list in sync
-- with the \u{XXXX} escapes used in lua/specs/ (grep -rohE '\\u\{[0-9A-Fa-f]+\}').
-- Runtime glyphs served by mini.icons are not enumerable here; extend with
-- ranges (e.g. {0xF0500, 0xF2BFF, 2} for nf-md) if those misalign for you.
vim.fn.setcellwidths({
    { 0xE0A0, 0xE7C5, 2 }, --  branch,  vim logo (modes)
    { 0xF002, 0xF054, 2 }, --  search,  file,  clock,  pin,  chevrons,  error,  warn
    { 0xF057, 0xF057, 2 },
    { 0xF071, 0xF071, 2 },
    { 0xF120, 0xF15C, 2 }, --  terminal,  rocket,  file,  file-o
    { 0xF233, 0xF233, 2 }, --  server (lsp)
    { 0xF246, 0xF246, 2 }, --  insert
    { 0xF423, 0xF423, 2 }, --  command
    { 0xF027C, 0xF027C, 2 }, -- 󰉼 replace
    { 0xF0375, 0xF0375, 2 }, -- 󰌵 hint
    { 0xF09A8, 0xF09A8, 2 }, -- 󰦨 visual
    { 0xF0FE6, 0xF0FE6, 2 }, -- 󰿦 v-block
})

-- Defer the clipboard so startup never waits on the clipboard provider.
vim.schedule(function()
    o.clipboard = "unnamedplus"
end)

o.breakindent = true

o.undofile = true

o.ignorecase = true
o.smartcase = true

o.signcolumn = "yes"

o.updatetime = 250

o.timeoutlen = 300

o.splitright = true
o.splitbelow = true

o.list = true
opt.listchars = { tab = "» ", trail = "·", nbsp = "␣" }

o.inccommand = "split"

o.cursorline = true

o.scrolloff = 10

o.confirm = true

-- Additions for nvim-unified
o.winborder = "rounded" -- rounded borders on floating windows
o.wildmode = "lastused,full" -- completion menu shows recents first
opt.iskeyword:append("-") -- treat dash-joined words as one keyword
