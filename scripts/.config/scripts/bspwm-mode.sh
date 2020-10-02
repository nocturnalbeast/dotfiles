#!/bin/bash

# find current window mode
is_tiled() {
    bspc query -T -n | grep -q '"state":"tiled"'
}

# if the window is not tiled, switch back to tiled
if ! is_tiled; then
    bspc node -t tiled
# otherwise, window is tiled, so let it be the mode requested
else
    bspc node -t $1
fi
