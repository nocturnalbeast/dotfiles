#!/bin/sh
# script from https://github.com/brodierobertson/cleanfullscreen

HideBar() {
  polybar-msg cmd hide
}

ShowBar() {
  polybar-msg cmd show
}

HideNodes() {
  NODES=$(bspc query -N -n .tiled -d "$1")

  for node in $NODES; do
    bspc node "$node" -g hidden=on
  done
}

ShowNodes() {
  NODES=$(bspc query -N -n .hidden -d "$1")

  for node in $NODES; do
    bspc node "$node" -g hidden=off
  done
}

bspc subscribe node_state | while read -r Event
do
  Monitor=$(echo "$Event" | awk '{print $2}')
  Desktop=$(echo "$Event" | awk '{print $3}')
  State=$(echo "$Event" | awk '{print $5}')
  Active=$(echo "$Event" | awk '{print $6}')
  # Hide bar and nodes when node becomes fullscreen, otherwise show
  if [ "$State" = "fullscreen" ]; then
    if [ "$Active" = "on" ]; then
      if [ "$(bspc query -M -m primary)" = "$Monitor" ]; then
        HideBar
      fi
      HideNodes "$Desktop"
    else
      ShowNodes "$Desktop"
      ShowBar
    fi
  fi
done &

bspc subscribe node_remove | while read -r Event
do
  Desktop=$(echo "$Event" | awk '{print $3}')

  # Show bar if no nodes are fullscreen on current desktop
  if [ -z "$(bspc query -N -n .fullscreen -d "$Desktop")" ]; then
    ShowBar
  fi
  ShowNodes "$Desktop"
done &

bspc subscribe node_transfer | while read -r Event
do
  SrcNode=$(echo "$Event" | awk '{print $4}')
  # Show nodes on src desktop and hide nodes on dest desktop
  # If src node is in full screen mode
  if [ -n "$(bspc query -N -n "$SrcNode".fullscreen)" ]; then
    SrcDesktop=$(echo "$Event" | awk '{print $3}')
    ShowNodes "$SrcDesktop"
    DestDesktop=$(echo "$Event" | awk '{print $6}')
    HideNodes "$DestDesktop"
    ShowBar
  fi
done &

bspc subscribe desktop_focus | while read -r Event
do
  Desktop=$(echo "$Event" | awk '{print $3}')

  # Hide bar if desktop contains fullscreen node, otherwise show it
  if [ -n "$(bspc query -N -n .fullscreen -d "$Desktop" -m primary)" ]; then
    HideBar
  else
    ShowBar
  fi
done &
