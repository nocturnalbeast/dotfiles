-- blink.cmp - completion engine (v1, lua fuzzy implementation: no build step).
--
-- Snippets use blink's native vim.snippet engine (preset = "default");
-- friendly-snippets (on the runtimepath via config/pack.lua) is loaded
-- automatically by the snippets source (`friendly_snippets = true` default).
-- Cmdline completion intentionally dropped (plan decision).
require("blink.cmp").setup({
    keymap = {
        preset = "default",
    },

    appearance = {
        nerd_font_variant = "mono",
    },

    completion = {
        documentation = {
            auto_show = false,
            auto_show_delay_ms = 500,
            -- window border: inherited from the global 'winborder' option
        },
    },

    sources = {
        default = { "lsp", "path", "snippets", "buffer" },
    },

    snippets = {
        preset = "default",
    },

    fuzzy = {
        implementation = "lua",
    },

    signature = {
        enabled = true,
    },
})

-- Registered here (after blink's setup) instead of in config/lsp.lua because
-- specs run after config/ modules during init, and config/lsp.lua must not
-- require blink.cmp before it is loaded. Applies to every server attach.
vim.lsp.config("*", { capabilities = require("blink.cmp").get_lsp_capabilities() })
