#!/usr/bin/env bash

DEPENDENCIES=(clipmenu)
for DEPENDENCY in "${DEPENDENCIES[@]}"; do
    type -p "$DEPENDENCY" &>/dev/null || {
        echo "error: Could not find '${DEPENDENCY}', is it installed?" >&2
        exit 1
    }
done

MENU_OPTS="$( $HOME/.config/scripts/dmenu-helper.sh get_options )"

~/.config/scripts/polybar-helper.sh disable 2>&1 >/dev/null
trap "~/.config/scripts/polybar-helper.sh enable 2>&1 >/dev/null" EXIT

clipmenu $MENU_OPTS -p "   "
