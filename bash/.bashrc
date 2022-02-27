#!/usr/bin/env bash

#  _           _
# | |_ ___ ___| |_
# | . | .'|_ -|   |
# |___|__,|___|_|_|

# just source .profile, it will source required environment variables and aliases
source "$HOME/.profile"

# make sure this is an interactive shell before setting up interactive shell preferences
[[ $- != *i* ]] && return

# shell-specific settings
shopt -s autocd
HISTCONTROL=ignoreboth
HISTFILE="${XDG_CACHE_HOME:-$HOME/.cache}/shell_history"
HISTSIZE=50000

# prompt theme
eval "$(starship init bash)"
