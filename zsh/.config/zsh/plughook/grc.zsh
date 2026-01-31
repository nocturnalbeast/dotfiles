#!/usr/bin/env zsh

function atclone() {
    mkdir -p "$XDG_CONFIG_HOME/grc"
    cp -fv "$ZCOMET_HOME/repos/garabik/grc/colourfiles/conf.*" "$ZCOMET_HOME/repos/garabik/grc/grc.conf" "$XDG_CONFIG_HOME/grc"
}

