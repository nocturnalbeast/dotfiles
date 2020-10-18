#!/bin/sh

echo '契'
mpc idleloop player | while read EVENT; do
    IS_PLAYING="$( mpc status | sed '2q;d' | grep -F "[playing]" | wc -l )"
    [[ "$IS_PLAYING" -eq 1 ]] && echo '' || echo '契'
done
