#!/usr/bin/env bash

CONFIG_FILE="$XDG_CONFIG_HOME/spectrwm/spectrwm.conf"
ICON="$XDG_CONFIG_HOME/dunst/icons/keyboard.svg"
MENU="$HOME/.config/scripts/dmenu-helper.sh custom_menu"

BINDINGS="$( sed -n "s/^[ ]*bind\[\(.*\)\][ ]*=[ ]*\(.*\)[ ]*$/\2 -> \1/p" "$CONFIG_FILE" | sed "s/MOD/$( sed -n "s/^[ ]*modkey[ ]*=[ ]*\(.*\)[ ]*$/\1/p" "$CONFIG_FILE" )/g" | sed "s/Mod1/Alt/g" | sed "s/Mod4/Super/g" | tr '[:upper:]' '[:lower:]' | column -t )"

SEL_KEYBIND="$( $MENU "-l 5" "   " "$BINDINGS" )"
[[ "$SEL_KEYBIND" == "" ]] && exit 0

notify-send -t 5000 "Selected keybind:" "$( echo "$SEL_KEYBIND" | tr -s "[:blank:]" " " | sed 's/\(.*\) -> \([^ ]*\)/<b>\1<\/b>\n\2/' )" -i "$ICON"