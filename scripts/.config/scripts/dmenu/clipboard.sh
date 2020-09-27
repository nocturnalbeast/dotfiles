#!/bin/bash

DEPENDENCIES=(clipmenu)
for DEPENDENCY in "${DEPENDENCIES[@]}"; do
    type -p "$DEPENDENCY" &>/dev/null || {
        echo "error: Could not find '${DEPENDENCY}', is it installed?" >&2
        exit 1
    }
done

source ~/.config/scripts/dmenu-helper.sh
source ~/.config/scripts/polybar-helper.sh
bar_hide_active
trap bar_show_first EXIT

clipmenu $( get_options ) -p "   "
