#!/usr/bin/env zsh

# forge zsh integration (loaded after all other deferred tasks)
#
# zsh-defer runs deferred tasks inside an anonymous function, so the plugin
# script's top-level `typeset -h _FORGE_*` declarations (its global state:
# _FORGE_BIN, _FORGE_CONVERSATION_PATTERN, session vars, ...) would become
# locals of that function and vanish when it returns. symptom: pressing Enter
# fails with "command not found: conversation" / "--agent" because
# $_FORGE_BIN expands empty. rewrite those declarations as global
# (typeset -gh) while evaluating; function bodies use `local` and are
# unaffected by the rewrite.
#
# the second rewrite revives _forge_reset's dead padding: it reads
# BUFFERLINES, which nothing ever sets, so the post-action prompt redraw
# (zle -I + reset-prompt) climbs the rows the action just printed and
# overwrites them — with a multi-row prompt (starship) that eats the last
# output line(s). pad the redraw down past the printed rows instead.
eval "$(forge zsh plugin | sed -E \
    -e 's/^typeset -h(a?) /typeset -gh\1 /' \
    -e 's/local pad="\$\{BUFFERLINES:-1\}"/local pad="$(( ${BUFFERLINES:-1} + 2 ))"/')"

if [[ -z "$_FORGE_THEME_LOADED" ]]; then
    eval "$(forge zsh theme)"
fi

# restore Tab binding for fzf-tab (forge overrides it with forge-completion)
bindkey '^I' fzf-tab-complete
