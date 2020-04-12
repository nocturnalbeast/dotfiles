#!/bin/bash

notify-send -a Keybinding -t 5000 "$( cat ~/.config/sxhkd/sxhkdrc | awk '/^[a-z]/ && last {print $0,"::",last} {last=""} /^#/{last=$0}' | column -t -s '::' | rofi -dmenu -i -no-show-icons -width 1150 -font 'mono 12' | sed 's/\(.*\)\s\s*#\s\(.*\)/\n\1\n\u\2/' )"
