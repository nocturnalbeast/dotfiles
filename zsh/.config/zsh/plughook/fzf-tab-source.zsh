#!/usr/bin/env zsh

function atclone() {
    return 0
}

function atinit() {
    return 0
}

function atload() {
    # configure fzf-tab-source behavior
    zstyle ':fzf-tab-source:*' fzf-command fzf
    zstyle ':fzf-tab-source:*' fzf-min-height 10
    zstyle ':fzf-tab-source:*' fzf-preview 'preview.sh {}'
    zstyle ':fzf-tab-source:*' fzf-flags --height=50% --preview-window=right:50%:wrap
    zstyle ':fzf-tab-source:*' fzf-bindings 'tab:accept'

    # configure preview for specific types
    zstyle ':fzf-tab-source:*:processes' preview 'ps -p {1} -o pid,ppid,user,comm,pcpu,pmem,time,cmd'
    zstyle ':fzf-tab-source:*:directories' preview 'ls -l --color=always {}'
    zstyle ':fzf-tab-source:*:files' preview 'bat --color=always --style=numbers --line-range=:500 {}'

    # disable preview for certain commands
    zstyle ':fzf-tab-source:(kill|ps):argument-rest' fzf-preview
    zstyle ':fzf-tab-source:systemctl:*' fzf-preview
}
