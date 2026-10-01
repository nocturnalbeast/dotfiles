-- Mason trio + lazydev. No require("lspconfig") anywhere: server configs
-- come from nvim-lspconfig's lsp/*.lua runtime files.
require("mason").setup()

-- Explicit vim.lsp.enable in config/lsp.lua owns activation; keep
-- mason-lspconfig from double-managing servers.
require("mason-lspconfig").setup({
    automatic_enable = false,
})

-- Mason package names (not lspconfig names).
require("mason-tool-installer").setup({
    ensure_installed = {
        "basedpyright",
        "ruff",
        "lua-language-server",
        "yaml-language-server",
        "json-lsp",
        "taplo",
        "stylua",
    },
})

-- lua_ls types for editing this config; workspace/library is lazydev's job.
require("lazydev").setup({
    library = {
        "lazydev",
        { path = "snacks.nvim", words = { "Snacks" } },
        { path = "${3rd}/luv/library", words = { "vim%.uv" } },
    },
})
