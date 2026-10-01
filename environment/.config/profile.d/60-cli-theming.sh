#!/usr/bin/env sh

## cli theming

export VIVID_THEME=~/.cache/theming/vivid/theme.yml # theme:managed

if command -v vivid > /dev/null 2>&1 && [ -f "$VIVID_THEME" ]; then
    # shellcheck disable=SC2155
    export LS_COLORS="$(vivid generate "$VIVID_THEME")"
fi
export EXA_ICON_SPACING=2
