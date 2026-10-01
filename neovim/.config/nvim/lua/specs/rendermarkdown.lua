-- render-markdown.nvim — minimal setup; anti_conceal block is the README's
-- recommended core (icon tables elided). Conceal itself is owned by
-- ftplugin/markdown.lua (conceallevel=2), not by this spec.
require("render-markdown").setup({
    file_types = { "markdown" },
    anti_conceal = {
        enabled = true,
        ignore = {
            highlight = true,
            concealcursor = false,
            rendered = true,
        },
    },
})
