#!/usr/bin/env zsh

function atclone() {
    return 0
}

function atinit() {
    # Check if we can actually send notifications
    if ! command -v notify-send &> /dev/null || [ "$XDG_SESSION_TYPE" = "tty" ]; then
        zlong_send_notifications=false
        return 0
    fi

    # Duration threshold in seconds
    zlong_duration=20

    # Commands to ignore (do not notify)
    zlong_ignore_cmds="vi vim nvim less more man tig watch top htop btm ssh nano docker bat man sleep info"

    # Prefixes to ignore (consider command in argument)
    zlong_ignore_pfxs="sudo time"

    # Whether to send desktop notifications
    zlong_send_notifications=true

    # Whether to enable terminal bell
    zlong_terminal_bell=false

    # Whether to ignore commands with leading space
    zlong_ignorespace=false

    # Custom notification message format using similar format to auto-notify
    # Note: Must be wrapped in single quotes then double quotes for proper evaluation
    zlong_message='"Command $cmd: execution complete." "Completed in $ftime"'
}

function atload() {
    return 0
}

