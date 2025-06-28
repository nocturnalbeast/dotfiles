#!/usr/bin/env zsh

# Hook functions for zsh-you-should-use plugin

function atclone() {
    return 0
}

function atinit() {
    export YSU_HARDCORE_MODE=0
    export YSU_MESSAGE_FORMAT="$(tput setaf 3) $(tput bold)%alias_type$(tput sgr0) found for '$(tput setaf 5)$(tput bold)%command$(tput sgr0)' - '$(tput setaf 2)$(tput bold)%alias$(tput sgr0)'"
}

function atload() {
    return 0
}

