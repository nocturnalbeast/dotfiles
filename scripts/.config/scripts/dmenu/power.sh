#!/usr/bin/env bash

# Source: shutdownmenu from https://github.com/MaryHal/dmenu-suite
# adapted to match setup and added styling snippets

MENU="$HOME/.config/scripts/dmenu-helper.sh run_menu"

MAIN_MENU="⏻ Shutdown\n⏼ Reboot\n⏾ Sleep\n Lock\n Clear pending"
DELAY_MENU="now\n+60\n+45\n+30\n+15\n+10\n+5\n+3\n+2\n+1"

ACTION=$( $MENU " 漣  " "$MAIN_MENU" )
[ -z "$ACTION" ] && exit

ICON="$HOME/.config/dunst/icons/power.svg"

case "$ACTION" in
    '⏻ Shutdown')
        DELAY=$( $MENU "Delay: " "$DELAY_MENU" )
        [ -z "$DELAY" ] && exit
        if [ "$DELAY" == "now" ]; then
            notify-send -u normal "Shutting down now..." -i "$ICON"
        else
            notify-send -u normal "Shutting down in $DELAY minutes..." -i "$ICON"
        fi
        shutdown -P "$DELAY"
        ;;
    '⏼ Reboot')
        DELAY=$( $MENU "Delay: " "$DELAY_MENU" )
        [ -z "$DELAY" ] && exit
        if [ "$DELAY" == "now" ]; then
            notify-send -u normal "Rebooting now..." -i "$ICON"
        else
            notify-send -u normal "Rebooting in $DELAY minutes..." -i "$ICON"
        fi
        shutdown -r "$DELAY"
        ;;
    '⏾ Sleep')
        notify-send -u low "Suspending now..." -i "$ICON"
        systemctl suspend
        ;;
    ' Lock')
        light-locker-command --lock
        ;;
    ' Clear pending')
        notify-send -u normal "Cleared pending shutdown" -i "$ICON"
        shutdown -c
esac
