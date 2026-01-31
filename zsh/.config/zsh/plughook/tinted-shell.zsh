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

    # define a function to easily change themes
    tinted() {
        local theme="$1"
        local type="${2:-auto}"

        if [[ -z "$theme" ]]; then
            echo "Usage: tinted <theme-name> [base16|base24|auto]"
            echo "Current theme: $TINTED_THEME"
            echo "Available themes:"
            echo "  Base16 themes:"
            for f in ~[tinted-shell]/scripts/base16-*.sh(N); do
                print "    ${f:t:r}"
            done | sort
            echo "  Base24 themes:"
            for f in ~[tinted-shell]/scripts/base24-*.sh(N); do
                print "    ${f:t:r}"
            done | sort
            return 1
        fi

        local full_theme=""

        # check if theme already includes prefix
        if [[ "$theme" == base16-* || "$theme" == base24-* ]]; then
            if [[ -f ~[tinted-shell]/scripts/$theme.sh ]]; then
                full_theme="$theme"
            fi
        else
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
        fi

        if [[ -n "$full_theme" ]]; then
            print -n "$full_theme" >| "$TINTED_SHELL_CACHE/current_theme"
            source ~[tinted-shell]/scripts/$full_theme.sh

            # apply theme with tinty if available
            if (( $+commands[tinty] )); then
                tinty apply "$full_theme" 2>/dev/null || true
            fi

            echo "Applied theme: $full_theme"
        else
            echo "Theme '$theme' not found"
            return 1
        fi
    }
}
