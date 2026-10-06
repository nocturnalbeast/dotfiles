-- Plugin roster for nvim-unified, installed with the built-in vim.pack
-- (see :help vim.pack). The lockfile (nvim-pack-lock.json) is generated on
-- first boot and committed alongside the config to pin exact revisions.

-- Most plugins are hosted on GitHub, so this helper keeps the specs short.
---@param repo string
---@return string
local function gh(repo)
    return "https://github.com/" .. repo
end

-- One add call, ordered to match the plan's approved roster (23 entries).
-- Configure each plugin in its own module under lua/specs/, not here.
vim.pack.add({
    { src = gh("folke/snacks.nvim") }, -- picker, dashboard, notifier, bigfile, quickfile, statuscolumn, words
    { src = gh("Saghen/blink.cmp"), version = vim.version.range("1.*") }, -- completion, lua fuzzy impl (no build)
    { src = gh("rebelot/heirline.nvim") }, -- statusline
    { src = gh("folke/which-key.nvim"), version = vim.version.range("3.*") }, -- keymap hints and groups
    { src = gh("nvim-mini/mini.icons") }, -- icon provider, mocks nvim-web-devicons
    { src = gh("nvim-mini/mini.nvim") }, -- mini.ai + mini.surround only
    { src = gh("tinted-theming/tinted-nvim") }, -- colorscheme following tinty's current_scheme
    { src = gh("neovim/nvim-lspconfig") }, -- server config collection only, no setup() calls
    { src = gh("mason-org/mason.nvim"), version = vim.version.range("2.*") }, -- installs external tools
    { src = gh("mason-org/mason-lspconfig.nvim"), version = vim.version.range("2.*") }, -- mason to lspconfig bridge (repo renamed upstream: old mason-lspconfig URL 404s)
    { src = gh("WhoIsSethDaniel/mason-tool-installer.nvim") }, -- ensures stylua and friends are installed
    { src = gh("folke/lazydev.nvim") }, -- lua_ls completion when editing this config
    { src = gh("stevearc/conform.nvim") }, -- formatting: stylua, ruff-format, lsp fallback
    { src = gh("nvim-treesitter/nvim-treesitter"), branch = "main" }, -- parsers and highlighting, main-branch API
    { src = gh("nvim-treesitter/nvim-treesitter-textobjects"), branch = "main" }, -- select/move/swap maps
    { src = gh("stevearc/oil.nvim") }, -- buffer file manager, replaces a sidebar tree
    { src = gh("lewis6991/gitsigns.nvim") }, -- git signs and current-line blame
    { src = gh("folke/todo-comments.nvim") }, -- highlight and list todo/fixme comments
    { src = gh("NMAC427/guess-indent.nvim") }, -- detect buffer indentation on open
    { src = gh("obsidian-nvim/obsidian.nvim") }, -- note-taking workflow
    { src = gh("MeanderingProgrammer/render-markdown.nvim") }, -- rendered markdown preview
    { src = gh("HakonHarnes/img-clip.nvim") }, -- paste images into notes (avif pipeline)
    { src = gh("b0o/incline.nvim") }, -- floating per-window navigation badge
    { src = gh("SmiteshP/nvim-navic") }, -- LSP symbol breadcrumbs (feeds incline)
    { src = gh("rafamadriz/friendly-snippets") }, -- snippet data only, loaded by blink
})
