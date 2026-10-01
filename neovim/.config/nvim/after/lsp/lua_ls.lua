-- Minimal: workspace/library types are provided by lazydev (specs/lsp.lua).
return {
    settings = {
        Lua = {
            runtime = {
                version = "LuaJIT",
            },
            workspace = {
                checkThirdParty = false,
            },
        },
    },
}
