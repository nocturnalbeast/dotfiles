#!/bin/bash

#  _           _
# | |_ ___ ___| |_
# | . | .'|_ -|   |
# |___|__,|___|_|_|

# setup a prompt that looks similar to zsh prompt
COL_CURSOR='\e[35m'
COL_CURRENT_PATH='\e[34m'
COL_GIT_STATUS_CLEAN='\e[93m'
COL_GIT_STATUS_CHANGES='\e[92m'
RESET='\e[0m'
BOLD='\e[1m'

parse_git_branch() {
    git branch 2> /dev/null | sed -e '/^[^*]/d' -e 's/* \(.*\)/\1/'
}

check_for_git_changes() {
    if [[ "$(parse_git_branch)" ]]; then
        if [[ $(git status --porcelain) ]]; then
            echo ${COL_GIT_STATUS_CLEAN}
        else
            echo ${COL_GIT_STATUS_CHANGES}
        fi
    fi
}

setup_prompt() {
    PS1="${RESET}${COL_CURRENT_PATH}\w $(check_for_git_changes)$(parse_git_branch)\n${COL_CURSOR}❯❯ ${RESET}"
}

PROMPT_COMMAND=setup_prompt

# setting up history file
HISTFILE="$HOME/.cache/shell_history"
HISTSIZE=50000

# import environment variables
source "$HOME/.config/shell/env"

# import aliases
source "$HOME/.config/shell/aliases"
