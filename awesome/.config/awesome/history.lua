-- Tag history stack with back/forward navigation.
-- Workspace and client focus history with older/newer traversal.

local awful = require("awful")
local capi = { client = client }

local history = {}

-- Per-screen data: screen_data[screen] = { stack={}, pos=0, client_pointer=nil, nav_depth=0 }
-- stack[1] = oldest, stack[N] = newest
-- pos points to the current tag in the stack
-- client_pointer: nil = not navigating, number = MRU offset during navigation
-- nav_depth: reentrancy counter to suppress focus-signal resets during navigation
local screen_data = {}
setmetatable(screen_data, { __mode = "k" })

local function data_for(s)
    if not screen_data[s] then
        screen_data[s] = {
            stack = {},
            pos = 0,
            client_pointer = nil,
            nav_depth = 0,
        }
    end
    return screen_data[s]
end

local function has_clients(tag)
    for _, c in ipairs(tag:clients()) do
        if c.type ~= "dock" then
            return true
        end
    end
    return false
end

local function remove_at(stack, idx)
    for i = idx, #stack - 1 do
        stack[i] = stack[i + 1]
    end
    stack[#stack] = nil
end

local function remove_all(stack, tag)
    local i = 1
    while i <= #stack do
        if stack[i] == tag then
            remove_at(stack, i)
        else
            i = i + 1
        end
    end
end

function history.switch(tag, screen)
    if not tag then
        return
    end
    screen = screen or tag.screen
    if not screen then
        return
    end
    local d = data_for(screen)
    local current = screen.selected_tag

    if current == tag then
        return
    end

    if current then
        remove_all(d.stack, current)
    end
    remove_all(d.stack, tag)

    if current then
        d.stack[#d.stack + 1] = current
    end
    d.stack[#d.stack + 1] = tag
    d.pos = #d.stack

    tag:view_only()
end

--- Navigate backward (older) in the history stack.
function history.back(screen)
    screen = screen or awful.screen.focused()
    local d = data_for(screen)
    if d.pos <= 1 then
        return
    end
    d.pos = d.pos - 1
    local tag = d.stack[d.pos]
    if tag and tag.activated and tag.screen then
        tag:view_only()
    end
end

--- Navigate forward (newer) in the history stack.
function history.forward(screen)
    screen = screen or awful.screen.focused()
    local d = data_for(screen)
    if d.pos >= #d.stack then
        return
    end
    d.pos = d.pos + 1
    local tag = d.stack[d.pos]
    if tag and tag.activated and tag.screen then
        tag:view_only()
    end
end

--- Pop the stack to find the last non-empty tag.
-- Used when the current tag becomes empty after unmanage.
-- @param screen table  The screen
-- @return true if a non-empty tag was found and switched to
function history.pop_to_nonempty(screen)
    screen = screen or awful.screen.focused()
    local d = data_for(screen)
    local current_tag = screen.selected_tag

    remove_all(d.stack, current_tag)

    for i = #d.stack, 1, -1 do
        local tag = d.stack[i]
        if tag and tag.activated and tag.screen == screen and has_clients(tag) then
            for j = #d.stack, i + 1, -1 do
                d.stack[j] = nil
            end
            d.pos = i
            tag:view_only()
            return true
        end
    end
    return false
end

-- ═══════════════════════════════════════════════════════════════════════════════
-- Client (window) focus history
-- ═══════════════════════════════════════════════════════════════════════════════

local function client_nav_reset(s)
    local d = data_for(s)
    if d.client_pointer then
        d.client_pointer = nil
        awful.client.focus.history.enable_tracking()
    end
end

-- Execute a function with nav_depth guard to suppress focus signal resets.
local function with_nav_guard(screen, fn)
    local d = data_for(screen)
    d.nav_depth = d.nav_depth + 1
    local ok, err = pcall(fn)
    d.nav_depth = d.nav_depth - 1
    if not ok then
        error(err)
    end
end

-- Get the client at a given offset in the MRU list for the current screen.
-- offset=0 = currently focused, offset=1 = next in history, etc.
local function client_at_offset(s, offset)
    local vc = awful.client.visible(s, true)
    local visible_set = {}
    for _, v in ipairs(vc) do
        visible_set[v] = true
    end
    local total = 0
    local match = nil
    for _, c in ipairs(awful.client.focus.history.list) do
        if c.screen == s and c.valid and visible_set[c] then
            if total == offset then
                match = c
            end
            total = total + 1
        end
    end
    return match, total
end

-- When a client is focused normally (not through navigation), reset the pointer.
capi.client.connect_signal("focus", function(c)
    if not c.screen then
        return
    end
    local d = data_for(c.screen)
    if d.nav_depth > 0 then
        return
    end
    if d.client_pointer then
        client_nav_reset(c.screen)
    end
end)

--- Navigate to the previously focused window (older in focus history).
function history.client_back()
    local s = awful.screen.focused()
    if not s then
        return
    end
    local d = data_for(s)
    if not d.client_pointer then
        awful.client.focus.history.disable_tracking()
        d.client_pointer = 1
    else
        d.client_pointer = d.client_pointer + 1
    end
    local c, total = client_at_offset(s, d.client_pointer)
    if not c and total and total > 0 then
        d.client_pointer = d.client_pointer % total
        c = client_at_offset(s, d.client_pointer)
    end
    if c then
        with_nav_guard(s, function()
            c:emit_signal("request::activate", "client.focus.history.previous", { raise = true })
            c:raise()
        end)
    else
        client_nav_reset(s)
    end
end

--- Navigate forward (newer) in the window focus history.
function history.client_forward()
    local s = awful.screen.focused()
    if not s then
        return
    end
    local d = data_for(s)
    if not d.client_pointer then
        return
    end
    d.client_pointer = d.client_pointer - 1
    local _, total = client_at_offset(s, 0)
    if d.client_pointer < 0 and total and total > 0 then
        d.client_pointer = total - 1
    end
    local c = client_at_offset(s, d.client_pointer)
    if c then
        with_nav_guard(s, function()
            c:emit_signal("request::activate", "client.focus.history.previous", { raise = true })
            c:raise()
        end)
    else
        client_nav_reset(s)
    end
end

return history
