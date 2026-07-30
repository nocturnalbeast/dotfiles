#!/usr/bin/env zsh

function atinit() {
    ZSHZ_DATA="$XDG_CACHE_HOME/zsh-z"
    ZSHZ_TILDE=1

    # zsh-z outputs completions in frecency order (via compadd -V zsh-z), but
    # fzf sorts alphabetically by default. --no-sort tells fzf to preserve the
    # input order (frecency ranking), filtering only by the query string.
    zstyle ':fzf-tab:complete:z:*' fzf-flags '--no-sort'
    zstyle ':completion:*:*:z:*' sort false
}

