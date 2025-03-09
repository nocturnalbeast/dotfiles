#!/usr/bin/env zsh

function atclone() {
    cp -f ~[forgit]/bin/* $ZPFX/bin
    return 0
}

function atinit() {
    return 0
}

function atload() {
    export FORGIT_IGNORE_PAGER='bat -l gitignore --color always --style numbers'
    path=(${path:#~[forgit]/bin})
}
