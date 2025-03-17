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
HISTCONTROL=ignoreboth
HISTFILE="${XDG_CACHE_HOME:-$HOME/.cache}/shell_history"
HISTSIZE=50000

# prompt theme
eval "$(starship init bash)"
