#!/bin/sh
# borders.sh — launch borders with colors from the active GUI palette.
# GUI world: reads ~/.cache/theme/palette.json .active.colors (Material roles:
# primary = active border, outline_variant = inactive border) via jq.
# Hardcoded fallbacks cover fresh boot with no palette / no jq (palette.json
# lives in ~/.cache, which macOS never wipes).
set -eu

borders_sh_palette="$HOME/.cache/theme/palette.json"

borders_sh_active=""
borders_sh_inactive=""
if command -v jq >/dev/null 2>&1 && [ -r "$borders_sh_palette" ]; then
    borders_sh_active=$(jq -r '.active.colors.primary // ""' "$borders_sh_palette" 2>/dev/null || true)
    borders_sh_inactive=$(jq -r '.active.colors.outline_variant // ""' "$borders_sh_palette" 2>/dev/null || true)
fi

# Values must be #RRGGBB or they are discarded (bad/partial palette).
case $borders_sh_active in
    \#[0-9A-Fa-f][0-9A-Fa-f][0-9A-Fa-f][0-9A-Fa-f][0-9A-Fa-f][0-9A-Fa-f]) ;;
    *) borders_sh_active="" ;;
esac
case $borders_sh_inactive in
    \#[0-9A-Fa-f][0-9A-Fa-f][0-9A-Fa-f][0-9A-Fa-f][0-9A-Fa-f][0-9A-Fa-f]) ;;
    *) borders_sh_inactive="" ;;
esac

# Fallbacks if palette is missing or unreadable (Material-dark baseline)
[ -n "$borders_sh_active" ] || borders_sh_active="#adc6ff"
[ -n "$borders_sh_inactive" ] || borders_sh_inactive="#44474f"

# hex "#adc6ff" -> "0xffadc6ff" (borders uses AARRGGBB)
exec borders \
    active_color="0xff${borders_sh_active#\#}" \
    inactive_color="0xff${borders_sh_inactive#\#}" \
    width=2.0
