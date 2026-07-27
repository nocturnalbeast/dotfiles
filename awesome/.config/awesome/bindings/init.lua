local _M = {}

_M.global = require("bindings.global")
_M.client = require("bindings.client")
_M.mouse = require("bindings.mouse")

function _M.set()
    root.keys(_M.global.get())
    _M.mouse.set_global()
    _M.mouse.set_client()
end

return _M
