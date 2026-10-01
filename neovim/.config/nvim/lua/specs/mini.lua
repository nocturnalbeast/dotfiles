-- mini.ai + mini.surround (matching the previous config's mappings), plus
-- mini.icons as the icon provider with the nvim-web-devicons shim.
require("mini.ai").setup({ n_lines = 500 })

require("mini.surround").setup()

require("mini.icons").setup()
require("mini.icons").mock_nvim_web_devicons()
