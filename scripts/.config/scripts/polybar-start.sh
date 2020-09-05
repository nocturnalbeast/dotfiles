#!/bin/sh

BARONE="mainbar"
BARTWO="monbar"

# get the name of the window manager
WM=$( wmctrl -m | sed -n "s/^Name: \(.*\)/\1/p" )

# terminate already running bar instances
killall -q polybar

# wait until the processes have been shut down
while pgrep -u $UID -x polybar >/dev/null 2>&1; do sleep 1; done

# then launch bars
for m in $( polybar --list-monitors | cut -d: -f1 ); do
    MONITOR=$m WINDOW_MANAGER=$WM polybar $BARONE & 
    MONITOR=$m WINDOW_MANAGER=$WM polybar $BARTWO &
done

# get the process ID of the second bar
BARTWO_PID=$!

# wait till the second bar has launched
while ! ls /tmp/polybar_mqueue.$BARTWO_PID >/dev/null 2>&1; do sleep 1; done

# then hide the second bar, showing only the first bar
polybar-msg -p $BARTWO_PID cmd hide >/dev/null 2>&1
