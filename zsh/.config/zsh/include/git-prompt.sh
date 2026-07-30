#!/hint/sh
# git-prompt.sh — async comprehensive git status for starship prompt
#
# Replaces starship's [git_branch], [git_commit], [git_state],
# [git_metrics], and [git_status] modules. All git operations run in a
# background process; the prompt reads cached results via [env_var.*]
# modules (<1ms per render regardless of repo size).
#
# Exports RAW values (branch name, status glyphs, metrics numbers) — no
# ANSI codes. starship's env_var format strings apply the styling.

# per-shell cache (avoids write conflicts between concurrent shells)
_GSD_CACHE="${XDG_CACHE_HOME:-$HOME/.cache}/zsh/gsd-prompt.$$"
_GSD_TS=0

# initialize env vars — unset so starship skips modules until first computation
unset GSD_BRANCH GSD_STATUS GSD_ADDED GSD_DELETED GSD_STATE

# source results from the previous background computation
__gsd_collect() {
    [ -f "$_GSD_CACHE" ] || return 0
    . "$_GSD_CACHE"
    rm -f "$_GSD_CACHE"
}

# spawn background computation (throttled to once per second)
__gsd_compute() {
    local _now
    _now=$(date +%s 2> /dev/null || echo 0)
    [ $((_now - _GSD_TS)) -lt 1 ] && return 0
    _GSD_TS=$_now

    # only in git repos
    git rev-parse --git-dir > /dev/null 2>&1 || {
        unset GSD_BRANCH GSD_STATUS GSD_ADDED GSD_DELETED GSD_STATE
        return 0
    }

    # background: compute in orphaned subshell (no job notifications)
    # outer ( ) exits immediately, orphaning the inner & job so neither
    # bash nor zsh tracks it — no [N] PID or "done" notifications
    ( (
        # ━━━ Nerd Font symbols for status (matching starship.toml) ━━━
        _S_CONFLICT=$'\U000f0b65'
        _S_STAGED=$'\uf067'
        _S_MODIFIED=$'\U000f1238'
        _S_UNTRACKED=$'\uf128'
        _S_AHEAD=$'\uf062'
        _S_BEHIND=$'\uf063'
        _S_STASHED=$'\U000f0613'

        # ━━━ Get status (single call: branch + file statuses) ━━━
        _porcelain=$(git status --porcelain=v2 --branch 2> /dev/null)

        # ━━━ Parse branch / upstream / ahead-behind ━━━
        _branch=$(printf '%s\n' "$_porcelain" | awk '/^# branch.head/{print $3}')
        _remote=$(printf '%s\n' "$_porcelain" | awk '/^# branch.upstream/{split($3,a,"/");print a[1]}')
        _ahead=$(printf '%s\n' "$_porcelain" | awk '/^# branch.ab/{gsub(/\+/,"",$3);print $3+0}')
        _behind=$(printf '%s\n' "$_porcelain" | awk '/^# branch.ab/{gsub(/-/,"",$4);print $4+0}')

        # ━━━ Parse file status counts ━━━
        _staged=$(printf '%s\n' "$_porcelain" | awk '/^[12]/{x=substr($2,1,1);if(x!="."&&x!=" "&&x!="?")c++}END{print c+0}')
        _unstaged=$(printf '%s\n' "$_porcelain" | awk '/^[12]/{y=substr($2,2,1);if(y!="."&&y!=" "&&y!="?")c++}END{print c+0}')
        _conflicted=$(printf '%s\n' "$_porcelain" | awk '/^u /{c++}END{print c+0}')
        _untracked=$(printf '%s\n' "$_porcelain" | awk '/^\?/{c++}END{print c+0}')

        # ━━━ Stash count ━━━
        _stashes=$(git stash list 2> /dev/null | wc -l | tr -d '[:space:]')

        # ━━━ Repo state ━━━
        _gitdir=$(git rev-parse --git-dir 2> /dev/null)
        _state=""
        if [ -d "$_gitdir/rebase-merge" ] || [ -d "$_gitdir/rebase-apply" ]; then
            _state="RBS"
            if [ -f "$_gitdir/rebase-merge/msgnum" ]; then
                _cur=$(cat "$_gitdir/rebase-merge/msgnum" 2> /dev/null || echo 0)
                _tot=$(cat "$_gitdir/rebase-merge/end" 2> /dev/null || echo 0)
                [ "$_cur" -gt 0 ] 2> /dev/null && _state="RBS $_cur/$_tot"
            elif [ -f "$_gitdir/rebase-apply/next" ]; then
                _cur=$(cat "$_gitdir/rebase-apply/next" 2> /dev/null || echo 0)
                _tot=$(cat "$_gitdir/rebase-apply/last" 2> /dev/null || echo 0)
                [ "$_cur" -gt 0 ] 2> /dev/null && _state="RBS $_cur/$_tot"
            fi
        elif [ -f "$_gitdir/MERGE_HEAD" ]; then
            _state="MRG"
        elif [ -f "$_gitdir/CHERRY_PICK_HEAD" ]; then
            _state="CHP"
        elif [ -f "$_gitdir/REVERT_HEAD" ]; then
            _state="RVT"
        elif [ -f "$_gitdir/BISECT_LOG" ]; then
            _state="BIS"
        fi

        # ━━━ Line-count diff ━━━
        _stats=$(git diff --shortstat 2> /dev/null)
        _added=$(printf '%s' "$_stats" | grep -oE '[0-9]+ insertion' | head -1 | grep -oE '[0-9]+')
        _deleted=$(printf '%s' "$_stats" | grep -oE '[0-9]+ deletion' | head -1 | grep -oE '[0-9]+')

        # ━━━ Build raw values (starship format strings apply styling) ━━━

        # Branch: "remote/branch" or short hash (detached)
        if [ -n "$_branch" ]; then
            if [ "$_branch" = "(detached)" ]; then
                _branch_val=$(git rev-parse --short HEAD 2> /dev/null || echo "")
            else
                _branch_val="${_remote:+$_remote/}${_branch}"
            fi
        else
            _branch_val=""
        fi

        # Status: concatenated Nerd Font glyphs
        _status_val=""
        [ "$_conflicted" -gt 0 ] 2> /dev/null && _status_val="${_status_val}${_S_CONFLICT}"
        [ "$_staged" -gt 0 ] 2> /dev/null && _status_val="${_status_val}${_S_STAGED}"
        [ "$_unstaged" -gt 0 ] 2> /dev/null && _status_val="${_status_val}${_S_MODIFIED}"
        [ "$_untracked" -gt 0 ] 2> /dev/null && _status_val="${_status_val}${_S_UNTRACKED}"
        [ "$_stashes" -gt 0 ] 2> /dev/null && _status_val="${_status_val}${_S_STASHED}"
        [ "$_ahead" -gt 0 ] 2> /dev/null && _status_val="${_status_val}${_S_AHEAD}"
        [ "$_behind" -gt 0 ] 2> /dev/null && _status_val="${_status_val}${_S_BEHIND}"

        # ━━━ Write cache file (atomic: temp + rename) ━━━
        _tmp="${_GSD_CACHE}.tmp"
        {
            [ -n "$_branch_val" ] && printf 'export GSD_BRANCH=%s\n' "'$_branch_val'" || printf 'unset GSD_BRANCH\n'
            [ -n "$_status_val" ] && printf 'export GSD_STATUS=%s\n' "'$_status_val'" || printf 'unset GSD_STATUS\n'
            [ -n "$_added" ] && printf 'export GSD_ADDED=%s\n' "'$_added'" || printf 'unset GSD_ADDED\n'
            [ -n "$_deleted" ] && printf 'export GSD_DELETED=%s\n' "'$_deleted'" || printf 'unset GSD_DELETED\n'
            [ -n "$_state" ] && printf 'export GSD_STATE=%s\n' "'$_state'" || printf 'unset GSD_STATE\n'
        } > "$_tmp"
        mv -f "$_tmp" "$_GSD_CACHE"
        # notify main shell via FIFO (zle -F handler fires only when ZLE is idle)
        [ -p "$_GSD_NOTIFY" ] && printf '.\n' > "$_GSD_NOTIFY" 2> /dev/null
    ) > /dev/null 2>&1 &)
}

# main hook: collect previous results, spawn new computation
__gsd_hook() {
    __gsd_collect
    __gsd_compute
}

# ━━━ FIFO + zle -F: async prompt redraw without signals ━━━
# zle -F handlers ONLY fire when ZLE is idle (at the prompt), so
# zle reset-prompt is always safe — no crashes from calling it
# during command execution or PROMPT evaluation.
# bash fallback: no auto-redraw; next prompt shows updated info.

_GSD_NOTIFY="${XDG_CACHE_HOME:-$HOME/.cache}/zsh/gsd-notify.$$"

# set up the FIFO and ZLE watcher (zsh only)
if [ -n "${ZSH_VERSION:-}" ]; then
    [ -p "$_GSD_NOTIFY" ] || mkfifo "$_GSD_NOTIFY" 2> /dev/null
    # open read-write so the open doesn't block waiting for a writer
    exec {_GSD_NOTIFY_FD}<> "$_GSD_NOTIFY"

    _gsd_zle_watcher() {
        local _junk
        read -rs -u $_GSD_NOTIFY_FD _junk # drain the pipe
        __gsd_collect
        zle reset-prompt
    }
    zle -F "$_GSD_NOTIFY_FD" _gsd_zle_watcher
fi
