#!/usr/bin/env bash

WIN_MODE="tiled"
if bspc query -T -n | grep -q '"state":"tiled"'; then WIN_MODE="$1"; fi
bspc node -t $WIN_MODE
