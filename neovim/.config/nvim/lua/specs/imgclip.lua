-- img-clip.nvim - AVIF paste pipeline. Harvested from linkarzu/neobean
-- img-clip.lua (skitty-mode branches dropped); format/quality hoisted to
-- constants, dir aligned to the obsidian attachments folder ('assets').
local IMG_FORMAT = "avif"
local IMG_QUALITY = 75

require("img-clip").setup({
    default = {
        use_absolute_path = false,
        relative_to_current_file = true,
        dir_path = "assets",
        prompt_for_file_name = false,
        file_name = "%y%m%d-%H%M%S",
        extension = IMG_FORMAT,
        process_cmd = string.format("convert - -quality %d %s:-", IMG_QUALITY, IMG_FORMAT),
    },
    filetypes = {
        markdown = {
            url_encode_path = true,
            template = "![Image](./$FILE_PATH)",
        },
    },
})
