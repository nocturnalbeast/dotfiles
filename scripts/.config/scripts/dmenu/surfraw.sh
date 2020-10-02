#!/bin/bash

# Source: menu-surfraw from https://github.com/TomboFry/menu-surfraw
# simplified script for use with only dmenu, added styling snippets

DEPENDENCIES=(surfraw)
for DEPENDENCY in "${DEPENDENCIES[@]}"; do
    type -p "$DEPENDENCY" &>/dev/null || {
        echo "error: Could not find '${DEPENDENCY}', is it installed?" >&2
        exit 1
    }
done

source ~/.config/scripts/dmenu-helper.sh
~/.config/scripts/polybar-helper.sh disable
trap "~/.config/scripts/polybar-helper.sh enable" EXIT

SEARCH_ELVI=$( echo "${@:1}" )
SEARCH_TERM=$( echo "${@:2}" )

if [[ -z "$SEARCH_ELVI" ]]; then
    ACTION=$( menu "  Engine: " "$( surfraw -elvi | awk -F'-' '{print $1}' | sed '/:/d' | awk '{$1=$1};1' )" )
elif [[ -z "$SEARCH_TERM" ]]; then
    ACTION=$( menu "  Search $SEARCH_ELVI: " "" )
else
    surfraw $SEARCH_ELVI
fi

case $ACTION in
    "") ;;
    *) $0 $SEARCH_ELVI $ACTION;;
esac
