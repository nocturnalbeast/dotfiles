#!/usr/bin/env zsh

function atclone() {
    cp -f ~[git-open]/git-open $ZPFX/bin
}

function atload() {
    path=(${path:#~[git-open]})
}
