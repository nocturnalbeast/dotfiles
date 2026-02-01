#!/usr/bin/env zsh

#
# Basic Completion Options
#

zstyle ':completion:*:*:*:*:*' menu select
zstyle ':completion:*:default' list-prompt '%S%M matches%s'
zstyle ':completion:*' select-prompt '%SScrolling active: current selection at %p%s'

#
# Caching for Performance
#

zstyle ':completion:*' use-cache yes
zstyle ':completion::complete:*' use-cache on
zstyle ':completion:*' cache-path "${ZSH_CACHE_DIR:-${XDG_CACHE_HOME:-$HOME/.cache}/zsh}/zcompcache"

#
# Matching and Case Sensitivity
#

# Case-insensitive matching, hyphen/underscore insensitivity, partial/substring completion
zstyle ':completion:*' matcher-list 'm:{[:lower:][:upper:]-_}={[:upper:][:lower:]_-}' 'r:|[._-]=* r:|=*' 'l:|=* r:|=*'

#
# Completers Strategy
#

zstyle ':completion:*' completer _oldlist _complete _expand _match _prefix _approximate
zstyle ':completion:*:match:*' original only
zstyle -e ':completion:*:approximate:*' max-errors 'reply=($((($#PREFIX+$#SUFFIX)/3>7?7:($#PREFIX+$#SUFFIX)/3))numeric)'

#
# Formatting and Display
#

# Use LS_COLORS for file completion
zstyle ':completion:*:default' list-colors ${(s.:.)LS_COLORS}

# Format messages, warnings, and descriptions with colors and icons
zstyle ':completion:*:messages' format '%F{yellow}󰍡 %d'
zstyle ':completion:*:warnings' format '%B%F{red}󱎘 %F{white}%d%b'
zstyle ':completion:*:descriptions' format '%B%F{cyan}󰦪 %d%f%b'
zstyle ':completion:*:corrections' format '%B%F{green}󰸞 %d (󱎘 %e) %f%b'
zstyle ':completion:*' format ' %F{yellow}-- %d --%f'

# Group matches
zstyle ':completion:*:matches' group 'yes'
zstyle ':completion:*' group-name ''
zstyle ':completion:*:default' list-grouped true

# Enable verbose output
zstyle ':completion:*' verbose yes

# Show selection numbers
zstyle ':completion:*' select-scroll 0

# Options description
zstyle ':completion:*:options' description 'yes'
zstyle ':completion:*:options' auto-description '%d'

#
# File and Directory Completion
#

# Complete . and .. special directories
zstyle -e ':completion:*' special-dirs '[[ $PREFIX = (../)#(|.|..) ]] && reply=(..)'

# Directory completion ordering
zstyle ':completion:*:cd:*' tag-order local-directories named-directories path-directories
zstyle ':completion:*:*:cd:*:directory-stack' menu yes select
zstyle ':completion:*:-tilde-:*' group-order 'named-directories' 'path-directories' 'users' 'expand'

# File sorting
zstyle ':completion:*' file-sort name
zstyle ':completion:*' file-type true

# Complete hidden files
zstyle ':completion:*' hidden true
zstyle ':completion:*' glob true
zstyle ':completion:*' glob-dots true

# Accept exact matches
zstyle ':completion:*' accept-exact '*(N)'
zstyle ':completion:*' accept-exact-dirs true

# Ignore certain directories
zstyle ':completion:*:cd:*' ignore-parents parent pwd
zstyle ':completion:*:(^/(|.git|.hg|.svn|.github)/)#*' ignored-patterns '*(.git|.hg|.svn|.github)(/|)'

# Squeeze slashes
zstyle ':completion:*' squeeze-slashes true
zstyle ':completion:*' keep-prefix changed
zstyle ':completion:*' path-completion true

#
# Process Completion (kill, ps)
#

# Process completion command
zstyle ':completion:*:*:*:*:processes' command 'ps -au$USER'
zstyle ':completion:*:*:*:*:processes' command "ps -u $USER -o pid,user,comm -w -w"

# Kill completion
zstyle ':completion:*:*:kill:*:processes' list-colors '=(#b) #([0-9]#) ([0-9a-z-]#)*=01;36=0=01'
zstyle ':completion:*:*:kill:*' menu yes select
zstyle ':completion:*:*:kill:*' force-list always
zstyle ':completion:*:*:kill:*' insert-ids single

# Ignore current line in kill/diff
zstyle ':completion:*:(rm|kill|diff):*' ignore-line other
zstyle ':completion:*:rm:*' file-patterns '*:all-files'

# Job completion
zstyle ':completion:*:jobs' numbers true

#
# SSH/Network Host Completion
#

# Build hosts from SSH known_hosts and /etc/hosts
typeset -g -a _ssh_hosts
typeset -g -a _etc_hosts
typeset -g -a _all_hosts

[[ -r /etc/ssh/ssh_known_hosts ]] && _ssh_hosts=(${${${${(f)"$(</etc/ssh/ssh_known_hosts)"}:#[\|]*}%%\ *}%%,*}) || _ssh_hosts=()
[[ -r ~/.ssh/known_hosts ]] && _ssh_hosts+=(${${${${(f)"$(<$HOME/.ssh/known_hosts)"}:#[\|]*}%%\ *}%%,*}) || _ssh_hosts=()
[[ -r /etc/hosts ]] && : ${(A)_etc_hosts:=${(s: :)${(ps:\t:)${${(f)~~"$(</etc/hosts)"}%%\#*}##[:blank:]#[^[:blank:]]#}}} || _etc_hosts=()

_all_hosts=(
  "$_ssh_hosts[@]"
  "$_etc_hosts[@]"
  "$HOST"
  localhost
)

zstyle ':completion:*:hosts' hosts "$_all_hosts[@]"

# SSH host completion ordering
zstyle ':completion:*:(ssh|scp|rsync):*' tag-order 'hosts:-host:host hosts:-domain:domain hosts:-ipaddr:ip\ address *'
zstyle ':completion:*:(scp|rsync):*' group-order users files all-files hosts-domain hosts-host hosts-ipaddr
zstyle ':completion:*:ssh:*' group-order users hosts-domain hosts-host users hosts-ipaddr

# Ignore common localhost patterns
zstyle ':completion:*:(ssh|scp|rsync):*:hosts-host' ignored-patterns '*(.|:)*' loopback ip6-loopback localhost ip6-localhost broadcasthost
zstyle ':completion:*:(ssh|scp|rsync):*:hosts-domain' ignored-patterns '<->.<->.<->.<->' '^[-[:alnum:]]##(.[-[:alnum:]]##)##' '*@*'
zstyle ':completion:*:(ssh|scp|rsync):*:hosts-ipaddr' ignored-patterns '^(<->.<->.<->.<->|(|::)([[:xdigit:].]##:(#c,2))##(|%*))' '127.0.0.<->' '255.255.255.255' '::1' 'fe80::*'

#
# Git Completion
#

zstyle ':completion:*:git-checkout:*' sort false
zstyle ':completion:*:complete:*:options' sort false

#
# History Completion
#

zstyle ':completion:*:history-words' stop yes
zstyle ':completion:*:history-words' remove-all-dups yes
zstyle ':completion:*:history-words' list false
zstyle ':completion:*:history-words' menu yes

#
# Manual Page Completion
#

zstyle ':completion:*:manuals' separate-sections true
zstyle ':completion:*:manuals.*' insert-sections true
zstyle ':completion:*:man:*' menu yes select
zstyle ':completion:*:man:*' file-patterns '*.(1|1p|1ssl|8|2|3|3p|3pm|3ssl|4|5|6|7|9|n|l|o|tcl|3tcl|3tk):man-pages'

#
# User Completion
#

# Don't complete system users
zstyle ':completion:*:*:*:users' ignored-patterns \
  adm amanda apache at avahi avahi-autoipd beaglidx bin cacti canna clamav \
  daemon dbus distcache dnsmasq dovecot fax ftp games gdm gkrellmd gopher \
  hacluster haldaemon halt hsqldb ident junkbust kdm ldap lp mail mailman \
  mailnull man messagebus mldonkey mysql nagios named netdump news nfsnobody \
  nobody nscd ntp nut nx obsrun openvpn operator pcap polkitd postfix \
  postgres privoxy pulse pvm quagga radvd rpc rpcuser rpm rtkit scard shutdown \
  squid sshd statd svn sync tftp usbmux uucp vcsa wwwrun xfs '_*'

#
# Function Completion
#

# Ignore completion functions
zstyle ':completion:*:functions' ignored-patterns '(_*|pre(cmd|exec)|prompt_*|TRAP*|_trap*|_zsh_autosuggest*|_zsh_highlight*)'

#
# Command Completion
#

# Order command groups
zstyle ':completion:*:-command-:*:*' group-order alias builtins functions commands

# Ignore backup files and temporary files
zstyle ':completion:*:complete:-command-::commands' ignored-patterns '*\~|\#*\#|*.zwc|*.zwc.old|*.bak|*.old|*\$'

#
# Subscript Completion
#

zstyle ':completion:*:*:-subscript-:*' tag-order indexes parameters
zstyle ':completion:*:expand:*' tag-order all-expansions
zstyle ':completion:*:expand:*' substitute true

#
# Media Player Completion
#

(( $+commands[mpg123] )) && zstyle ':completion:*:*:mpg123:*' file-patterns '*.(mp3|MP3):mp3\ files *(-/):directories'
(( $+commands[mpg321] )) && zstyle ':completion:*:*:mpg321:*' file-patterns '*.(mp3|MP3):mp3\ files *(-/):directories'
(( $+commands[ogg123] )) && zstyle ':completion:*:*:ogg123:*' file-patterns '*.(ogg|OGG|flac):ogg\ files *(-/):directories'
(( $+commands[mocp] )) && zstyle ':completion:*:*:mocp:*' file-patterns '*.(wav|WAV|mp3|MP3|ogg|OGG|flac):ogg\ files *(-/):directories'
(( $+commands[mpv] )) && zstyle ':completion:*:*:mpv:*' file-patterns '*.(mkv|MKV|mp4|MP4|avi|AVI|mov|MOV|webm|WEBM|flv|FLV|wmv|WMV|mp3|MP3|flac|FLAC|ogg|OGG|wav|WAV|m4a|M4A|aac|AAC):media\ files *(-/):directories'

#
# Email Client Completion
#

if (( $+commands[mutt] )); then
  if [[ -f "$HOME/.mutt/aliases" ]]; then
    zstyle ':completion:*:*:mutt:*' menu yes select
    zstyle ':completion:*:mutt:*' users ${${${(f)"$(<"$HOME/.mutt/aliases")"}#alias[[:space:]]}%%[[:space:]]*}
  fi
fi

#
# Sudo Completion
#

zstyle ':completion:sudo:*' environ PATH="$SUDO_PATH:$PATH"

#
# Correction Behavior
#

zstyle ':completion:*:correct:*' insert-unambiguous true
zstyle ':completion:*:correct:*' original true
zstyle ':completion:*:correct:*' prompt 'correct to: %e'

#
# Recent Directories
#

zstyle ':chpwd:*' recent-dirs-file "${ZSH_CACHE_DIR:-${XDG_CACHE_HOME:-$HOME/.cache}/zsh}/chpwd-recent-dirs"
zstyle ':chpwd:*' recent-dirs-max 1000
zstyle ':completion:*:*:cd:*' recent-dirs-insert both

#
# Expand and Prefix
#

zstyle ':completion:*' recent-dirs-insert both
zstyle ':completion:correct:' prompt 'correct to: %e'

#
# Alias Completion
#

zstyle ':completion:*:aliases' list-colors '=*=1;38;5;214'
zstyle ':completion:*:aliases' ignored-patterns ''

#
# Don't show single ignored matches
#

zstyle '*' single-ignored show
zstyle ':completion::complete:*' gain-privileges 1
