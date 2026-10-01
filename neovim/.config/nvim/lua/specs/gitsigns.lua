-- gitsigns.nvim — signs per current-config harvest; blame formatter harvested
-- from ~/desktop/nvim-from-dots/lua/plugins/config/gitsigns.lua L24-54.
-- FFI verdict (nvim 0.12.5, verified 2026-09-27): curwin_col_off via ffi FAILS
-- (pcall -> false), so width-aware truncation is dropped; formatter keeps the
-- "You" rename + relative dates with a gitsigns.util pcall guard.
require("gitsigns").setup({
    signs = {
        add = { text = "+" },
        change = { text = "~" },
        delete = { text = "_" },
        topdelete = { text = "‾" },
        changedelete = { text = "~" },
    },
    signcolumn = true,
    numhl = false,
    linehl = false,
    word_diff = false,
    sign_priority = 6,
    update_debounce = 100,
    max_file_length = 50000,
    current_line_blame = false,
    current_line_blame_opts = {
        virt_text = true,
        virt_text_pos = "right_align",
        delay = 500,
        ignore_whitespace = false,
    },
    -- Formatter opts table was removed upstream; get_relative_time
    -- (gitsigns/util.lua:202) is called directly, os.date as fallback.
    current_line_blame_formatter = function(name, blame_info)
        if blame_info.author == name then
            blame_info.author = "You"
        end
        if blame_info.author == "Not Committed Yet" then
            return { { " " .. blame_info.author, "GitSignsCurrentLineBlame" } }
        end
        local ok, relative = pcall(function()
            return require("gitsigns.util").get_relative_time(tonumber(blame_info.author_time))
        end)
        local date_time
        if ok then
            date_time = relative
        else
            date_time = os.date("%Y-%m-%d", tonumber(blame_info.author_time))
        end
        local text = string.format("%s, %s - %s", blame_info.author, date_time, blame_info.summary)
        return { { " " .. text, "GitSignsCurrentLineBlame" } }
    end,
    preview_config = {
        border = "single",
        style = "minimal",
        relative = "cursor",
        row = 0,
        col = 1,
    },
})

vim.keymap.set(
    "n",
    "<leader>hb",
    "<Cmd>Gitsigns toggle_current_line_blame<CR>",
    { desc = "Git: toggle current-line blame" }
)
