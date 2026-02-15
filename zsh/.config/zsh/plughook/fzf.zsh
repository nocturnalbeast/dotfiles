#!/usr/bin/env zsh

function atclone() {
    (( ${+commands[fzf]} )) || ~[fzf]/install --bin
    cp -f ~[fzf]/bin/* $ZPFX/bin
}

function atinit() {
    # use alternate sequence since ** will expand paths
    export FZF_COMPLETION_TRIGGER='~~'
    # 80% seems to be good in most sizes and doesn't hide the actual prompt
    export FZF_DEFAULT_HEIGHT='80%'
    export FZF_TMUX_HEIGHT='80%'
    # layout options only; colors are sourced from tinty cache
    export FZF_DEFAULT_OPTS=$FZF_DEFAULT_OPTS' --height ~80% --cycle --highlight-line --wrap --style="full:thinblock" --scrollbar="│" --layout="reverse" --prompt="󰉁 " --marker="󰄬 " --pointer="󰋇 "'
    # source cached fzf theme from tinty
    [[ -f ~/.cache/tinted-fzf/theme.sh ]] && source ~/.cache/tinted-fzf/theme.sh
    # make sure that directory completion and file completion uses fd instead
    export FZF_DEFAULT_COMMAND='fd --hidden --follow --type=f'
    _fzf_compgen_path() {
        fd --hidden --follow --type=f
    }
    export FZF_ALT_C_COMMAND='fd --hidden --follow --type=d'
    _fzf_compgen_dir() {
        fd --hidden --follow --type=d
    }
}

function atload() {
    path=(${path:#~[fzf]/bin})
}

