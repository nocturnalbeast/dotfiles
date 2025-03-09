#!/usr/bin/env zsh

function atclone() {
    cp -f ~[git-extra-commands]/bin/* $ZPFX/bin
}

function atinit() {
    return 0
}

function atload() {
    path=(${path:#~[git-extra-commands]/bin})
}
