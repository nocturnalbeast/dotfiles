#!/usr/bin/env zsh

function atclone() {
    return 0
}

function atinit() {
    # set default theme if not already set
    TINTED_THEME=${TINTED_THEME:-"base16-default-dark"}
   
    # create cache directory if it doesn't exist
    TINTED_SHELL_CACHE="$XDG_CACHE_HOME/tinted-shell"
    [[ ! -d "$TINTED_SHELL_CACHE" ]] && mkdir -p "$TINTED_SHELL_CACHE"
}

function atload() {
    # load theme from cache or use default
    [[ -f "$TINTED_SHELL_CACHE/current_theme" ]] && TINTED_THEME=$(cat "$TINTED_SHELL_CACHE/current_theme")
    
    # directly source the theme script
    [[ -n "$TINTED_THEME" && -f ~[tinted-shell]/scripts/$TINTED_THEME.sh ]] && \
        source ~[tinted-shell]/scripts/$TINTED_THEME.sh
    
    # define a function to easily change themes
    tinted() {
        local theme="$1"
        local type="${2:-auto}"
        
        if [[ -z "$theme" ]]; then
            echo "Usage: tinted <theme-name> [base16|base24|auto]"
            echo "Current theme: $TINTED_THEME"
            echo "Available themes:"
            echo "  Base16 themes:"
            command ls -1 ~[tinted-shell]/scripts/base16-*.sh 2>/dev/null | sed 's/^.*\(base16-.*\)\.sh$/    \1/' | sort
            echo "  Base24 themes:"
            command ls -1 ~[tinted-shell]/scripts/base24-*.sh 2>/dev/null | sed 's/^.*\(base24-.*\)\.sh$/    \1/' | sort
            return 1
        fi
        
        local full_theme=""
        
        if [[ "$type" == "base16" || "$type" == "auto" ]]; then
            if [[ -f ~[tinted-shell]/scripts/base16-$theme.sh ]]; then
                full_theme="base16-$theme"
            fi
        fi
        
        if [[ "$type" == "base24" || ("$type" == "auto" && -z "$full_theme") ]]; then
            if [[ -f ~[tinted-shell]/scripts/base24-$theme.sh ]]; then
                full_theme="base24-$theme"
            fi
        fi
        
        if [[ -n "$full_theme" ]]; then
            print -n "$full_theme" >| "$TINTED_SHELL_CACHE/current_theme"
            source ~[tinted-shell]/scripts/$full_theme.sh
            echo "Applied theme: $full_theme"
        else
            echo "Theme '$theme' not found"
            return 1
        fi
    }
}
