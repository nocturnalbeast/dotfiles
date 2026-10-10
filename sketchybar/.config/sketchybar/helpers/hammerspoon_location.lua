-- helpers/hammerspoon_location.lua - NO-OP STUB (future HS-side location hook).
--
-- pcall(dofile)d by ~/.hammerspoon/init.lua §[1] (pre-existing hook; a
-- missing file logs "Failed to load location watcher" to the HS console).
-- Returning a table satisfies the loader silently. NOTE: the sketchybar
-- side never prompts for Location itself - the SSID grant (if wanted) is
-- a user action in System Settings (AGENT.md fact 8 / bridge section).
return {}
