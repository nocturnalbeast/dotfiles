#!/usr/bin/env zsh

# default key bindings for fzf widgets
ZSH_FZF_PASTE_KEY=${ZSH_FZF_PASTE_KEY:-'space'}
ZSH_FZF_EXEC_KEY=${ZSH_FZF_EXEC_KEY:-'enter'}
ZSH_FZF_EXTRA_PASTE_KEYS=${ZSH_FZF_EXTRA_PASTE_KEYS:-'right'}

# interactive directory navigation with fzf
fzf-cd() {
    local cmd output ret
    
    if (( ${+commands[fd]} )); then
        cmd=(fd --type d --min-depth 1 --follow --exclude '.*' --exclude '/dev/*' --exclude '/proc/*' --exclude '/sys/*')
    else
        cmd=(find -L . -mindepth 1 \( -path '*/\.*' -o -fstype 'sysfs' -o -fstype 'devfs' -o -fstype 'devtmpfs' -o -fstype 'proc' \) -prune -o -type d -print)
    fi

    output=$($cmd 2>/dev/null | fzf --expect=$ZSH_FZF_EXEC_KEY,$ZSH_FZF_PASTE_KEY,$ZSH_FZF_EXTRA_PASTE_KEYS \
      --header="Navigate directories - ${ZSH_FZF_EXEC_KEY}:cd to dir, ${ZSH_FZF_PASTE_KEY}/${ZSH_FZF_EXTRA_PASTE_KEYS}:insert path")
    ret=$?

    [[ -n "$WIDGET" ]] && zle reset-prompt
    
    if [[ $ret -eq 0 ]]; then
        local action selection
        action=$(head -1 <<< "$output")
        selection=$(tail -n +2 <<< "$output")
        
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
        local action=$(head -1 <<< "$output")
        local cmd=$(tail -n1 <<< "$output" | sed 's/^[[:space:]]*[0-9]*[[:space:]]*//') 
        
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
        local action=$(head -1 <<< "$output")
        local selected=$(tail -n1 <<< "$output")
        local pid=$(awk '{print $2}' <<< "$selected")
        
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
        local action=$(head -1 <<< "$output")
        local selected=$(tail -n1 <<< "$output")
        local pid=$(grep -oP '(?<=pid=)\d+(?=,)' <<< "$selected")
        
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

bindkey '^Y' fzf-cd  # ctrl+y - directory navigation
bindkey '^R' fzf-history  # ctrl+r - history search
bindkey '^K' fzf-kill-proc-by-list  # ctrl+k - kill process by pid
bindkey '^P' fzf-kill-proc-by-port  # ctrl+p - kill process by port
