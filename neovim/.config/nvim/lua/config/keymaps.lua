-- Keymaps: base scheme from the live config + curated editing gems (plan §Keymaps).
-- Leader (<Space>) is set by init.lua; Snacks.picker is resolved at invocation
-- time, so load order of the plugin cannot break this module.

local map = vim.keymap.set

-- Pickers (snacks.picker, scheme harvested from the old telescope config)

---Defer Snacks.picker resolution to key-press time.
local function picker(name, opts)
    return function()
        Snacks.picker[name](opts)
    end
end

map("n", "<leader>sh", picker("help"), { desc = "[S]earch [H]elp" })
map("n", "<leader>sk", picker("keymaps"), { desc = "[S]earch [K]eymaps" })
map("n", "<leader>sf", picker("files"), { desc = "[S]earch [F]iles" })
map("n", "<leader>ss", picker("lsp_symbols"), { desc = "[S]earch document [S]ymbols" })
map({ "n", "v" }, "<leader>sw", picker("grep_word"), { desc = "[S]earch current [W]ord" })
map("n", "<leader>sg", picker("grep"), { desc = "[S]earch by [G]rep" })
map("n", "<leader>sd", picker("diagnostics"), { desc = "[S]earch [D]iagnostics" })
map("n", "<leader>sr", picker("resume"), { desc = "[S]earch [R]esume" })
map("n", "<leader>sc", picker("commands"), { desc = "[S]earch [C]ommands" })
map("n", "<leader>s.", picker("recent"), { desc = '[S]earch Recent Files ("." for repeat)' })
map("n", "<leader>s/", picker("grep_buffer"), { desc = "[S]earch [/] in current buffer" })
map("n", "<leader>sn", picker("files", { cwd = vim.fn.stdpath("config") }), { desc = "[S]earch [N]eovim files" })
map("n", "<leader><leader>", picker("buffers"), { desc = "[ ] Find existing buffers" })
map("n", "<leader>/", picker("lines"), { desc = "[/] Fuzzily search in current buffer" })

-- Windows, terminal, search (from the live config)

map("n", "<Esc>", "<cmd>nohlsearch<CR>", { desc = "Clear search highlighting" })
map("t", "<Esc><Esc>", "<C-\\><C-n>", { desc = "Exit terminal mode" })

map("n", "<C-h>", "<C-w><C-h>", { desc = "Move focus to the left window" })
map("n", "<C-l>", "<C-w><C-l>", { desc = "Move focus to the right window" })
map("n", "<C-j>", "<C-w><C-j>", { desc = "Move focus to the lower window" })
map("n", "<C-k>", "<C-w><C-k>", { desc = "Move focus to the upper window" })

-- Editing gems (harvested from nvim-modern-config)

map("n", "<A-j>", ":m .+1<CR>==", { desc = "Move line down" })
map("n", "<A-k>", ":m .-2<CR>==", { desc = "Move line up" })
map("v", "<A-j>", ":m '>+1<CR>gv=gv", { desc = "Move selection down" })
map("v", "<A-k>", ":m '<-2<CR>gv=gv", { desc = "Move selection up" })

map("n", "n", "nzzzv", { desc = "Next search result (centered)" })
map("n", "N", "Nzzzv", { desc = "Previous search result (centered)" })
map("n", "<C-d>", "<C-d>zz", { desc = "Half-page down (centered)" })
map("n", "<C-u>", "<C-u>zz", { desc = "Half-page up (centered)" })
map("n", "%", "%zz", { desc = "Jump to matching bracket (centered)" })

map("n", "J", "mzJ`z", { desc = "Join lines, keep cursor" })

map("v", "p", '"_dP', { desc = "Paste without yanking selection" })

map("v", "<", "<gv", { desc = "Unindent and keep selection" })
map("v", ">", ">gv", { desc = "Indent and keep selection" })

map("n", "j", "v:count == 0 ? 'gj' : 'j'", { expr = true, silent = true, desc = "Down (wrapped-line aware)" })
map("n", "k", "v:count == 0 ? 'gk' : 'k'", { expr = true, silent = true, desc = "Up (wrapped-line aware)" })
