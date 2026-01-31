#!/usr/bin/env zsh

function atload() {
    export GITCD_HOME="${XDG_DOWNLOAD_DIR:-$HOME}/repos"
    export GITCD_USEHOST=false
    [[ ! -d "$GITCD_HOME" ]] && mkdir -p "$GITCD_HOME"
}
