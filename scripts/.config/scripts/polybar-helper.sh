#!/bin/bash

STATE_FILE="$HOME/.cache/bar_state"

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

get_padding() {
    WINDOW_MANAGER=$( wmctrl -m | sed -n "s/^Name: \(.*\)/\1/p" )
    [[ "$WINDOW_MANAGER" == "bspwm" ]] && bspc config top_padding
}

switch_bar() {
    polybar-msg cmd toggle
    sed -i 's/visible/@@/gi; s/hidden/visible/gi; s/@@/hidden/gi' "$STATE_FILE"
}

enable_bars() {
    if [[ "$( get_padding )" != "0" ]]; then
        PID_ACTIVE="$( grep "visible$" "$STATE_FILE" | cut -f 3 -d : )"
        polybar-msg -p "$PID_ACTIVE" cmd show
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
    polybar-msg cmd hide
}

toggle_bars() {
    if [[ "$( are_bars_hidden )" == "yes" ]]; then
        enable_bars
    else
        disable_bars
    fi
}

enable_padding() {
    WINDOW_MANAGER=$( wmctrl -m | sed -n "s/^Name: \(.*\)/\1/p" )
    [[ "$WINDOW_MANAGER" == "bspwm" ]] && bspc config top_padding "$( grep -Eo "bspc config top_padding\s+[0-9]+" ~/.config/bspwm/bspwmrc | tr -s ' ' | cut -f 4 -d ' ' )"
}

disable_padding() {
    WINDOW_MANAGER=$( wmctrl -m | sed -n "s/^Name: \(.*\)/\1/p" )
    [[ "$WINDOW_MANAGER" == "bspwm" ]] && bspc config top_padding 0
}

toggle_padding() {
    WINDOW_MANAGER=$( wmctrl -m | sed -n "s/^Name: \(.*\)/\1/p" )
    if [[ "$WINDOW_MANAGER" == "bspwm" ]]; then
        CURR_PADDING="$( bspc config top_padding )"
        if [[ "$CURR_PADDING" != "0" ]]; then
            bspc config top_padding 0
        else
            bspc config top_padding "$( grep -Eo "bspc config top_padding\s+[0-9]+" ~/.config/bspwm/bspwmrc | tr -s ' ' | cut -f 4 -d ' ' )"
        fi
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
