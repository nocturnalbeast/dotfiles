-- helpers/hammerspoon_audio.lua — NO-OP STUB (future HS-side audio hook).
--
-- pcall(dofile)d by ~/.hammerspoon/init.lua §[1] (pre-existing hook; a
-- missing file logs "Failed to load audio watcher" to the HS console).
-- Returning a table satisfies the loader silently. The sketchybar side
-- now consumes audio state via the `hs_audio` bridge event instead —
-- wire real Hammerspoon-side automation here if ever needed.
return {}
