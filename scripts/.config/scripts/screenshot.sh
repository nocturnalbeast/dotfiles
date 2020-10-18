#!/bin/bash

SCREENSHOTS_DIR="$XDG_PICTURES_DIR/screenshots"
[ ! -d "$SCREENSHOTS_DIR" ] && mkdir -p "$SCREENSHOTS_DIR"
[ "$1" = "window" ] && FLAG="--focused" || FLAG=""
scrot $FLAG "$SCREENSHOTS_DIR/%d-%m-%Y_%H:%M:%S_$wx$h.png"
