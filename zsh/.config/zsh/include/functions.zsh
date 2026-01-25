#!/usr/bin/env zsh

function redraw-prompt() {
    emulate -L zsh
    local f
    for f in chpwd $chpwd_functions precmd $precmd_functions; do
        (($+functions[$f])) && $f &> /dev/null
    done
    zle .reset-prompt
    zle -R
}

function cd-rotate() {
    emulate -L zsh
    while (($#dirstack)) && ! pushd -q $1 &> /dev/null; do
        popd -q $1
    done
    if (($#dirstack)); then
        redraw-prompt
    fi
}

function cd-back() {
    cd-rotate +1
}

function cd-forward() {
    cd-rotate -0
}

function cd-up() {
    cd .. && redraw-prompt
}

function cd-down() {
    local candidate=${dirstack[1]#$PWD/}
    local fzf_cmd="fzf-tmux"
    if [[ $candidate != */* ]]; then
        cd -q "$candidate" && redraw-prompt
    else
        command -v ftb-tmux-popup &> /dev/null && fzf_cmd="ftb-tmux-popup"
        local -a dirs
        dirs=(${1}/**/*(/ND))
        dirs=(${dirs#$1/})
        dir=$(printf '%s\n' ${dirs[@]} | $fzf_cmd +m --header="Change directory to child from $PWD" --exit-0) && cd "$dir"
    fi
    redraw-prompt
}

zle -N cd-back
zle -N cd-forward
zle -N cd-up
zle -N cd-down
