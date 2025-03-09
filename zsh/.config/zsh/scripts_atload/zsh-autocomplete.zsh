#!/usr/bin/env zsh

# use tab/shift-tab to enter menu selection
bindkey '^I' menu-select
bindkey '^[[Z' menu-select

# use tab/shift-tab to navigate menu
bindkey -M menuselect '^I' menu-complete
bindkey -M menuselect '^[[Z' reverse-menu-complete

# make return accept the completion
bindkey -M menuselect '\r' .accept-line

# restore arrow key to normal history navigation
() {
   local -a prefix=( '\e'{\[,O} )
   local -a up=( ${^prefix}A ) down=( ${^prefix}B )
   local key=
   for key in $up[@]; do
      bindkey "$key" up-line-or-history
   done
   for key in $down[@]; do
      bindkey "$key" down-line-or-history
   done
}

# max lines for completion menu
zstyle -e ':autocomplete:*:*' list-lines 'reply=( $(( LINES / 3 )) )'

# don't complete empty input
zstyle ':autocomplete:*' ignored-input ''

# insert first common substring
zstyle ':autocomplete:*complete*:*' insert-unambiguous yes
zstyle ':autocomplete:*history*:*' insert-unambiguous yes
zstyle ':autocomplete:menu-search:*' insert-unambiguous yes

zstyle ':autocomplete:*' complete-options yes    # complete options when typing -
zstyle ':autocomplete:*' widget-style menu-complete

# configure min delay and input length
zstyle ':autocomplete:*' min-delay 0.05
zstyle ':autocomplete:*' min-input 2

# configure history search
zstyle ':autocomplete:*' history-incremental-search-backward yes
zstyle ':autocomplete:*' recent-dirs no

# configure menu behavior
zstyle ':autocomplete:*' add-space executables aliases functions builtins reserved-words commands

# configure completion groups and order
zstyle ':autocomplete:*' groups always
zstyle ':autocomplete:*' groups-order \
    expansions history-words options \
    aliases functions builtins reserved-words commands \
    local-directories directories suffix-aliases
