-- snacks.nvim — exactly the modules approved in plan decision #14:
-- picker, dashboard, notifier, bigfile, quickfile, statuscolumn, words.
-- Every other snacks module stays at its default (disabled).
-- Picker keymaps live in config/keymaps.lua, not here.

-- Captured as early as this module loads (near the start of the spec chain)
-- so the dashboard footer can report an approximate startup time.
local launch_ns = vim.uv.hrtime()

-- Count plugins managed by vim.pack.
local function pack_plugin_count()
    local dir = vim.fn.stdpath("data") .. "/site/pack/core/opt"
    local ok, entries = pcall(vim.fn.readdir, dir)
    if not ok or type(entries) ~= "table" then
        return 0
    end
    local count = 0
    for _, name in ipairs(entries) do
        if vim.fn.isdirectory(dir .. "/" .. name) == 1 then
            count = count + 1
        end
    end
    return count
end

-- Height-adaptive logo, restored from the nvim-modern harvest: three logo
-- files chosen by available window height (>50 big, >35 medium, else small).
local function logo_section()
    local win_height = vim.api.nvim_win_get_height(0)

    local dir = vim.fn.stdpath("config") .. "/assets/dashboard"
    local logo_path = dir .. "/logo-small"
    if win_height > 50 then
        logo_path = dir .. "/logo-big"
    elseif win_height > 35 then
        logo_path = dir .. "/logo-medium"
    end

    local content = "neovim"
    local logo_file = io.open(logo_path, "r")
    if logo_file then
        content = logo_file:read("*all")
        logo_file:close()
    end

    return {
        align = "center",
        text = content,
        padding = 2,
    }
end

-- Footer: nvim version + plugin count + startup ms (adapted from the
-- harvest's plugin_stats, minus the lazy.nvim-specific parts).
local function footer_section()
    local version = vim.version()
    local ms = math.floor((vim.uv.hrtime() - launch_ns) / 1e6)
    return {
        align = "center",
        text = {
            { ("nvim v%d.%d.%d"):format(version.major, version.minor, version.patch), hl = "Special" },
            { "   " .. pack_plugin_count() .. " plugins", hl = "Special" },
            { "   " .. ms .. " ms", hl = "Special" },
        },
        padding = 1,
    }
end

require("snacks").setup({
    picker = {
        enabled = true,
        -- Stock horizontal layout preset: input+list on the left, preview on
        -- the right. Only tweak: no backdrop dimming behind the picker.
        layout = { preset = "default" },
        layouts = {
            default = { layout = { backdrop = false } },
        },
    },

    dashboard = {
        enabled = true,
        -- Four visible actions; no hidden hotkey-only items.
        preset = {
            keys = {
                { icon = "", key = "f", desc = "Find File", action = ":lua Snacks.dashboard.pick('files')" },
                { icon = "", key = "r", desc = "Recent Files", action = ":lua Snacks.dashboard.pick('oldfiles')" },
                { icon = "", key = "g", desc = "Find Text", action = ":lua Snacks.dashboard.pick('live_grep')" },
                {
                    icon = "",
                    key = "c",
                    desc = "Config",
                    action = ":lua Snacks.dashboard.pick('files', { cwd = vim.fn.stdpath('config') })",
                },
            },
        },
        -- Section padding {bottom, top}: 1 blank after the header, 1 before the
        -- next section, no gap between entries. nf-seti icons render in every
        -- nerd font; MRU entries get filetype icons via mini.icons ("file").
        sections = {
            logo_section,
            { title = " Quick Actions", section = "keys", indent = 2, padding = { 1, 1 } },
            { title = " Recent Files", section = "recent_files", indent = 2, padding = { 1, 1 }, limit = 5 },
            footer_section,
        },
    },

    notifier = {
        enabled = true,
        timeout = 3000,
        width = { min = 40, max = 0.4 },
        sort = { "level", "added" },
        style = "compact",
        icons = {
            error = " ",
            warn = " ",
            info = " ",
            debug = " ",
            trace = " ",
        },
    },

    bigfile = {
        enabled = true,
        notify = true,
        size = 5 * 1024 * 1024,
        line_length = 1000,
        -- Degrade the editing environment for huge buffers (harvested setup).
        setup = function(ctx)
            if vim.fn.exists(":NoMatchParen") ~= 0 then
                vim.cmd([[NoMatchParen]])
            end
            vim.wo[ctx.buf].foldmethod = "manual"
            vim.wo[ctx.buf].statuscolumn = ""
            vim.wo[ctx.buf].conceallevel = 0
            vim.schedule(function()
                if vim.api.nvim_buf_is_valid(ctx.buf) then
                    vim.bo[ctx.buf].syntax = ctx.ft
                end
            end)
        end,
    },

    quickfile = {
        enabled = true,
    },

    statuscolumn = {
        enabled = true,
        -- Simple: signs (diagnostics etc.) + git markers left, folds right.
        -- Line numbers come from the 'number'/'relativenumber' options.
        left = { "sign", "git" },
        right = { "fold" },
    },

    words = {
        enabled = true,
        debounce = 200,
    },
})
