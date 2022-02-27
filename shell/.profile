#!/usr/bin/env sh

# source system profile if it exists
if [ -f /etc/profile ]; then
    . /etc/profile
fi

# source user environment variables if it exists
ENV_FILE="${XDG_CONFIG_HOME:-$HOME/.config}/shell/env"
if [ -f "$ENV_FILE" ]; then
    . "$ENV_FILE"
fi

# source user aliases if it exists
ALIAS_FILE="${XDG_CONFIG_HOME:-$HOME/.config}/shell/aliases"
if [ -f "$ALIAS_FILE" ]; then
    . "$ALIAS_FILE"
fi
