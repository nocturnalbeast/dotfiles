-- Diagnostics presentation + quickfix map (plan §Keymaps "Diagnostics").
-- ]d / [d jumps are 0.12 natives and are intentionally not remapped.

vim.diagnostic.config({
    update_in_insert = false,
    severity_sort = true,
    float = { border = "rounded", source = "if_many" },
    underline = { severity = vim.diagnostic.severity.ERROR },
    virtual_text = true,
    virtual_lines = false,
    jump = { float = true },
})

vim.keymap.set("n", "<leader>q", vim.diagnostic.setqflist, { desc = "Open diagnostics in quickfix list" })
