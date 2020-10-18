#!/bin/bash

DMENU_SCRIPT_DIR="$HOME/.config/scripts/dmenu"
DMENU_STYLERC_PATH="$XDG_CONFIG_HOME/dmenu/stylerc"

usage() {
    echo "$(basename $0) : dmenu helper script"
    echo " Possible operations: "
    echo "  run_menu    : Runs dmenu with the custom style and a supplied prompt message."
    echo "  get_options : Gets command-line options that are passed to dmenu."
    echo "  custom_menu : Runs dmenu with additional options apart from the custom style and prompt message."
    echo "  list_menus  : Runs a dmenu prompt with all the menu scripts and runs the chosen one."
}

get_options() {
    # import the variables from stylerc
    source "$DMENU_STYLERC_PATH"
    # define options to be passed to dmenu
    WIDTH=$( expr $( xdpyinfo | awk '/dimensions/{print $2}' | cut -f 1 -d 'x' ) - 2 \* $HPAD )
    echo "-x $HPAD -y $VPAD -h $HEIGHT -wd $WIDTH -nb $BG_CLR -nf $FG_CLR -sb $SELBG_CLR -sf $SELFG_CLR -nhb $HLBG_CLR -nhf $HLFG_CLR -shb $SELHLBG_CLR -shf $SELHLFG_CLR"
}

polybar_control() {
    ~/.config/scripts/polybar-helper.sh disable 2>&1 >/dev/null
    trap "~/.config/scripts/polybar-helper.sh enable 2>&1 >/dev/null" EXIT
}

menu() {
    if [ "$3" != "" ]; then
        LINES="$3"
    elif [ -p /dev/stdin ]; then
        LINES="$( cat )"
    fi
    echo -e "$LINES" | dmenu $1 -p "$2" | tail -1
}

list_menus() {
    SCRIPTS=""
    for ENTRY in "$DMENU_SCRIPT_DIR"/*; do SCRIPTS="$SCRIPTS$( basename $ENTRY )\n"; done
    SEL_SCRIPT="$( menu "   " "$SCRIPTS" )"
    [[ "$SEL_SCRIPT" == "" ]] && exit 0
    "$DMENU_SCRIPT_DIR"/"$SEL_SCRIPT"
}

case $1 in
    run_menu) polybar_control; menu "$( get_options )" "$2" "$3"; exit 0;;
    get_options) get_options; exit 0;;
    custom_menu) polybar_control; menu "$( get_options ) $2" "$3" "$4"; exit 0;;
    list_menus) polybar_control; list_menus; exit 0;;
    *) echo "Unknown operation: $1"; usage; exit 1;;
esac
