#!/bin/sh

# terminate notify-osd instances
killall -q notify-osd

# wait until the process has been shut down
while pgrep -u $UID -x notify-osd >/dev/null; do sleep 1; done

# then launch dunst
dunst &
