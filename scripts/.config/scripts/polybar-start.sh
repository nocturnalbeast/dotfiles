#!/bin/sh

BARONE="mainbar"
BARTWO="monbar"

# get the name of the window manager
export WINDOW_MANAGER=$( wmctrl -m | sed -n "s/^Name: \(.*\)/\1/p" )

# terminate already running bar instances
killall -q polybar

# remove the state file from the previous instances
rm -f $HOME/.cache/polybar_state

# wait until the processes have been shut down
while pgrep -u $UID -x polybar >/dev/null 2>&1; do sleep 1; done

# then launch bars
for M in $( polybar --list-monitors | cut -d: -f1 ); do
    # get the width of the monitor
    RES_X=$( xrandr | grep $( polybar --list-monitors | cut -f 1 -d : ) | grep -Eo '([0-9]+x[0-9]+\+[0-9]+\+[0-9]+)' )
    MONITOR=$M BAR_WIDTH=$RES_X polybar $BARONE &
    MONITOR=$M BAR_WIDTH=$RES_X polybar $BARTWO &
done

# get the process ID of the second bar
BARTWO_PID=$!

# wait till the second bar has launched
while ! ls /tmp/polybar_mqueue.$BARTWO_PID >/dev/null 2>&1; do sleep 1; done

# then hide the second bar, showing only the first bar
polybar-msg -p $BARTWO_PID cmd hide >/dev/null 2>&1

# initialize the state file for the helper script
rm -f ~/.cache/bar_state
$HOME/.config/scripts/polybar-helper.sh init
