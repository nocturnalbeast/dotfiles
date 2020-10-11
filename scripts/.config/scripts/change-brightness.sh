#!/bin/bash

# Source : brightnessControl.sh from https://gist.github.com/Blaradox/030f06d165a82583ae817ee954438f2e
# modified styling, added icon based on brightness level and integrate with polybar global visibility

function send_notification {
    BRIGHTNESS=$( xbacklight -get | cut -d '.' -f 1 )
    if [[ "$BRIGHTNESS" -lt "40" ]]; then
        ICON="~/.config/dunst/icons/brightness_low.svg"
    elif [[ "$BRIGHTNESS" -lt "70" ]]; then
        ICON="~/.config/dunst/icons/brightness_medium.svg"
    else
        ICON="~/.config/dunst/icons/brightness_high.svg"
    fi
    BAR=$(seq -s "🮂" 0 $(( BRIGHTNESS / 5 )) | sed 's/[0-9]//g')
    dunstify -i "$ICON" -u low -r 5555 "" "<span size='x-large'>$BAR</span>"
}

case $1 in
    up) xbacklight -inc 5 ;;
    down) xbacklight -dec 5 ;;
esac

[[ "$( ~/.config/scripts/polybar-helper.sh get_state )" == "yes" ]] && send_notification
