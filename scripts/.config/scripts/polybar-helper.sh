#!/usr/bin/env bash

STATE_FILE="$XDG_CACHE_HOME/bar_state"

usage() {
    echo "$(basename $0) : polybar helper script"
    echo " Possible operations: "
    echo "  init        : Initialize state file (used right after starting polybar)."
    echo "  get_state   : Returns the global state of the bars (are they hidden or not?)"
    echo "  switch      : Switch the active bar."
    echo "  enable      : Show the active bar."
    echo "  disable     : Hide the active bar."
    echo "  toggle      : Toggle between showing/hiding the active bar."
    echo "  pad_enable  : Enable top padding reserved by the window manager."
    echo "  pad_disable : Disable top padding reserved by the window manager."
    echo "  pad_toggle  : Toggle top padding reserved by the window manager."
}

get_bars() {
    IFS=$'\n'
    WIDS=($( xdotool search --class "Polybar" ))
    unset IFS
    for WID in "${WIDS[@]}"; do
        WNAME="$( xprop WM_NAME -id $WID | awk '{gsub(/[","]/,"",$3);print $3}' | sed 's/^polybar-//g' )"
        WPID="$( xprop _NET_WM_PID -id $WID | awk '{gsub(/[","]/,"",$3);print $3}' )"
        echo "$WNAME:$WID:$WPID"
    done
}

init_state() {
    [[ ! -f $STATE_FILE ]] && get_bars > "$STATE_FILE"
    while IFS= read -r LINE; do
        WID="$( echo "$LINE" | cut -f 2 -d : )"
        WSTATE="$( xwininfo -id "$WID" | tr -d " " | grep "^MapState:" | cut -f 2 -d : )"
        if [[ "$WSTATE" == "IsViewable" ]]; then
            ALL_STATES+=( "$LINE:visible" )
        else
            ALL_STATES+=( "$LINE:hidden" )
        fi
    done < "$STATE_FILE"
    printf "%s\n" "${ALL_STATES[@]}" > "$STATE_FILE"
}

# wm-specific functions - define one for every wm that we use
# this is kinda hacky, i guess
bspwm_get_padding() {
    bspc config top_padding
}

bspwm_enable_padding() {
    bspc config top_padding "$( grep -Eo "bspc config top_padding\s+[0-9]+" "$XDG_CONFIG_HOME/bspwm/bspwmrc" | tr -s ' ' | cut -f 4 -d ' ' )"
}

bspwm_disable_padding() {
    bspc config top_padding 0
}

# now for the wrapper functions that invoke the functions above based on which wm we're running
get_window_manager() { wmctrl -m | sed -n "s/^Name: \(.*\)/\1/p"; }
get_padding() { $( get_window_manager )_get_padding 2>/dev/null; }
enable_padding() { $( get_window_manager )_enable_padding 2>/dev/null; }
disable_padding() { $( get_window_manager )_disable_padding 2>/dev/null; }
toggle_padding() { [[ "$( get_padding )" != "0" ]] && disable_padding 2>/dev/null || enable_padding 2>/dev/null; }

switch_bar() {
    polybar-msg cmd toggle 2>&1 >/dev/null
    sed -i 's/visible/@@/gi; s/hidden/visible/gi; s/@@/hidden/gi' "$STATE_FILE"
}

enable_bars() {
    if [[ "$( get_padding )" != "0" ]]; then
        PID_ACTIVE="$( grep "visible$" "$STATE_FILE" | cut -f 3 -d : )"
        polybar-msg -p "$PID_ACTIVE" cmd show 2>&1 >/dev/null
    fi
}

are_bars_hidden() {
    STATE="$( for WID in $( xdotool search --class "Polybar" ); do xwininfo -id "0x$( printf "%x" "$WID" )"; done | grep "Map State: " | uniq | wc -l )"
    if [[ "$STATE" == "2" ]]; then
        echo "no"
    else
        echo "yes"
    fi
}

disable_bars() {
    polybar-msg cmd hide 2>&1 >/dev/null
}

toggle_bars() {
    if [[ "$( are_bars_hidden )" == "yes" ]]; then
        enable_bars
    else
        disable_bars
    fi
}

case $1 in
    init) init_state; exit 0;;
    get_state) are_bars_hidden; exit 0;;
    switch) switch_bar; exit 0;;
    enable) enable_bars; exit 0;;
    disable) disable_bars; exit 0;;
    toggle) toggle_bars; exit 0;;
    pad_enable) enable_padding; exit 0;;
    pad_disable) disable_padding; exit 0;;
    pad_toggle) toggle_padding; exit 0;;
    *) echo "Unknown operation: $1"; usage; exit 1;;
esac
