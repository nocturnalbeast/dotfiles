#!/usr/bin/env bash

SIZE=${2:-'20'}
DIRECTION=$1

if ! $( bspc query -T -n | grep -q '"state":"tiled"' ); then
    case "$DIRECTION" in
        west) FLAG="-x -";;
        east) FLAG="-x +";;
        north) FLAG="-y -";;
        south) FLAG="-y +";;
    esac
    xdo resize ${FLAG}${SIZE}
else
    case "$DIRECTION" in
        west) bspc node @west -r -${SIZE} || bspc node @east -r -${SIZE};;
        east) bspc node @west -r +${SIZE} || bspc node @east -r +${SIZE};;
        north) bspc node @south -r -${SIZE} || bspc node @north -r -${SIZE};;
        south) bspc node @south -r +${SIZE} || bspc node @north -r +${SIZE};;
    esac
fi
