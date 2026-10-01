-- obsidian.nvim (obsidian-nvim fork) — decision 7/19: full notes workflow,
-- mac vault active + Linux placeholder. Harvested from
-- ~/desktop/nvim-mac/lua/kickstart/plugins/obsidian.lua.
-- No dependencies: obsidian's completion is an in-process LSP that blink
-- picks up natively.
--
-- Workspace.new drops specs whose path does not exist (workspace.lua:89) and
-- setup() hard-errors when zero survive (:239), so only existing dirs are
-- passed; on a machine with no vault at all, ~/vault is created.
local workspaces = {
    { name = "mac-vault", path = "~/Desktop/area-51" },
    { name = "linux-vault", path = "~/vault" },
}
local existing = {}
for _, ws in ipairs(workspaces) do
    if vim.uv.fs_stat(vim.fn.expand(ws.path)) then
        existing[#existing + 1] = ws
    end
end
if #existing == 0 then
    local fallback_ws = workspaces[2]
    vim.fn.mkdir(vim.fn.expand(fallback_ws.path), "p")
    existing[1] = fallback_ws
end

require("obsidian").setup({
    legacy_commands = false,
    workspaces = existing,
    templates = {
        -- Anchors template resolution at <vault>/templates, cwd-independent
        folder = "templates",
    },
    daily_notes = {
        folder = "journals",
        date_format = "YYYY-MM-DD",
        template = "daily-note.md",
        default_tags = {},
        workdays_only = false,
    },
    completion = {
        min_chars = 2,
    },
    attachments = {
        folder = "assets",
    },
})

vim.keymap.set("n", "<leader>ot", "<Cmd>Obsidian today<CR>", { desc = "[O]bsidian [T]oday journal" })
vim.keymap.set("n", "<leader>oo", "<Cmd>Obsidian quick_switch<CR>", { desc = "[O]bsidian quick switch" })
vim.keymap.set("n", "<leader>os", "<Cmd>Obsidian search<CR>", { desc = "[O]bsidian [S]earch" })
vim.keymap.set("n", "<leader>ob", "<Cmd>Obsidian backlinks<CR>", { desc = "[O]bsidian [B]acklinks" })
vim.keymap.set("n", "<leader>on", "<Cmd>Obsidian new<CR>", { desc = "[O]bsidian [N]ew note" })
