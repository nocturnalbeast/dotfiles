#!/usr/bin/env zsh

function atinit() {
    export ZSH_SMARTCACHE_DIR="$XDG_CACHE_HOME/zsh-smartcache"
    [[ ! -d "$ZSH_SMARTCACHE_DIR" ]] && mkdir -p "$ZSH_SMARTCACHE_DIR"
}

function atload() {
    # disabled for now due to prompt rendering lag; see https://github.com/jdx/mise/discussions/3658
    #if (( $+commands[mise] )); then
    #    zsh-defer -a smartcache eval mise activate zsh
    #fi

    if (( $+commands[navi] )); then
        zsh-defer -a smartcache eval navi widget zsh
    fi
}
