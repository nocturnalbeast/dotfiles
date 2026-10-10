-- oil.nvim - buffer-based file manager (decision 10: oil ONLY, no sidebar tree).
-- Harvested from ~/desktop/nvim-from-dots/lua/plugins/config/oil.lua; modernized:
--   · DiagnosticSign{Warn,Error,Ok} -> Diagnostic{Warn,Error,Ok} (0.10+ names)
--   · '-'/'_' maps call the lua API instead of :Oil ex commands
require("oil").setup({
    default_file_explorer = true,
    columns = {
        {
            "permissions",
            highlight = function(permission_str)
                local permission_hlgroups = {
                    ["-"] = "NonText",
                    r = "DiagnosticWarn",
                    w = "DiagnosticError",
                    x = "DiagnosticOk",
                }
                local hls = {}
                for i = 1, #permission_str do
                    local char = permission_str:sub(i, i)
                    table.insert(hls, { permission_hlgroups[char], i - 1, i })
                end
                return hls
            end,
        },
        { "size", highlight = "Special" },
        { "mtime", highlight = "Number" },
        { "icon", add_padding = true },
    },
    buf_options = {
        buflisted = false,
        bufhidden = "hide",
    },
    win_options = {
        wrap = false,
        signcolumn = "no",
        cursorcolumn = false,
        foldcolumn = "0",
        spell = false,
        list = false,
        conceallevel = 3,
        concealcursor = "nvic",
    },
    skip_confirm_for_simple_edits = false,
    prompt_save_on_select_new_entry = true,
    cleanup_delay_ms = 2000,
    -- Renamed upstream: lsp_rename_autosave → lsp_file_methods.autosave_changes
    -- ("unmodified" is a still-valid value, oil config.lua:284).
    lsp_file_methods = {
        autosave_changes = "unmodified",
    },
    constrain_cursor = "editable",
    delete_to_trash = true,
    use_default_keymaps = true,
    view_options = {
        show_hidden = false,
        is_hidden_file = function(name, _)
            return name ~= ".." and vim.startswith(name, ".")
        end,
        is_always_hidden = function(_, _)
            return false
        end,
        sort = {
            { "type", "asc" },
            { "name", "asc" },
        },
    },
})

vim.keymap.set("n", "-", function()
    require("oil").toggle_float()
end, { desc = "Oil: open parent directory (float)" })
vim.keymap.set("n", "_", function()
    require("oil").open(vim.uv.cwd())
end, { desc = "Oil: open cwd in buffer" })
