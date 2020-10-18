#!/usr/bin/env bash

# Source: menu-calc from https://github.com/onespaceman/menu-calc
# added dependency checking script and some styling

DEPENDENCIES=(xclip bc)
for DEPENDENCY in "${DEPENDENCIES[@]}"; do
    type -p "$DEPENDENCY" &>/dev/null || {
        echo "error: Could not find '${DEPENDENCY}', is it installed?" >&2
        exit 1
    }
done

MENU="$HOME/.config/scripts/dmenu-helper.sh run_menu"

ANSWER=$( echo "$@" | bc -l | sed '/\./ s/\.\{0,1\}0\{1,\}$//' )
ACTION=$( $MENU "  $ANSWER " " Copy to clipboard\n Clear" )

case $ACTION in
    " Clear") $0 ;;
    " Copy to clipboard") echo -n "$ANSWER" | xclip ;;
    "") ;;
    *) $0 "$ANSWER $ACTION" ;;
esac
