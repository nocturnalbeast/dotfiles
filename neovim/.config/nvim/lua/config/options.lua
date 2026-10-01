-- Global options. Base harvested from the old config's settings.lua,
-- plus the additions agreed in the nvim-unified plan.
local o = vim.o
local opt = vim.opt

o.number = true

o.mouse = "a"

o.showmode = false

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
