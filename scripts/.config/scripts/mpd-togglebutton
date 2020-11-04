#!/usr/bin/env bash

echo '契'
mpc idleloop player 2>/dev/null | while read EVENT; do
    IS_PLAYING="$( mpc status 2>/dev/null | sed '2q;d' | grep -cF "[playing]" )"
    [[ "$IS_PLAYING" -eq 1 ]] && echo '' || echo '契'
done
