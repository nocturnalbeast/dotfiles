#!/usr/bin/env zsh

# XDG base directory specification
# needed by all programs, not just interactive shells
typeset -gx XDG_DATA_HOME=${XDG_DATA_HOME:-"$HOME/.local/share"}
typeset -gx XDG_STATE_HOME=${XDG_STATE_HOME:-"$HOME/.local/state"}
typeset -gx XDG_CACHE_HOME=${XDG_CACHE_HOME:-"$HOME/.cache"}
typeset -gx XDG_CONFIG_HOME=${XDG_CONFIG_HOME:-"$HOME/.config"}

# deduplicate PATH for all zsh processes
typeset -gU PATH path
