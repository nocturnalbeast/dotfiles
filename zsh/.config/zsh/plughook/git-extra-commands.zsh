#!/usr/bin/env zsh

function atclone() {
    cp -f ~[git-extra-commands]/bin/* $ZPFX/bin
}

function atload() {
    path=(${path:#~[git-extra-commands]/bin})
}
