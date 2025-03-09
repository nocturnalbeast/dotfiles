#!/usr/bin/env zsh

function atclone() {
    return 0
}

function atinit() {
    return 0
}

function atload() {
    HISTORY_SUBSTRING_SEARCH_FUZZY=true
    HISTORY_SUBSTRING_SEARCH_HIGHLIGHT_FOUND='fg=yellow,bold'
    HISTORY_SUBSTRING_SEARCH_HIGHLIGHT_NOT_FOUND='fg=red,bold'

    bindkey '^[[A' history-substring-search-up
    bindkey '^[[B' history-substring-search-down
}
