#!/bin/bash

DEPENDENCIES=(clipmenu)
for DEPENDENCY in "${DEPENDENCIES[@]}"; do
    type -p "$DEPENDENCY" &>/dev/null || {
        echo "error: Could not find '${DEPENDENCY}', is it installed?" >&2
        exit 1
    }
done

source ~/.config/scripts/dmenu-helper.sh
~/.config/scripts/polybar-helper.sh disable
trap "~/.config/scripts/polybar-helper.sh enable" EXIT

REGEX=$( clipdel ".*" | dmenu $( get_options ) -l 10 -p " 﫧  " )
[[ "$REGEX" == "" ]] && exit 0

clipdel -d "$REGEX"
