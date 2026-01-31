#!/usr/bin/env zsh

# Hook functions for zsh-you-should-use plugin

function atinit() {
    export YSU_HARDCORE_MODE=0
    # Pre-compute tput color codes to avoid subprocess calls
    export YSU_YELLOW="$(tput setaf 3)"
    export YSU_BOLD="$(tput bold)"
    export YSU_RESET="$(tput sgr0)"
    export YSU_MAGENTA="$(tput setaf 5)"
    export YSU_GREEN="$(tput setaf 2)"
    export YSU_MESSAGE_FORMAT="${YSU_YELLOW} ${YSU_BOLD}%alias_type${YSU_RESET} found for '${YSU_MAGENTA}${YSU_BOLD}%command${YSU_RESET}' - '${YSU_GREEN}${YSU_BOLD}%alias${YSU_RESET}'"
}

