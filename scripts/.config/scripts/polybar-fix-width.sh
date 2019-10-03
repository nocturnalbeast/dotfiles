#!/bin/sh

CURR_WIDTH=$( xrandr | grep \* | cut -d ' ' -f 4 | cut -d 'x' -f 1 )
sed -i "s/^bar-width.*$/bar-width = $CURR_WIDTH/g" ~/.config/polybar/config
echo "Bar width fixed."
