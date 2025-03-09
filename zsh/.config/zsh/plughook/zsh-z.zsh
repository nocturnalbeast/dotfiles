#!/usr/bin/env zsh

function atclone() {
    return 0
}

function atinit() {
    ZSHZ_DATA="$XDG_CACHE_HOME/zsh-z"
    ZSHZ_TILDE=1
}

function atload() {
    return 0
}
