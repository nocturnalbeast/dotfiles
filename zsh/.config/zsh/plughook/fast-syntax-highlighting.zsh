#!/usr/bin/env zsh

function atclone() {
    return 0
}

function atinit() {
    return 0
}

function atload() {
    zle_highlight=('paste:none')
    if [[ ! -f "$FAST_WORK_DIR/current_theme.zsh" ]]; then
        fast-theme clean
    fi
}

