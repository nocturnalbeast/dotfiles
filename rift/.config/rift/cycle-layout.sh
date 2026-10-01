#!/bin/sh
# cycle-layout.sh — meh+M layout engine cycler (aerospace parity: its
# meh+m cycled 4 layouts; rift equivalent cycles all 5 engines).
# Queries the ACTIVE workspace's layout, sets the next in the ring.
#
# rift-cli query workspace-layout returns JSON; field name verified
# defensively (mode|layout) since 0.5.3 output shape is undocumented.
set -eu

RING="traditional bsp stack master_stack scrolling"

current=$(/opt/homebrew/bin/rift-cli query workspace-layout 2>/dev/null \
	| /usr/bin/jq -r '.mode // .layout // empty' 2>/dev/null || true)
[ -n "$current" ] || current="bsp"

next=""
for engine in $RING; do
	if [ "$found" = "1" ]; then next="$engine"; break; fi
	[ "$engine" = "$current" ] && found=1
done
# wrap: if current was the last engine (or unknown), take the first
[ -z "$next" ] && next="traditional"

/opt/homebrew/bin/rift-cli execute workspace set-layout "$next"
