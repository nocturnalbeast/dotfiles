-- conform.nvim - formatting: stylua (lua), ruff_format (python), LSP fallback.
-- The <leader>f format keymap lives in config/keymaps.lua, not here.
require("conform").setup({
    notify_on_error = false,
    format_on_save = function(bufnr)
        local disable_filetypes = { c = true, cpp = true }
        if disable_filetypes[vim.bo[bufnr].filetype] then
            return nil
        end
        return {
            timeout_ms = 500,
            lsp_format = "fallback",
            async = false,
        }
    end,
    formatters_by_ft = {
        lua = { "stylua" },
        python = { "ruff_format" },
    },
})
