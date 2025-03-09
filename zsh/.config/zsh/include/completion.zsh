#!/usr/bin/env zsh

#
# Core completion system configuration
#

# NOTE: These basic completion settings are now handled by zsh-autocomplete
# # Enable completion menu and select with arrow keys when there are 2+ matches
# zstyle ':completion:*:default' menu select=2

# Enable verbose completion descriptions
zstyle ':completion:*' verbose yes

# Show command option descriptions
zstyle ':completion:*:options' auto-description '%d'
zstyle ':completion:*:options' description yes

# NOTE: Completion strategy is now handled by zsh-autocomplete
# # Set completion strategy order
# # _oldlist   - try to use previous completion results first
# # _complete  - standard completion
# # _expand    - expand variables, aliases, and glob patterns
# # _match     - match without expanding glob patterns
# # _prefix    - match prefix
# # _approximate - allow one error in matches
# zstyle ':completion:*' completer _oldlist _complete _expand _match _prefix _approximate

#
# Completion formatting and appearance
#

#
# Appearance and formatting
#

# Format messages with icons and colors
zstyle ':completion:*:messages' format '%F{yellow}󰍡 %d'
zstyle ':completion:*:warnings' format '%B%F{red}󱎘 %F{white}%d%b'
zstyle ':completion:*:descriptions' format '%B%F{cyan}󰦪 %d%f%b'
zstyle ':completion:*:corrections' format '%B%F{green}󰸞 %d (󱎘 %e) %f%b'

# Group matches and improve display
zstyle ':completion:*:matches' group 'yes'
zstyle ':completion:*' group-name ''
zstyle ':completion:*:default' list-grouped true
zstyle ':completion:*' format ' %F{yellow}-- %d --%f'

# Show completion menu stats
zstyle ':completion:*' select-prompt '%SScrolling active: current selection at %p%s'
zstyle ':completion:*:default' list-prompt '%S%M matches%s'

# Improve group headers and separators
zstyle ':completion:*:descriptions' format '%F{yellow}%B%d%b%f'
zstyle ':completion:*:messages' format ' %F{purple} -- %d --%f'
zstyle ':completion:*:warnings' format ' %F{red}-- no matches found --%f'

# Show selection numbers in menu
zstyle ':completion:*' select-scroll 0

#
# Matching and sorting configuration
#

# NOTE: Matching configuration is now handled by zsh-autocomplete
# # Advanced matching configuration:
# # - Case-insensitive matching (m:{a-zA-Z}={A-Za-z})
# # - Hyphen/underscore insensitive (m:{-_}={_-})
# # - Partial word completion from both ends (r:|=* l:|=*)
# # - Approximate matching with 1 error per 3 chars
# zstyle ':completion:*' matcher-list 'm:{a-zA-Z-_}={A-Za-z_-}' 'r:|=*' 'l:|=* r:|=*' 'l:|=* r:|=*'

# Use LS_COLORS for file completion coloring
zstyle ':completion:*' list-colors "${LS_COLORS}"

# Complete . and .. special directories
zstyle ':completion:*' special-dirs true

# Sort files by name in menu
zstyle ':completion:*' file-sort name

# Show file types during completion
zstyle ':completion:*' file-type true

# Complete hidden files
zstyle ':completion:*' hidden true

#
# History and correction behavior
#

# Correction settings
zstyle ':completion:*:correct:*' insert-unambiguous true
zstyle ':completion:*:correct:*' original true
zstyle ':completion:*:correct:*' prompt 'correct to: %e'

# Recent directories handling
zstyle ':chpwd:*' recent-dirs-file "${XDG_CACHE_HOME}/zsh/chpwd-recent-dirs"
zstyle ':chpwd:*' recent-dirs-max 1000
zstyle ':completion:*:*:cd:*' recent-dirs-insert both

# History word completion settings
zstyle ':completion:*:history-words' list false
zstyle ':completion:*:history-words' menu yes
zstyle ':completion:*:history-words' remove-all-dups yes
zstyle ':completion:*:history-words' stop yes

# Don't complete unavailable commands
zstyle ':completion:*:functions' ignored-patterns '(_*|pre(cmd|exec))'

#
# Directory navigation and privilege handling
#

# Match settings
zstyle ':completion:*:match:*' original only
zstyle -e ':completion:*:approximate:*' max-errors 'reply=( $(( ($#PREFIX+$#SUFFIX)/3 )) numeric )'

# Allow completion with elevated privileges
zstyle ':completion::complete:*' gain-privileges 1
zstyle ':completion:*' squeeze-slashes true

# Directory navigation settings
zstyle ':completion:*:*:cd:*:directory-stack' menu yes select
zstyle ':completion:*:cd:*' tag-order local-directories named-directories path-directories
zstyle ':completion:*:cd:*' group-order local-directories named-directories path-directories
zstyle ':completion:*:*:cd:*' ignored-patterns '(*/)#lost+found'

# Don't complete users for ssh/scp/rsync
zstyle ':completion:*:(ssh|scp|rsync):*' tag-order 'hosts:-host:host hosts:-domain:domain hosts:-ipaddr:ip\ address *'
zstyle ':completion:*:(scp|rsync):*' group-order users files all-files hosts-domain hosts-host hosts-ipaddr
zstyle ':completion:*:ssh:*' group-order users hosts-domain hosts-host users hosts-ipaddr
zstyle ':completion:*:(ssh|scp|rsync):*:hosts-host' ignored-patterns '*(.|:)*' loopback ip6-loopback localhost ip6-localhost broadcasthost
zstyle ':completion:*:(ssh|scp|rsync):*:hosts-domain' ignored-patterns '<->.<->.<->.<->' '^[-[:alnum:]]##(.[-[:alnum:]]##)##' '*@*'
zstyle ':completion:*:(ssh|scp|rsync):*:hosts-ipaddr' ignored-patterns '^(<->.<->.<->.<->|(|::)([[:xdigit:].]##:(#c,2))##(|%*))' '127.0.0.<->' '255.255.255.255' '::1' 'fe80::*'

# Process, manual pages, and other command completions
#

# Manual page settings
zstyle ':completion:*:manuals' separate-sections true
zstyle ':completion:*:manuals.*' insert-sections true
zstyle ':completion:*:man:*' menu yes select
zstyle ':completion:*:man:*' file-patterns '*.(1|1p|1ssl|8|2|3|3p|3pm|3ssl|4|5|6|7|9|n|l|o|tcl|3tcl|3tk):man-pages'

#
# Process handling and system commands
#

# Enhanced process completion with more details
zstyle ':completion:*:processes' command 'ps -au$USER'
zstyle ':completion:*:*:*:*:processes' command "ps -u $USER -o pid,user,comm -w -w"

# Better process selection for kill
zstyle ':completion:*:*:kill:*:processes' list-colors '=(#b) #([0-9]#) ([0-9a-z-]#)*=01;34=0=01'
zstyle ':completion:*:*:kill:*' menu yes select
zstyle ':completion:*:*:kill:*' force-list always
zstyle ':completion:*:*:kill:*' insert-ids single

# Improved killall completion
zstyle ':completion:*:*:killall:*' menu yes select
zstyle ':completion:*:*:killall:*' command 'ps -u $USER -o cmd'

# Better handling of make targets
zstyle ':completion:*:make:*:targets' call-command true
zstyle ':completion:*:make:*:*' tag-order targets
#zstyle ':completion:*:*:*make:*:targets' command awk \'/^[a-zA-Z0-9][^\/:=]*:/ {print $1}\'

# URL/web related completions
zstyle ':completion:*:urls' local 'www' '/var/www/' 'public_html'

# Don't complete backup files as executables
zstyle ':completion:*:complete:-command-::commands' ignored-patterns '*\~'

# NOTE: Fuzzy matching is now handled by zsh-autocomplete
# # Fuzzy match mistyped completions
# zstyle ':completion:*' completer _complete _match _approximate
# zstyle ':completion:*:match:*' original only
# zstyle ':completion:*:approximate:*' max-errors 1 numeric

# Colorize process list
zstyle ':completion:*:*:kill:*:processes' list-colors '=(#b) #([0-9]#) ([0-9a-z-]#)*=01;36=0=01'

# Enable menu for kill command
zstyle ':completion:*:*:kill:*' menu yes select

# Always show kill list
zstyle ':completion:*:*:kill:*' force-list always

# Insert process IDs individually
zstyle ':completion:*:*:kill:*' insert-ids single

# Parse Makefile targets
zstyle ':completion:*:make:*:targets' call-command true

# Order make targets
zstyle ':completion:*:make::' tag-order targets:

# Extract make targets using awk
zstyle ':completion:*:*:*make:*:targets' command awk \''/^[a-zA-Z0-9][^\/\t=]+:/ {print $1}'\' \$file

# Show job numbers
zstyle ':completion:*:jobs' numbers true

zstyle ":completion:*:git-checkout:*" sort false
zstyle ':completion:complete:*:options' sort false

#
# Ignore patterns and special handling
#

# Ignore patterns for better completion
zstyle ':completion:*:complete:-command-::commands' ignored-patterns '*\~|\#*\#|*.zwc|*.zwc.old|*.bak|*.old|*\$'

# Ignore compiled and temporary files
zstyle ':completion:*:*:zcompile:*' ignored-patterns '(*~|*.zwc|*.zwc.old)'

# Smarter function completion
zstyle ':completion:*:functions' ignored-patterns '(_*|pre(cmd|exec)|prompt_*|TRAP*|_trap*|_zsh_autosuggest*|_zsh_highlight*)'

# Better directory handling
zstyle -e ':completion:*' special-dirs '[[ $PREFIX = (../)#(|.|..) ]] && reply=(..)'
zstyle ':completion:*:cd:*' ignore-parents parent pwd

# Exclude version control directories
zstyle ':completion:*:(^/(|.git|.hg|.svn|.github)/)#*' ignored-patterns '*(.git|.hg|.svn|.github)(/|)'

#
# Advanced completion behavior
#

# Improve parameter and expansion handling
zstyle ':completion:*:*:-subscript-:*' tag-order indexes parameters
zstyle ':completion:*:expand:*' tag-order all-expansions
zstyle ':completion:*:expand:*' substitute true

# Better glob handling
zstyle ':completion:*' glob true
zstyle ':completion:*' glob-dots true
zstyle ':completion:*' accept-exact '*(N)'
zstyle ':completion:*' accept-exact-dirs true

# Keep prefix and improve path handling
zstyle ':completion:*' keep-prefix changed
zstyle ':completion:*' path-completion true
zstyle ':completion:*' squeeze-slashes true

# Improve history completion
zstyle ':completion:*:history-words' remove-all-dups true
zstyle ':completion:*:history-words' stop true

# Better handling of hosts
zstyle ':completion:*:hosts' hosts $hosts
zstyle ':completion:*:hosts' ports $ports

# Improve alias completion
zstyle ':completion:*:aliases' list-colors '=*=1;38;5;214'
zstyle ':completion:*:aliases' ignored-patterns ''

# Enhance command completion
zstyle ':completion:*:-command-:*' group-order alias builtins functions commands

# Insert both forms of recent dirs
zstyle ':completion:*' recent-dirs-insert both

# Set correction prompt format
zstyle ':completion:correct:' prompt 'correct to: %e'
