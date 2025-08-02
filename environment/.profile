#!/usr/bin/env sh

source_profile_dir() {
    [ -d "$1" ] || return
    set -a
    for file in "$1"/*.sh; do
        [ -f "$file" ] || continue
        [ -f "$file.nosource" ] && continue
        # shellcheck disable=SC1090
        . "$file"
    done
    set +a
}

if [ -z "$__PROFILE_SOURCED" ]; then
    # shellcheck disable=SC1091
    [ -f /etc/profile ] && . /etc/profile

    source_profile_dir "${XDG_CONFIG_HOME:-$HOME/.config}/profile.d"
    source_profile_dir "$HOME/.profile.d"

    export __PROFILE_SOURCED=1
fi

if [ -z "$__GUIPROFILE_SOURCED" ]; then
    source_profile_dir "${XDG_CONFIG_HOME:-$HOME/.config}/profile.d/gui"
    source_profile_dir "$HOME/.profile.d/gui"

    export __GUIPROFILE_SOURCED=1
fi
