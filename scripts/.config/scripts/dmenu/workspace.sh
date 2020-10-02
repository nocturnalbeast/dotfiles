#!/bin/bash

source ~/.config/scripts/dmenu-helper.sh
~/.config/scripts/polybar-helper.sh disable
trap "~/.config/scripts/polybar-helper.sh enable" EXIT

DEPENDENCIES=(wmctrl)
for DEPENDENCY in "${DEPENDENCIES[@]}"; do
    type -p "$DEPENDENCY" &>/dev/null || {
        echo "error: Could not find '${DEPENDENCY}', is it installed?" >&2
        exit 1
    }
done

declare -A WKSP
WKSP_INFO=$( wmctrl -d | awk '{print $1":"$2":"$9}' )
while IFS= read -r LINE; do
    WKSP+=([$( echo "$LINE" | cut -f 2,3 -d : )]=$( echo "$LINE" | cut -f 1 -d : ))
done <<< "$WKSP_INFO"

SEL_WKSP=$( menu "   " "$( printf '%s\n' "${!WKSP[@]}" | sort )")
[[ "$SEL_WKSP" == "" ]] && exit 0
wmctrl -s "${WKSP[$SEL_WKSP]}"
