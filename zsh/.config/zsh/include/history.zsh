#!/usr/bin/env zsh

function _resolve_atuin_binary() {
    local bin_path

    bin_path=$(command -v atuin 2>/dev/null) && { echo "$bin_path"; return 0 }

    [[ -n "$AQUA_ROOT_DIR" && -x "$AQUA_ROOT_DIR/bin/atuin" ]] && { echo "$AQUA_ROOT_DIR/bin/atuin"; return 0 }

    [[ -x "$HOME/.local/share/aquaproj-aqua/bin/atuin" ]] && { echo "$HOME/.local/share/aquaproj-aqua/bin/atuin"; return 0 }

    return 1
}

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
if local ATUIN_BIN=$(_resolve_atuin_binary); then
    unset HISTFILE

    ATUIN_INIT_CACHE="${XDG_CACHE_HOME}/atuin-init.zsh"
    ATUIN_CACHE_DIR="${XDG_CACHE_HOME}/atuin"
    mkdir -p "$ATUIN_CACHE_DIR"

    function _atuin_get_cached_init() {
        local cache_valid=0

        if [[ -f "$ATUIN_INIT_CACHE" ]]; then
            local atuin_mtime
            local cache_mtime
            atuin_mtime=$(stat -c %Y "$ATUIN_BIN" 2>/dev/null || stat -f %m "$ATUIN_BIN")
            cache_mtime=$(stat -c %Y "$ATUIN_INIT_CACHE" 2>/dev/null || stat -f %m "$ATUIN_INIT_CACHE")

            if [[ $cache_mtime -ge $atuin_mtime ]]; then
                cache_valid=1
            fi
        fi

        if [[ $cache_valid -eq 1 ]]; then
            source "$ATUIN_INIT_CACHE"
        else
            mkdir -p "$(dirname "$ATUIN_INIT_CACHE")"
            "$ATUIN_BIN" init zsh --disable-up-arrow > "$ATUIN_INIT_CACHE"
            source "$ATUIN_INIT_CACHE"
        fi
    }

    function _atuin_load_initial_history() {
        fc -R =("$ATUIN_BIN" search --cmd-only --limit 100)
    }

    function _atuin_init_deferred() {
        zprofile_start "atuin_init_deferred_load"
        _atuin_get_cached_init
        zprofile_end "atuin_init_deferred_load"
        zprofile_start "atuin_load_history_deferred_load"
        _atuin_load_initial_history
        zprofile_end "atuin_load_history_deferred_load"
        unfunction _atuin_init_deferred _atuin_get_cached_init _atuin_load_initial_history 2>/dev/null
    }

    zprofile_start "atuin_init_defer_schedule"
    zsh-defer -dmszpr _atuin_init_deferred
    zprofile_end "atuin_init_defer_schedule"

    export ATUIN_INIT=1

else
    export HISTFILE="$XDG_CACHE_HOME/shell_history"
    export HISTSIZE=50000
    export SAVEHIST=50000
    export HISTORY_IGNORE="(ls|ls *|pwd|zsh|exit|clear|cls)"
    export ATUIN_INIT=0
fi

