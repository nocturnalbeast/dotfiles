#!/usr/bin/env zsh

function atload() {
    zle -N autopair-insert
    zle -N autopair-close
    zle -N autopair-delete
    zle -N autopair-delete-word

    local p
    for p in ${(@k)AUTOPAIR_PAIRS}; do
        bindkey "$p" autopair-insert
        bindkey -M isearch "$p" self-insert

        local rchar="$(_ap-get-pair $p)"
        if [[ $p != $rchar ]]; then
            bindkey "$rchar" autopair-close
            bindkey -M isearch "$rchar" self-insert
        fi
    done

    bindkey '^?' autopair-delete
    bindkey '^H' autopair-delete-word
    bindkey -M isearch '^?' backward-delete-char
    bindkey -M isearch '^H' backward-kill-word
}

