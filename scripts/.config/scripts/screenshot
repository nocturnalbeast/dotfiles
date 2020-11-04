#!/usr/bin/env bash

SCREENSHOTS_DIR="$XDG_PICTURES_DIR/screenshots"
[ ! -d "$SCREENSHOTS_DIR" ] && mkdir -p "$SCREENSHOTS_DIR"

MAIM_OPTS="-o -u" 
SLOP_OPTS="-b 2 -c 0,0,0,0.6 -q"

IMAGE_PATH="$SCREENSHOTS_DIR/$( date +%Y-%m-%d_%H:%M:%S ).png"

STATUS="1"
case $1 in
    full) maim $MAIM_OPTS "$IMAGE_PATH"; STATUS="$?";;
    window) maim $MAIM_OPTS -B -i $( xdotool getactivewindow ) "$IMAGE_PATH"; STATUS="$?";;
    select) maim $MAIM_OPTS $SLOP_OPTS -s -B "$IMAGE_PATH"; STATUS="$?";;
    *) echo -e "Unknown operation: '$1'\n Only allowed operations - full, window, select."; exit 1;;
esac

if [ $STATUS -ne 0 ]; then
    dunstify "Failed to take screenshot."
else
    ACTION=$( dunstify --action="default,Open image" "Screenshot taken." "Path: $IMAGE_PATH" )
    [ "$ACTION" == "default" ] && pqiv "$IMAGE_PATH" &
fi
