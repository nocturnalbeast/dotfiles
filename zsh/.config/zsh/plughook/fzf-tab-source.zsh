#!/usr/bin/env zsh

function atload() {
    # setup lesspipe
    if (( $+commands[lesspipe.sh] )); then
        if (( $+functions[_evalcache] )); then
            _evalcache lesspipe.sh
        else
            eval "$(lesspipe.sh)"
        fi
    fi
    path=(${path:#~[fzf-tab-source]/bin})
}
