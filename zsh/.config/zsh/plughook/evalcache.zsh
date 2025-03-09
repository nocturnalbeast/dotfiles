#!/usr/bin/env zsh

function atclone() {
    return 0
}

function atinit() {
    export ZSH_EVALCACHE_DIR="$XDG_CACHE_HOME/zsh/evalcache"
    [[ ! -d "$ZSH_EVALCACHE_DIR" ]] && mkdir -p "$ZSH_EVALCACHE_DIR"
}

function atload() {
    # disabled for now due to prompt rendering lag; see https://github.com/jdx/mise/discussions/3658
    #if command -v mise &> /dev/null; then
    #    zsh-defer -a _evalcache mise activate zsh
    #fi

    if command -v navi &> /dev/null; then
        zsh-defer -a _evalcache navi widget zsh
    fi
}
