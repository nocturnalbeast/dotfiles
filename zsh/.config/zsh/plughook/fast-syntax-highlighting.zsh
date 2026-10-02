#!/usr/bin/env zsh

function atload() {
    zle_highlight=('paste:none')
    local theme="$HOME/.cache/theming/fsh/theme.ini"
    if [[ -f $theme ]]; then
        if [[ ! -f "$FAST_WORK_DIR/current_theme.zsh" || $theme -nt "$FAST_WORK_DIR/current_theme.zsh" ]]; then
            fast-theme $theme
        fi
    elif [[ ! -f "$FAST_WORK_DIR/current_theme.zsh" ]]; then
        fast-theme clean
    fi
}

