#!/usr/bin/env zsh

function atclone() {
    return 0
}

function atinit() {
    return 0
}

function atload() {
    export GITCD_HOME="${XDG_DOWNLOAD_DIR:-$HOME}/repos"
    export GITCD_USEHOST=false
    [[ ! -d "$GITCD_HOME" ]] && mkdir -p "$GITCD_HOME"
}
