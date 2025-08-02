#!/usr/bin/env sh

## cli theming

if command -v vivid > /dev/null 2>&1 && [ -f "$XDG_CONFIG_HOME/vivid/theme.yml" ]; then
    # shellcheck disable=SC2155
    export LS_COLORS="$(vivid generate "$XDG_CONFIG_HOME/vivid/theme.yml")"
fi
export EXA_ICON_SPACING=2
