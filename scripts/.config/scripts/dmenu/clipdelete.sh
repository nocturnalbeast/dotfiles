#!/bin/bash

DEPENDENCIES=(clipmenu)
for DEPENDENCY in "${DEPENDENCIES[@]}"; do
    type -p "$DEPENDENCY" &>/dev/null || {
        echo "error: Could not find '${DEPENDENCY}', is it installed?" >&2
        exit 1
    }
done

MENU="$HOME/.config/scripts/dmenu-helper.sh custom_menu"

REGEX=$( $MENU "-l $CM_HISTLENGTH" " 﫧  " "$( clipdel ".*" )" )
[[ "$REGEX" == "" ]] && exit 0

clipdel -d "$REGEX"
