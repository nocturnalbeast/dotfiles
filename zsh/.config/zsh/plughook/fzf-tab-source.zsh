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
        eval "$(lesspipe.sh)"
    fi
    path=(${path:#~[fzf-tab-source]/bin})
}
