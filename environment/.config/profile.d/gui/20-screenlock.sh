#!/usr/bin/env sh

## common screenlock settings

# xsecurelock configuration
if command -v xsecurelock > /dev/null 2>&1; then
    export XSECURELOCK_AUTH_BACKGROUND_COLOR="rgb:0d/0d/0d"
    export XSECURELOCK_AUTH_CURSOR_BLINK=1
    export XSECURELOCK_AUTH_FOREGROUND_COLOR="rgb:F2/F2/F2"
    export XSECURELOCK_AUTH_TIMEOUT=10
    export XSECURELOCK_AUTH_WARNING_COLOR="rgb:FF/8D/8D"
    export XSECURELOCK_AUTH="auth_x11"
    export XSECURELOCK_AUTHPROTO="authproto_pam"
    export XSECURELOCK_BLANK_TIMEOUT=60
    export XSECURELOCK_COMPOSITE_OBSCURER=1
    export XSECURELOCK_DATETIME_FORMAT="%A, %-d %B - %I:%M %p"
    export XSECURELOCK_DIM_ALPHA=1
    export XSECURELOCK_DIM_COLOR="rgb:00/00/00"
    export XSECURELOCK_DIM_TIME_MS=500
    export XSECURELOCK_DISCARD_FIRST_KEYPRESS=1
    export XSECURELOCK_FONT="monospace:style=Bold:antialias=true"
    export XSECURELOCK_NO_XRANDR=0
    export XSECURELOCK_PASSWORD_PROMPT="cursor"
    export XSECURELOCK_SAVER_CLOCK_FONT_SIZE=120
    export XSECURELOCK_SAVER_IMAGE="$(readlink -f "$XDG_CONFIG_HOME/wm/current_wallpaper")"
    export XSECURELOCK_SAVER_STATUS_FONT_SIZE=40
    export XSECURELOCK_SAVER_TIMEOUT=300
    export XSECURELOCK_SAVER="$(which xsecurelock-screensaver)"
    export XSECURELOCK_SHOW_DATETIME=0
    export XSECURELOCK_SHOW_HOSTNAME=0
    export XSECURELOCK_SHOW_USERNAME=0
fi
