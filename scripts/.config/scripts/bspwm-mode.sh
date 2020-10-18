#!/usr/bin/env bash

WIN_MODE="tiled"
bspc query -T -n | grep -q '"state":"tiled"'
[ $? == 0 ] && WIN_MODE="$1"
bspc node -t $WIN_MODE
