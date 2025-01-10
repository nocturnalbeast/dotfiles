#!/usr/bin/env sh

TPM_PATH="${XDG_DATA_HOME:-$HOME/.local/share}/tmux/plugins/tpm"

if [ ! -d "$TPM_PATH" ]; then
    printf "Installing tmux plugin manager...\n"
    mkdir -p "$XDG_DATA_HOME/tmux/plugins"
    git clone https://github.com/tmux-plugins/tpm "$TPM_PATH"
fi

printf "Installing tmux plugins...\n"
"$TPM_PATH/bin/install_plugins"
