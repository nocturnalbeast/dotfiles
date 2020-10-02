#!/bin/bash

DEPENDENCIES=(wmctrl)
for DEPENDENCY in "${DEPENDENCIES[@]}"; do
    type -p "$DEPENDENCY" &>/dev/null || {
        echo "error: Could not find '${DEPENDENCY}', is it installed?" >&2
        exit 1
    }
done

source ~/.config/scripts/dmenu-helper.sh
~/.config/scripts/polybar-helper.sh disable
trap "~/.config/scripts/polybar-helper.sh enable" EXIT

IFS=$'\n'
WKSP_NAMES=($( wmctrl -d | awk '{print $9};' ))
WINDOWS=($( wmctrl -l | awk '{print $1":"$2":"substr($0, index($0,$4))};' ))
unset IFS
for IDX in ${!WINDOWS[*]}; do
    WINDOWS_WWN+=("$IDX. $( wmctrl -d | grep "^$( echo "${WINDOWS[$IDX]}" | cut -f 2 -d : )" | awk '{print $9}' ):$( echo "${WINDOWS[$IDX]}" | cut -f 3 -d : )")
    WIDS+=("$( echo "${WINDOWS[$IDX]}" | cut -f 1 -d : )")
done

SEL_WNUM=$( menu "   " "$( printf '%s\n' "${WINDOWS_WWN[@]}" )" | cut -f 1 -d . )
[ "$SEL_WNUM" != "" ] && wmctrl -ia "${WIDS[$SEL_WNUM]}" &
