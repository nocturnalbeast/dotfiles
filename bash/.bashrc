#!/bin/bash

#  _           _
# | |_ ___ ___| |_
# | . | .'|_ -|   |
# |___|__,|___|_|_|

# setting up history file
HISTFILE="$HOME/.cache/shell_history"
HISTSIZE=50000

# import environment variables
source "$HOME/.config/shell/env"

# import aliases
source "$HOME/.config/shell/aliases"

#starship_precmd_user_func="set_win_title"
# prompt theme
eval "$(starship init bash)"
