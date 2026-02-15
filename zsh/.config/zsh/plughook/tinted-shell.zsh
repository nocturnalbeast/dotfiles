#!/usr/bin/env zsh

function atinit() {
    # set default theme if not already set
    TINTED_THEME=${TINTED_THEME:-"base16-default-dark"}

    # create cache directory if it doesn't exist
    TINTED_SHELL_CACHE="$XDG_CACHE_HOME/tinted-shell"
    [[ ! -d "$TINTED_SHELL_CACHE" ]] && mkdir -p "$TINTED_SHELL_CACHE"
}

function atload() {
    # load theme from cache or use default
    [[ -f "$TINTED_SHELL_CACHE/current_theme" ]] && TINTED_THEME=$(<$TINTED_SHELL_CACHE/current_theme)

    # directly source the theme script
    [[ -n "$TINTED_THEME" && -f ~[tinted-shell]/scripts/$TINTED_THEME.sh ]] && \
        source ~[tinted-shell]/scripts/$TINTED_THEME.sh


}
