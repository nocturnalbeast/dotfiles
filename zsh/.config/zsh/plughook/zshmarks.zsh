#!/usr/bin/env zsh

function atclone() {
    return 0
}

function atinit() {
    export BOOKMARKS_FILE="${XDG_DATA_HOME:-$HOME/.local/share}/zshmarks"
    alias cm="bookmark"
    alias dm="deletemark"
    alias sm="showmarks"
    alias md="jump"
}

function atload() {
    return 0
}
