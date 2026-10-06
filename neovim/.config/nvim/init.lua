-- Neovim entry point (the unified config; see .sisyphus/plans/nvim-unified.md).
-- Targets nvim 0.12.x only. Plugin management is the built-in vim.pack;
-- there is deliberately no plugin-manager plugin.

-- Leader keys must be set before anything else maps with them.
vim.g.mapleader = " "
vim.g.maplocalleader = " "

-- Keep treesitter parsers fresh: whenever vim.pack installs or updates
-- nvim-treesitter, run :TSUpdate. Deferred via vim.schedule so it does
-- not fight the pack change still in flight.
vim.api.nvim_create_autocmd("PackChanged", {
    desc = "Run TSUpdate after nvim-treesitter install/update",
    callback = function(ev)
        local data = ev.data
        if data.spec.name ~= "nvim-treesitter" then
            return
        end
        if data.kind ~= "install" and data.kind ~= "update" then
            return
        end
        vim.schedule(function()
            -- Guard: on first install this fires before the plugin is
            -- sourced, and specs/treesitter.lua bootstraps parsers anyway.
            if vim.fn.exists(":TSUpdate") == 2 then
                vim.cmd("TSUpdate")
            end
        end)
    end,
})

-- Require a module, reporting failures instead of aborting startup: a
-- missing module should degrade, not brick, the editor. Failures are also
-- recorded in vim.g.unified_load_errors so headless validation can query
-- load status even when a notifier UI swallows vim.notify.
local load_errors = vim.g.unified_load_errors or {}
vim.g.unified_load_errors = load_errors
---@param mod string
local function safe_require(mod)
    local ok, err = pcall(require, mod)
    if not ok then
        load_errors[#load_errors + 1] = { module = mod, err = tostring(err) }
        vim.notify(("config: failed to load %s\n%s"):format(mod, err), vim.log.levels.ERROR)
    end
end

-- Load order is a dependency chain: core options first, config.pack adds
-- the plugins, then every spec configures plugins that are already present.
local modules = {
    "config.options",
    "config.keymaps",
    "config.autocmds",
    "config.diagnostics",
    "config.pack",
    "config.colorscheme",
    "config.lsp",
    "specs.blink",
    "specs.lsp",
    "specs.treesitter",
    "specs.snacks",
    "specs.whichkey",
    "specs.heirline",
    "specs.mini",
    "specs.oil",
    "specs.gitsigns",
    "specs.conform",
    "specs.obsidian",
    "specs.rendermarkdown",
    "specs.imgclip",
    "specs.todo",
    "specs.guessindent",
    "specs.incline",
    "specs.neovide",
}

for _, mod in ipairs(modules) do
    safe_require(mod)
end
