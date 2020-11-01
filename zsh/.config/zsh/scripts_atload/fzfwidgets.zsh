autoload -Uz chpwd_recent_dirs cdr add-zsh-hook
add-zsh-hook chpwd chpwd_recent_dirs

bindkey '^A' fzf-select-widget
bindkey '^R' fzf-insert-history
bindkey '^F' fzf-insert-files
bindkey '^D' fzf-insert-directory
bindkey '^E' fzf-edit-files
bindkey '^K' fzf-kill-processes
