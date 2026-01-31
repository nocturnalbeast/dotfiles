#!/usr/bin/env zsh

function atinit() {
    if [ -n "$SSH_CLIENT" ] || [ -n "$SSH_TTY" ]; then
        export ZSH_TAB_TITLE_PREFIX="$USER@$HOST - zsh: "
    else
        export ZSH_TAB_TITLE_DEFAULT_DISABLE_PREFIX=true
    fi

    export ZSH_TAB_TITLE_ONLY_FOLDER=true
    export ZSH_TAB_TITLE_CONCAT_FOLDER_PROCESS=true
    export ZSH_TAB_TITLE_ENABLE_FULL_COMMAND=true
    export ZSH_TAB_TITLE_DISABLE_AUTO_TITLE=false
    export ZSH_TAB_TITLE_ADDITIONAL_TERMS='alacritty|kitty|foot'
}

