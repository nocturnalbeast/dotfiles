#!/usr/bin/env zsh

function atclone() {
    return 0
}

function atinit() {
    export ZSH_EVALCACHE_DIR="$XDG_CACHE_HOME/zsh/evalcache"
    [[ ! -d "$ZSH_EVALCACHE_DIR" ]] && mkdir -p "$ZSH_EVALCACHE_DIR"
}

function atload() {
    return 0
}
