#!/usr/bin/env zsh

function atinit() {
    ZSH_AUTOSUGGEST_STRATEGY=(history match_prev_cmd completion)
    ZSH_AUTOSUGGEST_USE_ASYNC=1
    ZSH_AUTOSUGGEST_HIGHLIGHT_STYLE='fg=242,underline'
}

function atload() {
    _zsh_autosuggest_start
}

