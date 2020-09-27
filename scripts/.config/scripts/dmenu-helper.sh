#!/bin/bash

# import the variables from stylerc
source ~/.config/dmenu/stylerc

# define options to be passed to dmenu
WIDTH=$( expr $( xdpyinfo | awk '/dimensions/{print $2}' | cut -f 1 -d 'x' ) - 2 \* $HPAD )
OPTIONS="-x $HPAD -y $VPAD -h $HEIGHT -wd $WIDTH -nb $BG_CLR -nf $FG_CLR -sb $SELBG_CLR -sf $SELFG_CLR -nhb $HLBG_CLR -nhf $HLFG_CLR -shb $SELHLBG_CLR -shf $SELHLFG_CLR"

function menu {
    echo -e "$2" | dmenu $OPTIONS -p "$1" | tail -1
}

function get_options {
    echo "$OPTIONS"
}
