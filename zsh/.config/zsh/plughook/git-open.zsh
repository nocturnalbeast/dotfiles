#!/usr/bin/env zsh

function atclone() {
    cp -f ~[git-open]/git-open $ZPFX/bin
}

function atinit() {
    return 0
}

function atload() {
    path=(${path:#~[git-open]})
}
