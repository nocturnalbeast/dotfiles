#!/bin/bash

source ~/.config/scripts/dmenu-helper.sh
~/.config/scripts/polybar-helper.sh disable
trap "~/.config/scripts/polybar-helper.sh enable" EXIT

ENTRIES=$( cat ~/.config/sxhkd/sxhkdrc | awk '/^[A-Za-z]/ && last {print $0,"::",last} {last=""} /^#/{last=$0}' | column -t -s '::' )

SEL_KEYBIND=$( echo "$ENTRIES" | dmenu $( get_options ) -l 10 -p "   " )
[[ "$SEL_KEYBIND" == "" ]] && exit 0

echo $SEL_KEYBIND
notify-send -a Keybinding -t 5000 "$( echo "$SEL_KEYBIND" | sed 's/\(.*\)\s\s*#\s\(.*\)/\n\1\n\u\2/' )"
