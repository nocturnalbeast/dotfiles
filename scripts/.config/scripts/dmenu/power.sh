#!/bin/bash

# Source: shutdownmenu from https://github.com/MaryHal/dmenu-suite
# adapted to match setup and added styling snippets

source ~/.config/scripts/dmenu-helper.sh
source ~/.config/scripts/polybar-helper.sh
bar_hide_active
trap bar_show_first EXIT

MAIN_MENU="⏻ Shutdown\n⏼ Reboot\n⏾ Sleep\n Lock\n Clear pending"
DELAY_MENU="now\n+60\n+45\n+30\n+15\n+10\n+5\n+3\n+2\n+1"

ACTION=$( menu " 漣  " "$MAIN_MENU" )
[ -z "$ACTION" ] && exit

case "$ACTION" in
    '⏻ Shutdown')
        DELAY=$( menu "Delay: " "$DELAY_MENU" )
        [ -z "$DELAY" ] && exit
        notify-send -u normal -a "System" " Shutting down" "Delay: $DELAY"
        shutdown -P "$DELAY"
        ;;
    '⏼ Reboot')
        DELAY=$( menu "Delay: " "$DELAY_MENU" )
        [ -z "$DELAY" ] && exit
        notify-send -u normal -a "System" " Rebooting" "Delay: $DELAY"
        shutdown -r "$DELAY"
        ;;
    '⏾ Sleep')
        notify-send -u low -a "System" " Suspending now"
        systemctl suspend
        ;;
    ' Lock')
        light-locker-command --lock
        ;;
    ' Clear pending')
        notify-send -u normal -a "System" " Cleared pending shutdown"
        shutdown -c
esac
