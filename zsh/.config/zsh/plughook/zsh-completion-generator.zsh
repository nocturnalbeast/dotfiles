#!/usr/bin/env zsh

function atclone() {
    return 0
}

function atinit() {
    GENCOMPL_FPATH="${ZINIT_HOME:-$XDG_DATA_HOME/zinit}/completions"
    GENCOMPL_PY=python3
    zstyle :plugin:zsh-completion-generator programs tr
}

function atload() {
    return 0
}
