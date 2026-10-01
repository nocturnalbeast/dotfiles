-- Autocommands harvested from nvim-modern-config (plan §Harvest map).
-- `vim.uv` is used because the deprecated libuv alias is removed in 0.12.

local augroup = vim.api.nvim_create_augroup
local autocmd = vim.api.nvim_create_autocmd

local general = augroup("GeneralSettings", { clear = true })
local filetype = augroup("FiletypeSettings", { clear = true })

autocmd("TextYankPost", {
    group = general,
    desc = "Highlight yanked region",
    callback = function()
        vim.hl.on_yank()
    end,
})

autocmd("VimResized", {
    group = general,
    desc = "Equalize splits when the window is resized",
    command = "tabdo wincmd =",
})

autocmd("BufReadPost", {
    group = general,
    desc = "Restore last edit position when reopening a file",
    callback = function()
        local mark = vim.api.nvim_buf_get_mark(0, '"')
        local lcount = vim.api.nvim_buf_line_count(0)
        if mark[1] > 0 and mark[1] <= lcount then
            pcall(vim.api.nvim_win_set_cursor, 0, mark)
        end
    end,
})

autocmd("BufWinEnter", {
    group = general,
    desc = "Disable auto-comment continuation",
    callback = function()
        vim.opt_local.formatoptions:remove({ "c", "r", "o" })
    end,
})

autocmd("BufWritePre", {
    group = general,
    desc = "Create missing parent directories on save",
    callback = function(event)
        if event.match:match("^%w%w+://") then
            return -- skip remote/URI buffers such as oil:// or fugitive://
        end
        local file = vim.uv.fs_realpath(event.match) or event.match
        local dir = vim.fn.fnamemodify(file, ":p:h")
        if vim.fn.isdirectory(dir) == 0 then
            vim.fn.mkdir(dir, "p")
        end
    end,
})

autocmd("FileType", {
    group = general,
    desc = "Close auxiliary windows with q",
    pattern = {
        "checkhealth",
        "help",
        "lspinfo",
        "man",
        "notify",
        "PlenaryTestPopup",
        "qf",
        "spectre_panel",
        "startuptime",
        "tsplayground",
    },
    callback = function(event)
        vim.bo[event.buf].buflisted = false
        vim.keymap.set("n", "q", "<cmd>close<cr>", {
            buffer = event.buf,
            silent = true,
            desc = "Close window",
        })
    end,
})

autocmd("BufWritePre", {
    group = general,
    desc = "Trim trailing whitespace",
    command = [[keeppatterns %s/\s\+$//e]],
})

autocmd("FocusGained", {
    group = general,
    desc = "Reload files changed outside of nvim",
    command = "checktime",
})

autocmd("FileType", {
    group = filetype,
    desc = "2-space indentation for markup",
    pattern = { "html", "css", "markdown" },
    callback = function()
        vim.opt_local.tabstop = 2
        vim.opt_local.shiftwidth = 2
        vim.opt_local.softtabstop = 2
    end,
})

autocmd({ "BufRead", "BufNewFile" }, {
    group = filetype,
    desc = "Treat .env* files as shell scripts",
    pattern = ".env*",
    command = "set filetype=sh",
})
