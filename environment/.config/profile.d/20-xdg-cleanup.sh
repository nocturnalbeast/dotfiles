#!/usr/bin/env sh

## xdg base directory cleanup

# languages / development tools
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

# x11
export XCURSOR_PATH="/usr/share/icons:$XDG_DATA_HOME/icons"
export XINITRC="$XDG_CONFIG_HOME/X11/xinitrc"
export XSERVERRC="$XDG_CONFIG_HOME/X11/xserverrc"
# comment the below line if using lightdm/slim/sddm for login manager
export XAUTHORITY="$XDG_RUNTIME_DIR/Xauthority"
export ICEAUTHORITY="$XDG_CACHE_HOME/ICEauthority"

# others
export CUDA_CACHE_PATH="$XDG_CACHE_HOME/nv"
export GNUPGHOME="$XDG_DATA_HOME/gnupg"
export GTK2_RC_FILES="$XDG_CONFIG_HOME/gtk-2.0/gtkrc"
export _JAVA_OPTIONS=-Djava.util.prefs.userRoot="$XDG_CONFIG_HOME/java"
export WINEPREFIX="$XDG_CONFIG_HOME/wine"
