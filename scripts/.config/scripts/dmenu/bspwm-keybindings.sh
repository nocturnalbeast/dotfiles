#!/bin/bash

source ~/.config/scripts/dmenu-helper.sh
~/.config/scripts/polybar-helper.sh disable
trap "~/.config/scripts/polybar-helper.sh enable" EXIT

ICON="~/.config/dunst/icons/keyboard.svg"

ENTRIES=$( cat ~/.config/sxhkd/sxhkdrc | awk '/^[A-Za-z]/ && last {print $0,"::",last} {last=""} /^#/{last=$0}' | column -t -s '::' )

SEL_KEYBIND=$( echo "$ENTRIES" | dmenu $( get_options ) -l 10 -p "   " )
[[ "$SEL_KEYBIND" == "" ]] && exit 0

notify-send -t 5000 "Selected keybind:" "$( echo "$SEL_KEYBIND" | tr -s "[:blank:]" " " | sed 's/\(.*\) # \([^ ]*\)/<b>\1<\/b>\n\2/' )" -i "$ICON"
