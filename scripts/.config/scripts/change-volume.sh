#!/usr/bin/env bash

# Source : volumeControl.sh from https://gist.github.com/Blaradox/030f06d165a82583ae817ee954438f2e
# modified styling, a bit of cleanup and integrate with polybar global visibility

function get_volume {
    amixer -D pulse get Master | grep '%' | head -n 1 | cut -d '[' -f 2 | cut -d '%' -f 1
}

function is_mute {
    amixer -D pulse get Master | grep '%' | grep -oE '[^ ]+$' | grep -q off
}

function send_notification {
    VOLUME="$( get_volume )"
    # make mute icon have precedence over all the other icons as a reminder
    if is_mute; then
        ICON="$HOME/.config/dunst/icons/volume_mute.svg"
    elif [[ "$( get_volume )" -lt "40" ]]; then
        ICON="$HOME/.config/dunst/icons/volume_low.svg"
    elif [[ "$( get_volume )" -lt "70" ]]; then
        ICON="$HOME/.config/dunst/icons/volume_medium.svg"
    else
        ICON="$HOME/.config/dunst/icons/volume_high.svg"
    fi
    BAR="$(seq -s "🮂" 0 $(( VOLUME / 5 )) | sed 's/[0-9]//g')"
    dunstify -i "$ICON" -u low -r 5556 "" "<span size='x-large'>$BAR</span>"
}

case $1 in
    up) amixer -D pulse sset Master 5%+ > /dev/null ;;
    down) amixer -D pulse sset Master 5%- > /dev/null ;;
    mute) amixer -D pulse set Master 1+ toggle > /dev/null ;;
esac

[[ "$( $HOME/.config/scripts/polybar-helper.sh get_state )" == "yes" ]] && send_notification
