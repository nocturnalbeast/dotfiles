-- Treesitter (main-branch API) + nvim-treesitter-textobjects (main-branch API).
-- Pattern harvested from kickstart@80743df via ~/desktop/nvim-mac/init.lua L937-979:
-- explicit parser list, guarded startup install, FileType autocmd attach,
-- indentexpr wiring when an indent query exists.
-- Textobjects API verified against the main-branch README (2026-09-27):
--   setup{ select = {...}, move = {...} } carries options only (no keymaps);
--   keymaps call .select/.move/.swap modules explicitly via vim.keymap.set.

local parsers = {
    "lua",
    "python",
    "markdown",
    "markdown_inline",
    "bash",
    "yaml",
    "json",
    "toml",
    "html",
    "css",
    "query",
    "vimdoc",
}

local nts = require("nvim-treesitter")

-- Install only what is missing; install() is async and tolerates fresh boots
-- (no parsers installed yet) without erroring.
local installed = nts.get_installed("parsers")
local missing = {}
for _, parser in ipairs(parsers) do
    if not vim.tbl_contains(installed, parser) then
        missing[#missing + 1] = parser
    end
end
if #missing > 0 then
    nts.install(missing)
end

---@param buf integer
---@param language string
local function treesitter_try_attach(buf, language)
    -- Check if a parser exists and load it
    if not vim.treesitter.language.add(language) then
        return
    end
    -- Enable syntax highlighting and other treesitter features
    vim.treesitter.start(buf, language)

    -- Enable treesitter-based indentation when an indent query exists;
    -- otherwise indentexpr falls back to Vim's built-in one.
    if vim.treesitter.query.get(language, "indents") ~= nil then
        vim.bo[buf].indentexpr = "v:lua.require'nvim-treesitter'.indentexpr()"
    end
end

local available_parsers = nts.get_available()
vim.api.nvim_create_autocmd("FileType", {
    callback = function(args)
        local buf, filetype = args.buf, args.match

        local language = vim.treesitter.language.get_lang(filetype)
        if not language then
            return
        end

        local installed_parsers = nts.get_installed("parsers")

        if vim.tbl_contains(installed_parsers, language) then
            -- Enable the parser if it is already installed
            treesitter_try_attach(buf, language)
        elseif vim.tbl_contains(available_parsers, language) then
            -- Auto-install and enable once installation completes
            nts.install(language):await(function()
                treesitter_try_attach(buf, language)
            end)
        else
            -- Try anyway: parser may exist locally without nvim-treesitter knowing it
            treesitter_try_attach(buf, language)
        end
    end,
})

-- ======================================================================
-- nvim-treesitter-textobjects (branch = main)
-- ======================================================================

-- The built-in python ftplugin defines buffer-local ]m/[m/]M/[M maps that
-- would shadow our global move maps; the README's per-ft opt-out:
vim.g.no_python_maps = true

require("nvim-treesitter-textobjects").setup({
    select = {
        -- Automatically jump forward to matching textobject, similar to targets.vim
        lookahead = true,
        selection_modes = {
            ["@parameter.outer"] = "v", -- charwise
            ["@function.outer"] = "V", -- linewise
        },
        include_surrounding_whitespace = false,
    },
    move = {
        -- whether to set jumps in the jumplist
        set_jumps = true,
    },
})

local select = require("nvim-treesitter-textobjects.select")
local move = require("nvim-treesitter-textobjects.move")
local swap = require("nvim-treesitter-textobjects.swap")

-- Select: aa/ia (argument), af/if (function), ac/ic (class)
local select_maps = {
    aa = "@parameter.outer",
    ia = "@parameter.inner",
    af = "@function.outer",
    ["if"] = "@function.inner",
    ac = "@class.outer",
    ic = "@class.inner",
}
for key, query in pairs(select_maps) do
    vim.keymap.set({ "x", "o" }, key, function()
        select.select_textobject(query, "textobjects")
    end, { desc = "TS select " .. query })
end

-- Move: ]m/[m (function start), ]M/[M (function end), ]]/[[ (class start)
local move_maps = {
    ["]m"] = { "goto_next_start", "@function.outer", "next function start" },
    ["[m"] = { "goto_previous_start", "@function.outer", "previous function start" },
    ["]M"] = { "goto_next_end", "@function.outer", "next function end" },
    ["[M"] = { "goto_previous_end", "@function.outer", "previous function end" },
    ["]]"] = { "goto_next_start", "@class.outer", "next class start" },
    ["[["] = { "goto_previous_start", "@class.outer", "previous class start" },
}
for key, spec in pairs(move_maps) do
    local fn, query, what = spec[1], spec[2], spec[3]
    vim.keymap.set({ "n", "x", "o" }, key, function()
        move[fn](query, "textobjects")
    end, { desc = "TS: " .. what })
end

-- Swap: <leader>a with next parameter, <leader>A with previous
vim.keymap.set("n", "<leader>a", function()
    swap.swap_next("@parameter.inner")
end, { desc = "TS swap parameter with next" })
vim.keymap.set("n", "<leader>A", function()
    swap.swap_previous("@parameter.inner")
end, { desc = "TS swap parameter with previous" })
