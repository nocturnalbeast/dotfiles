#!/usr/bin/env bash

#  _           _
# | |_ ___ ___| |_
# | . | .'|_ -|   |
# |___|__,|___|_|_|

# source profile if it exists
if [[ -f "$HOME/.profile" ]]; then
    # shellcheck disable=SC1091
    source "$HOME/.profile"
fi

# source user aliases if it exists
if [[ -f "$XDG_CONFIG_HOME/shell/aliases" ]]; then
    # shellcheck disable=SC1091
    source "$XDG_CONFIG_HOME/shell/aliases"
fi

# make sure this is an interactive shell before setting up interactive shell preferences
[[ $- != *i* ]] && return

# shell-specific settings
shopt -s autocd

# prompt theme
eval "$(starship init bash)"

# if atuin is present, use atuin for history management
if command -v atuin > /dev/null 2>&1; then
    unset HISTFILE
    eval "$(atuin init bash --disable-up-arrow)"
    tmpfile=$(mktemp)
    atuin search --cmd-only --limit 100 > "$tmpfile"
    history -r "$tmpfile"
    rm -f "$tmpfile"
    export ATUIN_INIT=1
else
    export HISTFILE="$XDG_CACHE_HOME/shell_history"
    export HISTSIZE=50000
    export HISTFILESIZE=50000
    export HISTIGNORE="ls:ls *:pwd:exit:clear:cls:zsh"
    export ATUIN_INIT=0
fi
