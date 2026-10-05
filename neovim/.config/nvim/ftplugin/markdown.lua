-- Conceal for render-markdown + obsidian links. Spell/wrap/indent are owned
-- elsewhere (config/autocmds.lua handles per-ft settings).
-- conceallevel/concealcursor are window-local, so they need setlocal scope here.
vim.opt_local.conceallevel = 2
vim.opt_local.concealcursor = "nc"
