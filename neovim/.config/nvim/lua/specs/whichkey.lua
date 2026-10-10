-- which-key.nvim (v3) - group declarations only.
-- Actual mappings live in config/keymaps.lua; which-key picks up their
-- `desc` fields automatically. Kept deliberately simple: no icon rules.

local wk = require("which-key")

wk.setup({})

wk.add({
    { "<leader>", group = "Leader" },
    { "<leader>s", group = "Search" },
    { "<leader>o", group = "Obsidian" },
    { "<leader>f", desc = "Format" },
})
