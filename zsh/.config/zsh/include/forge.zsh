#!/usr/bin/env zsh

# forge zsh integration (loaded after all other deferred tasks)

if ! command -v forge 2>&1 >/dev/null; then
    return
fi

# zsh-defer runs deferred tasks inside an anonymous function, so the plugin
# script's top-level `typeset -h _FORGE_*` declarations (its global state:
# _FORGE_BIN, _FORGE_CONVERSATION_PATTERN, session vars, ...) would become
# locals of that function and vanish when it returns.
# also revive _forge_reset's dead padding: it reads BUFFERLINES, which
# nothing ever sets, so the post-action prompt redraw (zle -I + reset-prompt)
# climbs the rows the action just printed and overwrites them - with a
# multi-row prompt (starship) that eats the last output line(s).
eval "$(forge zsh plugin | sed -E \
    -e 's/^typeset -h(a?) /typeset -gh\1 /' \
    -e 's/local pad="\$\{BUFFERLINES:-1\}"/local pad="$(( ${BUFFERLINES:-1} + 2 ))"/')"

if [[ -z "$_FORGE_THEME_LOADED" ]]; then
    eval "$(forge zsh theme)"
fi

# restore Tab binding for fzf-tab (forge overrides it with forge-completion)
bindkey '^I' fzf-tab-complete
