std = "luajit"
cache = true
quiet = 23.6

globals = {
    "awesome",
    "screen",
    "client",
    "mouse",
    "root",
    "drawin",
    "selection",
    "keygrabber",
    "mousegrabber",
    "package",
    "require",
}

ignore = {
    "212/self",
    "212/_M",
    "113/unreachable",
}

not_globals = {
    "awesome",
    "screen",
    "client",
    "mouse",
    "root",
}

files["**/bling/**/*.lua"] = {
    ignore = { "21", "21/_M", "11" },
}

files["**/lib/**/*.lua"] = {
    ignore = { "21", "21/_M", "11" },
}

files["rc.lua"] = {
    globals = { "rc" },
}
