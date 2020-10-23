#!/usr/bin/env bash

DEPENDENCIES=(gtk-launch)
for DEPENDENCY in "${DEPENDENCIES[@]}"; do
    type -p "$DEPENDENCY" &>/dev/null || {
        echo "error: Could not find '${DEPENDENCY}', is it installed?" >&2
        exit 1
    }
done

MENU="$HOME/.config/scripts/dmenu-helper.sh run_menu"

# the location of the frecency history file
HISTORY_LOC="$HOME/.cache/frecency_launcher/history"

# these are the paths that are used to either include in the search or avoid
# use pipe symbol as the separator for multiple paths
PATHS_INCLUDE="$HOME/.local/share/applications|/usr/share/applications"
PATHS_EXCLUDE="/tmp"

function usage() {
    echo "$(basename "$0") : dmenu frecency launcher script"
    echo " Possible operations: "
    echo "  rebuild : Discard history and regenerate application index."
    echo "  refresh : Refresh the application index without discarding history."
    echo "  launch  : Launch an application."
}

# one-liner to get all apps in the format we need
function get_apps() {
    find / -iname "*.desktop" 2>>/dev/null | grep -vE "$PATHS_EXCLUDE" | grep -E "$PATHS_INCLUDE" | xargs -n 1 basename | sort | uniq | sort | xargs -n 1 echo "00000.0000000000" | sed 's/\.desktop$//'
}

# one-liner to get a listing of all new apps in the format we need
function get_new_apps() {
    comm -23 <( get_apps | cut -f 2- -d ' ' | sort | uniq | sort ) <( cut -f 2- -d ' ' "$HISTORY_LOC" | sort | uniq | sort ) | xargs -n 1 echo "00000.0000000000"
}

# function to rebuild the history file, disregarding the existing file
function rebuild_hfile() {
    rm -rf "$( dirname "$HISTORY_LOC" )"
    mkdir -p "$( dirname "$HISTORY_LOC" )"
    get_apps > "$HISTORY_LOC"
}

# function to refresh the history file without losing history
function refresh_hfile() {
    local REFHIST="$( echo -e "$( get_new_apps )\n$( cat "$HISTORY_LOC" )" | sort -nr )"
    echo "$REFHIST" > "$HISTORY_LOC"
}

# function to launch applications
function launch_application() {
    # get the selected application via menu prompt
    local SEL_APP="$( $MENU "   " "$( cut -f 2- -d ' ' "$HISTORY_LOC" )" )"
    # if nothing chosen, then exit
    [[ "$SEL_APP" == "" ]] && exit 0
    # next, get the entry and its corresponding fields from the history file
    local SEL_ENT="$( grep -E "^[0-9]{5}\.[0-9]{10} $SEL_APP$" "$HISTORY_LOC" )"
    local APP_NAME="$( echo "$SEL_ENT" | cut -f 2- -d " " )"
    local APP_FREQ="$( echo "$SEL_ENT" | cut -f 1 -d "." )"
    # we discard the earlier timestamp and replace it with this
    local APP_LSTL="$( date +%s )"
    # increment the frequency counter for the application selected
    APP_FREQ="$( printf %05.0f $(( $APP_FREQ + 1 )) )"
    # launch the app
    gtk-launch "$APP_NAME"
    # create the updated entry and save it to the history file
    local HCONTENT="$( echo -e "$( grep -vE "^[0-9]{5}\.[0-9]{10} $APP_NAME$" "$HISTORY_LOC" )\n$APP_FREQ.$APP_LSTL $APP_NAME" | sort -nr | uniq | sort -nr )"
    echo -e "$HCONTENT" > "$HISTORY_LOC"
}

case $1 in
    rebuild) rebuild_hfile; exit 0;;
    refresh) refresh_hfile; exit 0;;
    launch) launch_application; exit 0;;
    *) echo "Unknown operation: $1"; usage; exit 1;;
esac
