#!/usr/bin/env zsh

function atload() {
    zle_highlight=('paste:none')
    local cache_flag="$ZSH_CACHE_DIR/fsth_set"
    if [[ ! -f "$cache_flag" ]]; then
        if [[ ! -f "$FAST_WORK_DIR/current_theme.zsh" ]]; then
            fast-theme clean
        fi
        touch "$cache_flag"
    fi
}

