export AUTO_NOTIFY_THRESHOLD=20
export AUTO_NOTIFY_TITLE="Command '%command': execution complete"
export AUTO_NOTIFY_BODY="Completed in %elapsed seconds; exit code is %exit_code."
export AUTO_NOTIFY_IGNORE=("vi" "vim" "nvim" "less" "more" "man" "tig" "watch" "top" "htop" "btm" "ssh" "nano" "docker" "bat" "man" "sleep")

if ! command -v notify-send &>/dev/null; then
    disable_auto_notify
fi
if [ "$XDG_SESSION_TYPE" = "tty" ]; then
    disable_auto_notify
fi
