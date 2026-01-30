#!/usr/bin/env zsh

function atclone() {
    return 0
}

function atinit() {
    return 0
}

function atload() {
    # setup lesspipe
    if command -v lesspipe.sh >/dev/null 2>&1; then
        if (( $+functions[_evalcache] )); then
            _evalcache lesspipe.sh
        else
            eval "$(lesspipe.sh)"
        fi
    fi
    path=(${path:#~[fzf-tab-source]/bin})
}
