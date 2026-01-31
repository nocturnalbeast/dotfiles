#!/usr/bin/env zsh

# append history to file rather than overwriting
setopt append_history
# remove older dups when trimming history
setopt hist_ignore_all_dups
# don't add dups to history list
setopt hist_ignore_dups
# don't add commands starting with space
setopt hist_ignore_space
# don't store history command in history
setopt hist_no_store
# remove extra blanks from commands
setopt hist_reduce_blanks
# don't add dups when writing history
setopt hist_save_no_dups
# share history between all sessions
setopt share_history
# execute expanded history immediately
unsetopt hist_verify
# save command timestamps and duration
setopt extended_history
# add | to output redirections in history
setopt hist_allow_clobber

# if atuin is present, use atuin for history management
if (( $+commands[atuin] )); then
    unset HISTFILE
    if (( $+functions[_evalcache] )); then
        _evalcache atuin init zsh --disable-up-arrow
    else
        eval "$(atuin init zsh --disable-up-arrow)"
    fi
    fc -R =(atuin search --cmd-only --limit 100)
    export ATUIN_INIT=1
else
    export HISTFILE="$XDG_CACHE_HOME/shell_history"
    export HISTSIZE=50000
    export SAVEHIST=50000
    export HISTORY_IGNORE="(ls|ls *|pwd|zsh|exit|clear|cls)"
    export ATUIN_INIT=0
fi

