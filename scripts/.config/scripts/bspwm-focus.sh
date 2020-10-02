#!/bin/bash

size=${2:-'20'}
dir=$1

# find current window mode
is_tiled() {
    bspc query -T -n | grep -q '"state":"tiled"'
}

# if the window is floating, move it
if ! is_tiled; then
    # only parse input if window is floating, tiled windows accept input as is
    case "$dir" in
        west) switch="-x"
        sign="-"
        ;;
        east) switch="-x"
        sign="+"
        ;;
        north) switch="-y"
        sign="-"
        ;;
        south) switch="-y"
        sign="+"
        ;;
    esac
    xdo move ${switch} ${sign}${size}
# otherwise, window is tiled: just move to the direction given, disregarding the size
else
    bspc node -f $1
fi
