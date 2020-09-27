#!/bin/sh

# Source: cleanfullscreen from https://github.com/brodierobertson/cleanfullscreen
# modified ShowBar function to show only one bar instead of all of them

source ~/.config/scripts/polybar-helper.sh

HideNodes() {
  for node in $1; do
    bspc node "$node" -g hidden=on
  done
}

HideTiled() {
  Nodes=$(bspc query -N -n .tiled -d "$1")
  HideNodes "$Nodes"
}

ShowNodes() {
  Nodes=$(bspc query -N -n .hidden -d "$1")

  for node in $Nodes; do
    bspc node "$node" -g hidden=off
  done
}

bspc subscribe node_state | while read -r Event Monitor Desktop Node State Active
do
  PrimaryMonitor=$(bspc query -M -m primary)
  # Hide bar and nodes when node becomes fullscreen, otherwise show
  if [ "$State" = "fullscreen" ] && [ "$Active" = "on" ]; then
    # Only consider nodes on primary monitor
    if [ "$PrimaryMonitor" = "$Monitor" ]; then
      bar_hide_all
    fi
      HideTiled "$Desktop"
  else
    if [ "$PrimaryMonitor" = "$Monitor" ]; then
      bar_show_first
    fi
    ShowNodes "$Desktop"
  fi
done &

bspc subscribe node_remove | while read Event Monitor Desktop Node
do
  PrimaryMonitor="$(bspc query -M -m primary)"

  # Show bar if no nodes are fullscreen on current desktop
  if [ "$Monitor" = "$PrimaryMonitor" ] && \
    [ -z "$(bspc query -N -n .fullscreen -d "$Desktop")" ]; then
    bar_show_first
  fi
  ShowNodes "$Desktop"
done &

bspc subscribe node_transfer | while read -r Event SrcMonitor SrcDesktop SrcNode DestMonitor Dest Desktop DestNode
do
  # Show nodes on src desktop and hide nodes on dest desktop
  # If src node is in full screen mode
  if [ -n "$(bspc query -N -n "$SrcNode".fullscreen)" ]; then
    ShowNodes "$SrcDesktop"
    HideTiled "$DestDesktop"
    bar_show_first
  fi

  # Hide any fullscreen nodes on destination desktop
  FullscreenDest=$(bspc query -N -n .fullscreen -d "$DestDesktop" \
    | sed "/$SrcNode/d")
  if [ -n "$FullscreenDest" ]; then
    HideNodes "$FullscreenDest"
  fi
done &

bspc subscribe desktop_focus | while read -r Event Monitor Desktop
do
  PrimaryMonitor="$(bspc query -M -m primary)"
  FullscreenNode="$(bspc query -N -n .fullscreen -d "$Desktop")"

  # Only consider nodes on primary monitor
  if [ "$PrimaryMonitor" = "$Monitor" ]; then
    # Hide bar if desktop contains fullscreen node
    if [ -n "$FullscreenNode" ]; then
      bar_show_first
    # Otherwise show the bar
    else
      bar_hide_second
      bar_show_first
    fi
  fi
done &
