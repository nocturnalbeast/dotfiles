#!/usr/bin/env zsh

function atclone() {
    cd ~[git-extras]
    echo y | make install PREFIX=$ZPFX
    cd -
}

function atinit() {
    return 0
}

function atload() {
    path=(${path:#~[git-extras]/bin})
}
