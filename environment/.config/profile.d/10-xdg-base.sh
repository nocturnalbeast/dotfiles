#!/usr/bin/env sh

## xdg base directory specification

# base user directories
export XDG_DATA_HOME="${XDG_DATA_HOME:-$HOME/.local/share}"
export XDG_STATE_HOME="${XDG_STATE_HOME:-$HOME/.local/state}"
export XDG_CACHE_HOME="${XDG_CACHE_HOME:-$HOME/.cache}"
export XDG_CONFIG_HOME="${XDG_CONFIG_HOME:-$HOME/.config}"

# other user directories from user-dirs.dirs
if [ -f "$XDG_CONFIG_HOME/user-dirs.dirs" ]; then
    set -a
    # shellcheck disable=SC1091
    . "$XDG_CONFIG_HOME/user-dirs.dirs"
    set +a
fi
