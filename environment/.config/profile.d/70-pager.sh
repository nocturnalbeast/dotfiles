#!/usr/bin/env sh

## pager settings

export PAGER="less -RF --mouse"
export LESSHISTFILE=-
export MANPAGER="sh -c 'col -bx | bat -l man -p'"
export BAT_PAGER="$PAGER"
export DELTA_PAGER="$PAGER"
# fix formatting with bat while using as man pager
export MANROFFOPT="-c"
