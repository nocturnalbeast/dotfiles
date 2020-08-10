#!/bin/sh

usage() {
    echo "$(basename $0) : window manager info script"
    echo " Possible operations: "
    echo "  workspace       : Get the index of the current workspace."
    echo "  workspace_name  : Get the name assigned to the current workspace."
    echo "  workspace_icon  : Get the icon assigned to the current workspace."
    echo "  window_name     : Get the name of the current window."
    echo "  window_class    : Get the class of the current window."
    echo "  window_instance : Get the instance name of the current window."
    echo "  window_state    : Get the state of the current window."
}

get_current_workspace() {
    xprop -root '\t$0' _NET_CURRENT_DESKTOP | cut -f 2
}

get_current_workspace_name() {
    declare -i SEP=$( xprop -root '\t$0' _NET_CURRENT_DESKTOP | cut -f 2 )+1
    C_WKSP_NAME=$( xprop -root _NET_DESKTOP_NAMES | tr -d ' ' | cut -d = -f 2 | cut -d , -f $SEP ); C_WKSP_NAME="${C_WKSP_NAME#?}"; C_WKSP_NAME="${C_WKSP_NAME%?}"
    echo $C_WKSP_NAME
}

get_current_workspace_icon() {
    # icon hex codes for each workspace
    ICON0="e795"
    ICON1="f6e6"
    ICON2="f44f"
    ICON3="e613"
    ICON4="f04b"
    ICON5="f718"
    ICON6="f1fc"
    ICON7="f6d9"
    ICON8="f9c4"
    ICON9="f2d0"
    C_WKSP=$( xprop -root '\t$0' _NET_CURRENT_DESKTOP | cut -f 2 )
    WORKSPACE_ICON=ICON$C_WKSP
    echo -e "\u${!WORKSPACE_ICON}"
}

get_current_window_name() {
    C_WINDOW=$( xprop -id $(xprop -root 32x '\t$0' _NET_ACTIVE_WINDOW | cut -f 2) '\t$0' _NET_WM_NAME | cut -f 2 ); C_WINDOW="${C_WINDOW#?}"; C_WINDOW="${C_WINDOW%?}"
    echo $C_WINDOW
}

get_current_window_class() {
    C_WINDOW=$( xprop -id $(xprop -root 32x '\t$0' _NET_ACTIVE_WINDOW | cut -f 2) '\t$1' WM_CLASS | cut -f 2 ); C_WINDOW="${C_WINDOW#?}"; C_WINDOW="${C_WINDOW%?}"
    echo $C_WINDOW
}

get_current_window_instance() {
    C_WINDOW=$( xprop -id $(xprop -root 32x '\t$0' _NET_ACTIVE_WINDOW | cut -f 2) '\t$0' WM_CLASS | cut -f 2 ); C_WINDOW="${C_WINDOW#?}"; C_WINDOW="${C_WINDOW%?}"
    echo $C_WINDOW
}

get_current_window_state() {
    C_WINDOW=$( xprop -id $(xprop -root 32x '\t$0' _NET_ACTIVE_WINDOW | cut -f 2) '\t$0' _NET_WM_STATE | cut -f 2 ); C_WINDOW="${C_WINDOW#?}"; C_WINDOW="${C_WINDOW%?}"
    echo $C_WINDOW
    C_WINDOWNS=$( xprop -id $(xprop -root 32x '\t$0' _NET_ACTIVE_WINDOW | cut -f 2) '\t$0' WM_STATE | cut -f 2 )
    echo $C_WINDOWNS
}

case $1 in
    workspace) get_current_workspace; exit 0;;
    workspace_name) get_current_workspace_name; exit 0;;
    workspace_icon) get_current_workspace_icon; exit 0;;
    window_name) get_current_window_name; exit 0;;
    window_class) get_current_window_class; exit 0;;
    window_instance) get_current_window_instance; exit 0;;
    window_state) get_current_window_state; exit 0;;
    *) echo "Unknown operation: $1"; usage; exit 1;;
esac
