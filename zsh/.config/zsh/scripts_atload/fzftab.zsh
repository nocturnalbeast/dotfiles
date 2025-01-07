# use tmux popup instead of plain fzf
if command -v tmux &>/dev/null; then
    zstyle ':fzf-tab:*' fzf-command ftb-tmux-popup
    zstyle ':fzf-tab:*' popup-min-size 80 12
fi

# let fzf-tab take over
zstyle ':completion:*' menu no

# don't sort git checkout completions since it will mess up chronological order of commits
zstyle ':completion:*:git-checkout:*' sort false

# set header style for description
zstyle ':completion:*:descriptions' format '󰄾 %d'

# color all file/directory entries with LS_COLORS
zstyle ':completion:*' list-colors ${(s.:.)LS_COLORS}

# use Space to accept the match
zstyle ':fzf-tab:*' fzf-bindings 'space:accept'

# use continuous trigger using path separator
zstyle ':fzf-tab:*' continuous-trigger '/'

# use < > to switch between groups
zstyle ':fzf-tab:*' switch-group '<' '>'

# setup file preview - keep adding commands we might need preview for
local PREVIEW_SNIPPET='if [ -d $realpath ]; then eza -1 --color=always $realpath; elif [ -f $realpath ]; then bat -pp --color=always --line-range :30 $realpath; else exit; fi'
# ls / eza and aliases
zstyle ':fzf-tab:complete:eza:*' fzf-preview $PREVIEW_SNIPPET
zstyle ':fzf-tab:complete:ls:*' fzf-preview $PREVIEW_SNIPPET
zstyle ':fzf-tab:complete:ll:*' fzf-preview $PREVIEW_SNIPPET
zstyle ':fzf-tab:complete:la:*' fzf-preview $PREVIEW_SNIPPET
zstyle ':fzf-tab:complete:lt:*' fzf-preview $PREVIEW_SNIPPET
zstyle ':fzf-tab:complete:l.:*' fzf-preview $PREVIEW_SNIPPET
zstyle ':fzf-tab:complete:lal:*' fzf-preview $PREVIEW_SNIPPET
zstyle ':fzf-tab:complete:lsd:*' fzf-preview $PREVIEW_SNIPPET
zstyle ':fzf-tab:complete:lr:*' fzf-preview $PREVIEW_SNIPPET
zstyle ':fzf-tab:complete:lra:*' fzf-preview $PREVIEW_SNIPPET
zstyle ':fzf-tab:complete:lrl:*' fzf-preview $PREVIEW_SNIPPET
# cd / z and aliases
zstyle ':fzf-tab:complete:cd:*' fzf-preview $PREVIEW_SNIPPET
zstyle ':fzf-tab:complete:z:*' fzf-preview $PREVIEW_SNIPPET
zstyle ':fzf-tab:complete:zd:*' fzf-preview $PREVIEW_SNIPPET
# nvim / vim / vi and aliases
zstyle ':fzf-tab:complete:v:*' fzf-preview $PREVIEW_SNIPPET
zstyle ':fzf-tab:complete:nvim:*' fzf-preview $PREVIEW_SNIPPET
zstyle ':fzf-tab:complete:vim:*' fzf-preview $PREVIEW_SNIPPET
zstyle ':fzf-tab:complete:vi:*' fzf-preview $PREVIEW_SNIPPET
# cat / bat and aliases
zstyle ':fzf-tab:complete:c:*' fzf-preview $PREVIEW_SNIPPET
zstyle ':fzf-tab:complete:cat:*' fzf-preview $PREVIEW_SNIPPET
zstyle ':fzf-tab:complete:bat:*' fzf-preview $PREVIEW_SNIPPET
# other commands
zstyle ':fzf-tab:complete:rm:*' fzf-preview $PREVIEW_SNIPPET
zstyle ':fzf-tab:complete:cp:*' fzf-preview $PREVIEW_SNIPPET
zstyle ':fzf-tab:complete:mv:*' fzf-preview $PREVIEW_SNIPPET
zstyle ':fzf-tab:complete:less:*' fzf-preview $PREVIEW_SNIPPET
