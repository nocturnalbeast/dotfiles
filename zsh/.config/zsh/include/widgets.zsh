#!/usr/bin/env zsh

# default key bindings for fzf widgets
ZSH_FZF_PASTE_KEY=${ZSH_FZF_PASTE_KEY:-'space'}
ZSH_FZF_EXEC_KEY=${ZSH_FZF_EXEC_KEY:-'enter'}
ZSH_FZF_EXTRA_PASTE_KEYS=${ZSH_FZF_EXTRA_PASTE_KEYS:-'right'}

# Cache command availability check at startup for performance
typeset -g HAS_FD=0

if (( ${+commands[fd]} )); then
    HAS_FD=1
fi

# interactive directory navigation with fzf
fzf-cd() {
    local cmd output ret

    if (( HAS_FD )); then
        cmd=(fd --type d --min-depth 1 --follow --exclude '.*' --exclude '/dev/*' --exclude '/proc/*' --exclude '/sys/*')
    else
        cmd=(find -L . -mindepth 1 \( -path '*/\.*' -o -fstype 'sysfs' -o -fstype 'devfs' -o -fstype 'devtmpfs' -o -fstype 'proc' \) -prune -o -type d -print)
    fi

    output=$($cmd 2>/dev/null | fzf --expect=$ZSH_FZF_EXEC_KEY,$ZSH_FZF_PASTE_KEY,$ZSH_FZF_EXTRA_PASTE_KEYS \
      --header="Navigate directories - ${ZSH_FZF_EXEC_KEY}:cd to dir, ${ZSH_FZF_PASTE_KEY}/${ZSH_FZF_EXTRA_PASTE_KEYS}:insert path")
    ret=$?

    [[ -n "$WIDGET" ]] && zle reset-prompt

    if [[ $ret -eq 0 ]]; then
        local -a output_lines
        output_lines=(${(f)output})
        local action=$output_lines[1]
        local selection=${output_lines[2,-1]}

        if [[ -n "$selection" ]]; then
            if [[ "$action" == "$ZSH_FZF_EXEC_KEY" ]] && [[ -n "$WIDGET" ]]; then
                BUFFER="cd \"$selection\""
                zle redisplay
                zle accept-line
            elif [[ "$action" == "$ZSH_FZF_PASTE_KEY" || "$action" == "$ZSH_FZF_EXTRA_PASTE_KEYS" ]] && [[ -n "$WIDGET" ]]; then
                LBUFFER+="$selection"
                zle redisplay
            else
                echo "$selection"
            fi
        fi
    fi

    return $ret
}
zle -N fzf-cd

# interactive history search with fzf
fzf-history() {
    local output ret

    output=$(fc -rl 1 | fzf --expect=$ZSH_FZF_EXEC_KEY,$ZSH_FZF_PASTE_KEY,$ZSH_FZF_EXTRA_PASTE_KEYS --query="$LBUFFER" \
      --header="Search history - ${ZSH_FZF_EXEC_KEY}:execute command, ${ZSH_FZF_PASTE_KEY}/${ZSH_FZF_EXTRA_PASTE_KEYS}:insert command" \
      --tiebreak=index -n2..,.. --no-sort)
    ret=$?

    [[ -n "$WIDGET" ]] && zle reset-prompt

    if [[ $ret -eq 0 ]]; then
        local -a output_lines
        output_lines=(${(f)output})
        local action=$output_lines[1]
        local cmd=${output_lines[-1]##[[:space:]]#[0-9]##[[:space:]]#}

        if [[ "$action" == "$ZSH_FZF_EXEC_KEY" ]] && [[ -n "$WIDGET" ]]; then
            BUFFER="$cmd"
            zle redisplay
            zle accept-line
        elif [[ "$action" == "$ZSH_FZF_PASTE_KEY" || "$action" == "$ZSH_FZF_EXTRA_PASTE_KEYS" ]] && [[ -n "$WIDGET" ]]; then
            LBUFFER+="$cmd"
            zle redisplay
        else
            echo "$cmd"
        fi
    fi

    return $ret
}
zle -N fzf-history

# interactive process killing by pid with fzf
fzf-kill-proc-by-list() {
    local cmd output ret

    cmd="ps -f -u $UID"
    [[ "$UID" == '0' ]] && cmd="ps -ef"

    output=$(${=cmd} | fzf --expect=$ZSH_FZF_EXEC_KEY,$ZSH_FZF_PASTE_KEY,$ZSH_FZF_EXTRA_PASTE_KEYS \
      --header="Select process to kill - ${ZSH_FZF_PASTE_KEY}/${ZSH_FZF_EXTRA_PASTE_KEYS}:copy PID, ${ZSH_FZF_EXEC_KEY}:kill -9 PID")
    ret=$?

    [[ -n "$WIDGET" ]] && zle reset-prompt

    if [[ $ret -eq 0 ]]; then
        local -a output_lines
        output_lines=(${(f)output})
        local action=$output_lines[1]
        local selected=$output_lines[-1]
        local -a selected_parts
        selected_parts=(${=selected})
        local pid=$selected_parts[2]

        if [[ "$action" == "$ZSH_FZF_EXEC_KEY" ]] && [[ -n "$WIDGET" ]]; then
            BUFFER="kill -9 $pid"
            zle redisplay
            zle accept-line
        elif [[ "$action" == "$ZSH_FZF_PASTE_KEY" || "$action" == "$ZSH_FZF_EXTRA_PASTE_KEYS" ]] && [[ -n "$WIDGET" ]]; then
            LBUFFER+="$pid"
            zle redisplay
        else
            echo "$pid"
        fi
    fi

    return $ret
}
zle -N fzf-kill-proc-by-list

# interactive process killing by port with fzf
fzf-kill-proc-by-port() {
    local output ret

    output=$(sudo ss -natup | fzf --expect=$ZSH_FZF_EXEC_KEY,$ZSH_FZF_PASTE_KEY,$ZSH_FZF_EXTRA_PASTE_KEYS \
      --header="Select process by port - ${ZSH_FZF_PASTE_KEY}/${ZSH_FZF_EXTRA_PASTE_KEYS}:copy PID, ${ZSH_FZF_EXEC_KEY}:kill -9 PID")
    ret=$?

    [[ -n "$WIDGET" ]] && zle reset-prompt

    if [[ $ret -eq 0 ]]; then
        local -a output_lines
        output_lines=(${(f)output})
        local action=$output_lines[1]
        local selected=$output_lines[-1]
        local pid
        [[ $selected =~ 'pid=([0-9]+),' ]]
        pid=$match[1]

        if [[ "$action" == "$ZSH_FZF_EXEC_KEY" ]] && [[ -n "$WIDGET" ]]; then
            BUFFER="sudo kill -9 $pid"
            zle redisplay
            zle accept-line
        elif [[ "$action" == "$ZSH_FZF_PASTE_KEY" || "$action" == "$ZSH_FZF_EXTRA_PASTE_KEYS" ]] && [[ -n "$WIDGET" ]]; then
            LBUFFER+="$pid"
            zle redisplay
        else
            echo "$pid"
        fi
    fi

    return $ret
}
zle -N fzf-kill-proc-by-port

# interactive theme selection with fzf and live preview
fzf-tinted-theme() {
    local output ret theme_type
    local TINTED_SHELL_PATH="${XDG_DATA_HOME:-$HOME/.local/share}/zsh/zcomet/repos/tinted-theming/tinted-shell"
    local TINTED_CACHE="${XDG_CACHE_HOME:-$HOME/.cache}/tinted-shell"
    local original_theme=""

    if [[ -f "$TINTED_CACHE/current_theme" ]]; then
        original_theme=$(<$TINTED_CACHE/current_theme)
    fi

    local preview_cmd='local sel={}; THEME=${${sel}##[[:space:]]#}; '
    preview_cmd+="THEME_PATH=\$(find $TINTED_SHELL_PATH/scripts/\$THEME.sh -type f 2>/dev/null); "
    preview_cmd+="if [[ -n \$THEME_PATH ]]; then "
    preview_cmd+="source \$THEME_PATH; "

    preview_cmd+="echo \"\033[1;37mTheme: \$THEME\033[0m\n\"; "

    preview_cmd+="echo -en \"\n Panes:\n\n \"; "
    for i in {0..7}; do
        preview_cmd+="echo -en \"\033[38;5;${i}m███\033[38;5;$((8 + i))m▄\033[0m  \"; "
    done
    preview_cmd+="echo -en \"\n \"; "
    for i in {0..7}; do
        preview_cmd+="echo -en \"\033[38;5;${i}m███\033[38;5;$((8 + i))m█\033[38;5;$((16 + i))m█\033[0m \"; "
    done
    preview_cmd+="echo -en \"\n \"; "
    for i in {0..7}; do
        preview_cmd+="echo -en \"\033[38;5;$((8 + i))m ▀\033[48;5;$((16 + i))m▀▀\033[38;5;$((16 + i))m█\033[0m \"; "
    done
    preview_cmd+="echo -e \"\033[0m\"; "

    preview_cmd+="echo -en \"\n Blocks:\n\n \"; "
    for i in {0..7}; do
        preview_cmd+="echo -en \"\033[38;5;${i}m███ \"; "
    done
    preview_cmd+="echo -en \"\033[0m\n \"; "
    for i in {8..15}; do
        preview_cmd+="echo -en \"\033[38;5;${i}m███ \"; "
    done
    preview_cmd+="echo -en \"\033[0m\n \"; "
    for i in {16..23}; do
        preview_cmd+="echo -en \"\033[38;5;${i}m███ \"; "
    done
    preview_cmd+="echo -e \"\033[0m\"; "

    preview_cmd+="fi"

    output=$(printf '%s\n' $TINTED_SHELL_PATH/scripts/*.sh(:t:r) | sort | \
              fzf --expect=$ZSH_FZF_EXEC_KEY,$ZSH_FZF_PASTE_KEY \
                  --preview="$preview_cmd" \
                  --preview-window="right:40%:wrap" \
                  --header="Select theme - ${ZSH_FZF_EXEC_KEY}:apply theme, ${ZSH_FZF_PASTE_KEY}:preview theme" \
                  --prompt="Theme > ")
    ret=$?

    [[ -n "$WIDGET" ]] && zle reset-prompt

    if [[ $ret -eq 0 ]]; then
        local -a output_lines
        output_lines=(${(f)output})
        local action=$output_lines[1]
        local selection=${output_lines[-1]##[[:space:]]#}

        if [[ "$action" == "$ZSH_FZF_EXEC_KEY" ]] && [[ -n "$WIDGET" ]]; then
            BUFFER="tinted \"${selection#base*-}\""
            zle redisplay
            zle accept-line
        elif [[ "$action" == "$ZSH_FZF_PASTE_KEY" ]] && [[ -n "$WIDGET" ]]; then
            theme_path="$TINTED_SHELL_PATH/scripts/$selection.sh"
            BUFFER="source $theme_path"
            zle redisplay
            zle accept-line
        fi
    else
        if [[ -n "$original_theme" ]] && [[ -n "$WIDGET" ]]; then
            if [[ -f "$TINTED_SHELL_PATH/scripts/$original_theme.sh" ]]; then
                source "$TINTED_SHELL_PATH/scripts/$original_theme.sh" 2>/dev/null
            fi
        fi
    fi

    return $ret
}
zle -N fzf-tinted-theme

bindkey '^Y' fzf-cd  # ctrl+y - directory navigation
# ctrl+r - history search
if [[ "$ATUIN_INIT" != "1" ]]; then
    bindkey '^R' fzf-history
else
    # use atuin if initialized
    bindkey '^R' atuin-search
fi
bindkey '^K' fzf-kill-proc-by-list  # ctrl+k - kill process by pid
bindkey '^P' fzf-kill-proc-by-port  # ctrl+p - kill process by port
bindkey '^T' fzf-tinted-theme  # ctrl+t - theme selection
