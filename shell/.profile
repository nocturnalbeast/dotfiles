#!/usr/bin/env sh

if [ "$ENV_DONE" = "1" ]; then
    return
fi

## source system profile if it exists

if [ -f /etc/profile ]; then
    # shellcheck disable=SC1091
    . /etc/profile
fi

## language settings

export LC_ALL="${LC_ALL:-en_US.UTF-8}"
export LANG="${LANG:-en_US.UTF-8}"

## xdg base directory specification

export XDG_DATA_HOME="${XDG_DATA_HOME:-$HOME/.local/share}"
export XDG_STATE_HOME="${XDG_STATE_HOME:-$HOME/.local/state}"
export XDG_CACHE_HOME="${XDG_CACHE_HOME:-$HOME/.cache}"
export XDG_CONFIG_HOME="${XDG_CONFIG_HOME:-$HOME/.config}"

## xdg user directories
if [ -f "$XDG_CONFIG_HOME/user-dirs.dirs" ]; then
    set -a
    # shellcheck disable=SC1091
    . "$XDG_CONFIG_HOME/user-dirs.dirs"
    set +a
fi

## xdg cleanup

# development tools
export CARGO_HOME="$XDG_DATA_HOME/cargo"
export RUSTUP_HOME="$XDG_DATA_HOME/rustup"
export GOPATH="$XDG_DATA_HOME/go"
export PYTHONSTARTUP="$XDG_CONFIG_HOME/python/startup.py"
export ANDROID_HOME="$XDG_DATA_HOME/android"
export NPM_CONFIG_USERCONFIG="$XDG_CONFIG_HOME/npm/npmrc"
export GEM_PATH="$XDG_DATA_HOME/ruby/gems"
export GEM_SPEC_CACHE="$XDG_DATA_HOME/ruby/specs"
export GEM_HOME="$XDG_DATA_HOME/ruby/gems"
export BUNDLE_USER_CONFIG="$XDG_CONFIG_HOME/bundle"
export BUNDLE_USER_CACHE="$XDG_CACHE_HOME/bundle"
export BUNDLE_USER_PLUGIN="$XDG_DATA_HOME/bundle"

# system configuration
export GNUPGHOME="$XDG_DATA_HOME/gnupg"
export _JAVA_OPTIONS=-Djava.util.prefs.userRoot="$XDG_CONFIG_HOME/java"
export GTK2_RC_FILES="$XDG_CONFIG_HOME/gtk-2.0/gtkrc"
export CUDA_CACHE_PATH="$XDG_CACHE_HOME/nv"
export WINEPREFIX="$XDG_CONFIG_HOME/wine"
export XCURSOR_PATH="/usr/share/icons:$XDG_DATA_HOME/icons"

# x11 configuration
export XINITRC="$XDG_CONFIG_HOME/X11/xinitrc"
export XSERVERRC="$XDG_CONFIG_HOME/X11/xserverrc"
export ICEAUTHORITY="$XDG_CACHE_HOME/ICEauthority"

## path configuration

# user binaries
if [ -d "$HOME/.local/bin" ]; then
    export PATH="$HOME/.local/bin:$PATH"
fi

# third-party binaries
if [ -d "$HOME/.bin" ]; then
    export PATH="$HOME/.bin:$PATH"
elif [ -d "$HOME/bin" ]; then
    export PATH="$HOME/bin:$PATH"
fi

# rust binaries
if [ -d "$CARGO_HOME/bin" ]; then
    export PATH="$CARGO_HOME/bin:$PATH"
fi

# go binaries
if [ -d "$GOPATH/bin" ]; then
    export PATH="$GOPATH/bin:$PATH"
fi

# aqua package manager
if command -v aqua > /dev/null 2>&1 || [ -x "$XDG_DATA_HOME/aquaproj-aqua/bin/aqua" ]; then
    export AQUA_ROOT_DIR="$XDG_DATA_HOME/aquaproj-aqua"
    export AQUA_GLOBAL_CONFIG="$XDG_CONFIG_HOME/aquaproj-aqua/aqua.yaml"
    export PATH="$AQUA_ROOT_DIR/bin:$PATH"
fi

## default applications

export EDITOR="nvim"
export VISUAL="nvim"
export TERMINAL="kitty"
export BROWSER="librewolf"
export BROWSER_PRIVATE_OPT="--private-window"
export SYSTEMD_EDITOR="$EDITOR"
export READER="zathura"
export VIDEO="mpv"
export IMAGE="imv"
export FILES="nemo"

# default menu
if [ -n "$WAYLAND_DISPLAY" ]; then
    export MENU_BACKEND="tofi"
else
    export MENU_BACKEND="dmenu"
fi

## theming

# gui settings
export QT_AUTO_SCREEN_SCALE_FACTOR=0
export QT_SCALE_FACTOR=1
export QT_SCREEN_SCALE_FACTORS="1;1;1"
export GDK_SCALE=1
export GDK_DPI_SCALE=1
export QT_LOGGING_RULES="*.debug=false"
export QT_QPA_PLATFORMTHEME="qt6ct"

# cli settings
if command -v vivid > /dev/null 2>&1 && [ -f "$XDG_CONFIG_HOME/vivid/theme.yml" ]; then
    # shellcheck disable=SC2155
    export LS_COLORS="$(vivid generate "$XDG_CONFIG_HOME/vivid/theme.yml")"
fi
export EXA_ICON_SPACING=2

## tool configuration

# pager settings
export PAGER="less -RF --mouse"
export LESSHISTFILE=-
export MANPAGER="sh -c 'col -bx | bat -l man -p'"
export BAT_PAGER="$PAGER"
export DELTA_PAGER="$PAGER"
export MANROFFOPT="-c" # fix formatting with bat while using as man pager

# clipmenu settings
if command -v clipmenu > /dev/null 2>&1; then
    export CM_DIR="$XDG_RUNTIME_DIR"
    export CM_HISTLENGTH=5
fi

# xsecurelock settings
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
    # shellcheck disable=SC2155
    export XSECURELOCK_SAVER_IMAGE="$(readlink -f "$XDG_CONFIG_HOME/wm/current_wallpaper")"
    export XSECURELOCK_SAVER_STATUS_FONT_SIZE=40
    export XSECURELOCK_SAVER_TIMEOUT=300
    # shellcheck disable=SC2155
    export XSECURELOCK_SAVER="$(which xsecurelock-screensaver)"
    export XSECURELOCK_SHOW_DATETIME=0
    export XSECURELOCK_SHOW_HOSTNAME=0
    export XSECURELOCK_SHOW_USERNAME=0
fi

export ENV_DONE=1
