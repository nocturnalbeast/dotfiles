#!/usr/bin/env sh

ALIAS_FILE="${XDG_CONFIG_HOME:-$HOME/.config}/shell/aliases"
ENV_FILE="${XDG_CONFIG_HOME:-$HOME/.config}/shell/env"

if [ -f "$ENV_FILE" ]; then
    . "$ENV_FILE"
fi

if [ -f "$ALIAS_FILE" ]; then
    . "$ALIAS_FILE"
fi
