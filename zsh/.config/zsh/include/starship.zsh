#!/usr/bin/env zsh

zmodload zsh/parameter
zmodload zsh/datetime
zmodload zsh/mathfunc

_prompt_executing=""

__starship_get_time() {
    (( STARSHIP_CAPTURED_TIME = int(rint(EPOCHREALTIME * 1000)) ))
}

__unified_precmd() {
    STARSHIP_CMD_STATUS=$? STARSHIP_PIPE_STATUS=(${pipestatus[@]})
    if (( ${+STARSHIP_START_TIME} )); then
        __starship_get_time && (( STARSHIP_DURATION = STARSHIP_CAPTURED_TIME - STARSHIP_START_TIME ))
        unset STARSHIP_START_TIME
    else
        unset STARSHIP_DURATION STARSHIP_CMD_STATUS STARSHIP_PIPE_STATUS
    fi
    STARSHIP_JOBS_COUNT=${#jobstates}

    local ret="$?"
    if [[ "$_prompt_executing" != "0" ]]
    then
      _PROMPT_SAVE_PS1="$PS1"
      _PROMPT_SAVE_PS2="$PS2"
      PS1=$'%{\e]133;P;k=i\a%}'$PS1$'%{\e]133;B\a\e]122;> \a%}'
      PS2=$'%{\e]133;P;k=s\a%}'$PS2$'%{\e]133;B\a%}'
    fi
    if [[ "$_prompt_executing" != "" ]]
    then
       printf "\033]133;D;%s;aid=%s\007" "$ret" "$$"
    fi
    printf "\033]133;A;cl=m;aid=%s\007" "$$"
    _prompt_executing=0
}

__unified_preexec() {
    __starship_get_time && STARSHIP_START_TIME=$STARSHIP_CAPTURED_TIME

    PS1="$_PROMPT_SAVE_PS1"
    PS2="$_PROMPT_SAVE_PS2"
    printf "\033]133;C;\007"
    _prompt_executing=1
}

starship_zle-keymap-select() {
    zle reset-prompt
}

preexec_functions+=(__unified_preexec)
precmd_functions+=(__unified_precmd)

__starship_preserved_zle_keymap_select=${widgets[zle-keymap-select]#user:}
if [[ -z $__starship_preserved_zle_keymap_select ]]; then
    zle -N zle-keymap-select starship_zle-keymap-select;
else
    starship_zle-keymap-select-wrapped() {
        $__starship_preserved_zle_keymap_select "$@";
        starship_zle-keymap-select "$@";
    }
    zle -N zle-keymap-select starship_zle-keymap-select-wrapped;
fi

export STARSHIP_SHELL="zsh"

STARSHIP_SESSION_KEY="$RANDOM$RANDOM$RANDOM$RANDOM$RANDOM"
STARSHIP_SESSION_KEY="${STARSHIP_SESSION_KEY}0000000000000000"
export STARSHIP_SESSION_KEY=${STARSHIP_SESSION_KEY:0:16}

VIRTUAL_ENV_DISABLE_PROMPT=1

setopt promptsubst

if [[ "$(uname)" == "Darwin" ]] && command -v "brew" > /dev/null 2>&1; then
    STARSHIP_BIN="/opt/homebrew/bin/starship"
else
    STARSHIP_BIN="/usr/bin/starship"
fi

PROMPT='$($STARSHIP_BIN prompt --terminal-width="$COLUMNS" --keymap="${KEYMAP:-}" --status="$STARSHIP_CMD_STATUS" --pipestatus="${STARSHIP_PIPE_STATUS[*]}" --cmd-duration="${STARSHIP_DURATION:-}" --jobs="$STARSHIP_JOBS_COUNT")'
RPROMPT='$($STARSHIP_BIN prompt --right --terminal-width="$COLUMNS" --keymap="${KEYMAP:-}" --status="$STARSHIP_CMD_STATUS"--pipestatus="${STARSHIP_PIPE_STATUS[*]}" --cmd-duration="${STARSHIP_DURATION:-}" --jobs="$STARSHIP_JOBS_COUNT")'
PROMPT2="$($STARSHIP_BIN prompt --continuation)"
