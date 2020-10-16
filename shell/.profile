ALIAS_FILE="$HOME/.config/shell/aliases"
ENV_FILE="$HOME/.config/shell/env"

if [ -f "$ENV_FILE" ]; then
    source "$ENV_FILE"
fi

if [ -f "$ALIAS_FILE" ]; then
    source "$ALIAS_FILE"
fi
