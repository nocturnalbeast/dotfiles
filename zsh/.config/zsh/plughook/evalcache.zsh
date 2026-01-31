#!/usr/bin/env zsh

function atinit() {
    export ZSH_EVALCACHE_DIR="$XDG_CACHE_HOME/zsh/evalcache"
    [[ ! -d "$ZSH_EVALCACHE_DIR" ]] && mkdir -p "$ZSH_EVALCACHE_DIR"
}

function atload() {
    # disabled for now due to prompt rendering lag; see https://github.com/jdx/mise/discussions/3658
    #if (( $+commands[mise] )); then
    #    zsh-defer -a _evalcache mise activate zsh
    #fi

    if (( $+commands[navi] )); then
        zsh-defer -a _evalcache navi widget zsh
    fi
}
