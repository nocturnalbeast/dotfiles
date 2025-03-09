#!/usr/bin/env zsh

function atclone() {
    return 0
}

function atinit() {
    return 0
}

function atload() {
    # use tmux popup instead of plain fzf
    if command -v tmux &>/dev/null && [[ -n "$TMUX" ]]; then
        zstyle ':fzf-tab:*' fzf-command ftb-tmux-popup
        zstyle ':fzf-tab:*' popup-min-size 80 12
    fi

    zstyle -d ':completion:*' format

    # let fzf-tab take over
    zstyle ':completion:*' menu no

    # don't sort git checkout completions since it will mess up chronological order of commits
    zstyle ':completion:*:git-checkout:*' sort false

    # set header style for description
    zstyle ':completion:*:descriptions' format '󰄾 %d'

    # color all file/directory entries with LS_COLORS
    zstyle ':completion:*' list-colors ${(s.:.)LS_COLORS}

    # key bindings
    zstyle ':fzf-tab:*' accept-line enter
    zstyle ':fzf-tab:*' continuous-trigger '/'
    zstyle ':fzf-tab:*' fzf-bindings 'ctrl-u:preview-half-page-up' 'ctrl-d:preview-half-page-down' 'space:accept' 'alt-k:page-up' 'alt-j:page-down'
    zstyle ':fzf-tab:*' switch-group '<' '>'

    # use-fzf-default-opts (TODO: this needs to be replaced with opts copied here)
    zstyle ':fzf-tab:*' use-fzf-default-opts yes

    # options preview
    zstyle ':fzf-tab:complete:*:options' fzf-preview '/usr/bin/echo Description:; /usr/bin/echo option: $desc | sed -e "s/\s\{3,\}/\n/g"'
    zstyle ':fzf-tab:complete:(-command-|-parameter-|-brace-parameter-|export|unset|expand):*' fzf-preview 'echo ${(P)word}'

    # git preview
    zstyle ':fzf-tab:complete:git-(add|diff|restore):*' fzf-preview 'git diff $word | delta'
    zstyle ':fzf-tab:complete:git-log:*' fzf-preview 'git log --color=always $word'
    zstyle ':fzf-tab:complete:git-help:*' fzf-preview 'git help $word | bat -plman --color=always'
    zstyle ':fzf-tab:complete:git-show:*' fzf-preview \
        'case "$group" in
        "commit tag") git show --color=always $word ;;
        *) git show --color=always $word | delta ;;
        esac'
    zstyle ':fzf-tab:complete:git-checkout:*' fzf-preview \
        'case "$group" in
        "modified file") git diff $word | delta ;;
        "recent commit object name") git show --color=always $word | delta ;;
        *) git log --color=always $word ;;
        esac'

    # process preview
    zstyle ':fzf-tab:complete:(kill|ps):argument-rest' fzf-preview '[[ $group == "[process ID]" ]] && ps --pid=$word -o cmd --no-headers -w -w'
    zstyle ':fzf-tab:complete:(kill|ps):argument-rest' fzf-flags --preview-window=down:3:wrap

    # man preview
    zstyle ':fzf-tab:complete:(\\|)run-help:*' fzf-preview 'run-help $word'
    zstyle ':fzf-tab:complete:(\\|*/|)man:*' fzf-preview 'man $word'
}

