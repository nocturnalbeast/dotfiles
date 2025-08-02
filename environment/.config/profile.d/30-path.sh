#!/usr/bin/env sh

## path configuration

# external binaries
if [ -d "$HOME/.bin" ]; then
    export EXTBIN_PATH="$HOME/.bin"
elif [ -d "$HOME/bin" ]; then
    export EXTBIN_PATH="$HOME/bin"
fi

# move external downloads of binaries into EXTBIN_PATH and add the same to PATH
if [ -n "$EXTBIN_PATH" ]; then
    export PIPX_BIN_DIR="$EXTBIN_PATH"
    export PATH="$EXTBIN_PATH:$PATH"
fi

# user binaries
if [ -d "$HOME/.local/bin" ]; then
    export PATH="$HOME/.local/bin:$PATH"
fi

# rust binaries
if [ -d "$CARGO_HOME/bin" ]; then
    export PATH="$CARGO_HOME/bin:$PATH"
fi

# go binaries
if [ -d "$GOPATH/bin" ]; then
    export PATH="$GOPATH/bin:$PATH"
fi
