require("todo-comments").setup({
    signs = false,
})

-- signs=false only stops placement; the deferred _setup() still defines
-- signs from the keyword icons (todo-comments/config.lua:141), and those
-- glyphs are double-width per setcellwidths() in config/options.lua -
-- sign_define rejects double-width text (E239). The signs are never
-- placed, so stub the definer out before the deferred setup runs.
local ok_config, tc_config = pcall(require, "todo-comments.config")
if ok_config then
    tc_config.signs = function() end
end
