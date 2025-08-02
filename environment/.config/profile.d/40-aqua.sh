#!/usr/bin/env sh

## aqua package manager

if command -v aqua > /dev/null 2>&1 || [ -x "$XDG_DATA_HOME/aquaproj-aqua/bin/aqua" ]; then
    export AQUA_ROOT_DIR="$XDG_DATA_HOME/aquaproj-aqua"
    export AQUA_GLOBAL_CONFIG="$XDG_CONFIG_HOME/aquaproj-aqua/aqua.yaml"
    export PATH="$AQUA_ROOT_DIR/bin:$PATH"
fi
