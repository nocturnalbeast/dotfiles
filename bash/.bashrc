#!/usr/bin/env bash

#  _           _
# | |_ ___ ___| |_
# | . | .'|_ -|   |
# |___|__,|___|_|_|

# setting up history file
HISTFILE="${XDG_CACHE_HOME:-$HOME/.cache}/shell_history"
HISTSIZE=50000

# import environment variables
source "${XDG_CONFIG_HOME:-$HOME/.config}/shell/env"

# import aliases
source "${XDG_CONFIG_HOME:-$HOME/.config}/shell/aliases"

#starship_precmd_user_func="set_win_title"
# prompt theme
eval "$(starship init bash)"
