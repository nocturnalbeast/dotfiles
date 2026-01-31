#!/usr/bin/env zsh

# Cache command availability checks at startup for performance
typeset -g FTB_TMUX_POPUP_CMD="fzf-tmux"
typeset -g HAS_FD=0

if (( $+commands[ftb-tmux-popup] )); then
    FTB_TMUX_POPUP_CMD="ftb-tmux-popup"
fi

if (( ${+commands[fd]} )); then
    HAS_FD=1
fi

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
    local fzf_cmd="$FTB_TMUX_POPUP_CMD"
    local candidate

    if (( $#dirstack )); then
        candidate=${dirstack[1]#$PWD/}
    else
        candidate="$PWD"
    fi

    if [[ $candidate != */* ]]; then
        cd -q "$candidate"
    else
        local dir
        if (( HAS_FD )); then
            dir=$(fd -t d --follow . "$PWD" | $fzf_cmd +m --select-1 --exit-0 --header="Change directory to child from $PWD")
        else
            dir=$(find "$PWD" -mindepth 1 -type d -print | $fzf_cmd +m --select-1 --exit-0 --header="Change directory to child from $PWD")
        fi

        [[ -n "$dir" ]] && cd "$dir"
    fi

    redraw-prompt
}

zle -N cd-back
zle -N cd-forward
zle -N cd-up
zle -N cd-down
