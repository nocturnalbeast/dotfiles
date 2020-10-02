#!/bin/bash

source ~/.config/scripts/dmenu-helper.sh
~/.config/scripts/polybar-helper.sh disable
trap "~/.config/scripts/polybar-helper.sh enable" EXIT

SELECTION=$( menu " ﮊ  " "$( ps -e -o pid,user,cmd | tail -n +2 | awk '{print $1":"$2":"substr($0, index($0,$3))}' )" )

[[ -z "$SELECTION" ]] && exit

PROC=$(cut -d : -f 1 <<< "$SELECTION")
NAME=$(cut -d : -f 3- <<< "$SELECTION")
[[ -z "$PROC" ]] && exit

notify-send -u normal -a "System" "Killing PID $PROC" "$NAME"
kill "$PROC"
