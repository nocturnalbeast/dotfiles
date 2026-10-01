-- Neovide GUI block — guarded so the whole module is inert outside Neovide.
if not vim.g.neovide then
    return
end

local g = vim.g

g.neovide_scale_factor = 1.0
g.neovide_fullscreen = false

-- Transparency + floating-window blur (harvested values).
g.neovide_transparency = 0.85
g.neovide_floating_blur_amount_x = 8.0
g.neovide_floating_blur_amount_y = 8.0

-- Cursor animation tuned fast.
g.neovide_cursor_animate_in_insert_mode = true
g.neovide_cursor_animation_length = 0.05
g.neovide_cursor_trail_length = 0.3
g.neovide_cursor_animate_command_line = true

g.neovide_scroll_animation_far_lines = 1
g.neovide_refresh_rate = 60
g.neovide_refresh_rate_idle = 30
g.neovide_hide_mouse_while_typing = true
g.neovide_confirm_quit = true
g.neovide_underline_stroke_scale = 1.0

vim.keymap.set("n", "<F11>", function()
    g.neovide_fullscreen = not g.neovide_fullscreen
end, { desc = "Neovide: toggle fullscreen" })

-- Keep underline/undercurl stroke weight matched to the font scale, which
-- otherwise stays fixed and looks thin when zoomed in.
vim.api.nvim_create_autocmd("User", {
    pattern = "NeovideScale",
    callback = function()
        g.neovide_underline_stroke_scale = g.neovide_scale_factor or 1.0
    end,
})

local function rescale(factor)
    g.neovide_scale_factor = factor
    vim.cmd("doautocmd User NeovideScale")
end

vim.keymap.set("n", "<C-=>", function()
    rescale((g.neovide_scale_factor or 1.0) + 0.1)
end, { desc = "Neovide: increase scale" })

vim.keymap.set("n", "<C-->", function()
    rescale(math.max(0.5, (g.neovide_scale_factor or 1.0) - 0.1))
end, { desc = "Neovide: decrease scale" })

vim.keymap.set("n", "<C-0>", function()
    rescale(1.0)
end, { desc = "Neovide: reset scale" })
