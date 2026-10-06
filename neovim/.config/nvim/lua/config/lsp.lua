-- LSP activation + buffer-local LSP behaviour.
--
-- Ordering note: this module runs during init BEFORE the specs/ modules
-- (specs/blink.lua included), so blink's completion capabilities are
-- registered at the end of specs/blink.lua, not here. vim.lsp.enable()
-- only marks servers active; actual attachment happens on FileType events,
-- after init has completed.

local enabled_servers = { "basedpyright", "ruff", "lua_ls", "yamlls", "jsonls", "taplo" }

-- Activation is owned by this explicit list. mason-lspconfig has
-- automatic_enable = false (see specs/lsp.lua) so it never double-manages.
vim.lsp.enable(enabled_servers)

-- Rename-then-save: after a successful `textDocument/rename`, write all
-- buffers so renamed buffers are not left modified (neobean harvest).
--
-- DECISION (deviation from the plan's `LspRequest` autocmd): on nvim 0.12.5
-- the LspRequest payload is `data.request = { type = "pending"|"complete"|
-- "cancel", bufnr, method }` — it carries no error/result info — and its
-- "complete" event is queued (schedule_wrap in rpc.lua) BEFORE the rename
-- handler applies the workspace edits, so an autocmd there would `wall`
-- stale buffers. Post-hooking the rename handler guarantees the write runs
-- after util.apply_workspace_edit, only on a successful rename.
local rename_handler = vim.lsp.handlers["textDocument/rename"]
vim.lsp.handlers["textDocument/rename"] = function(err, result, ctx, config)
    local ret = { rename_handler(err, result, ctx, config) }
    if not err and result ~= nil then
        vim.cmd("silent! wall")
    end
    return table.unpack(ret)
end

local highlight_augroup = vim.api.nvim_create_augroup("unified-lsp-highlight", { clear = false })
local detach_augroup = vim.api.nvim_create_augroup("unified-lsp-detach", { clear = false })

vim.api.nvim_create_autocmd("LspAttach", {
    group = vim.api.nvim_create_augroup("unified-lsp-attach", { clear = true }),
    callback = function(event)
        local client = vim.lsp.get_client_by_id(event.data.client_id)
        if not client then
            return
        end

        if client:supports_method("textDocument/documentHighlight", event.buf) then
            vim.api.nvim_create_autocmd({ "CursorHold", "CursorHoldI" }, {
                buffer = event.buf,
                group = highlight_augroup,
                callback = vim.lsp.buf.document_highlight,
            })
            vim.api.nvim_create_autocmd({ "CursorMoved", "CursorMovedI" }, {
                buffer = event.buf,
                group = highlight_augroup,
                callback = vim.lsp.buf.clear_references,
            })
            vim.api.nvim_create_autocmd("LspDetach", {
                buffer = event.buf,
                group = detach_augroup,
                callback = function(ev)
                    vim.lsp.buf.clear_references()
                    vim.api.nvim_clear_autocmds({ group = highlight_augroup, buffer = ev.buf })
                end,
            })
        end

        if client:supports_method("textDocument/inlayHint", event.buf) then
            vim.keymap.set("n", "<leader>th", function()
                vim.lsp.inlay_hint.enable(not vim.lsp.inlay_hint.is_enabled({ bufnr = event.buf }))
            end, {
                buffer = event.buf,
                desc = "[T]oggle Inlay [H]ints",
            })
        end

        -- Symbol breadcrumbs for the incline badge. navic.attach re-checks
        -- documentSymbolProvider itself, but the guard avoids its error
        -- notify path on servers without symbols (e.g. ruff).
        if client:supports_method("textDocument/documentSymbol", event.buf) then
            local ok, navic = pcall(require, "nvim-navic")
            if ok then
                navic.attach(client, event.buf)
            end
        end
    end,
})
