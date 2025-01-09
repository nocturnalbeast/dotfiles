#!/usr/bin/env zsh

#          _
#  ___ ___| |_
# |- _|_ -|   |
# |___|___|_|_|

## 0: make sure this is an interactive shell before setting up interactive shell preferences

[[ $- != *i* ]] && return


## 1: setup plugin manager

if [ -z "$ZINIT_HOME" ]; then
    export ZINIT_HOME="${XDG_DATA_HOME:-${HOME}/.local/share}/zinit"
fi
if [ ! -d "$ZINIT_HOME" ]; then
    mkdir -p "$ZINIT_HOME"
    chmod 0700 "$ZINIT_HOME"
    git clone --depth 10 https://github.com/zdharma-continuum/zinit.git ${ZINIT_HOME}/bin
fi

typeset -gAH ZINIT
ZINIT[HOME_DIR]="${ZINIT_HOME}"
ZINIT[BIN_DIR]="${ZINIT[HOME_DIR]}/bin"
ZINIT[PLUGINS_DIR]="${ZINIT[HOME_DIR]}/plugins"
ZINIT[COMPLETIONS_DIR]="${ZINIT[HOME_DIR]}/completions"
ZINIT[SNIPPETS_DIR]="${ZINIT[HOME_DIR]}/snippets"
ZINIT[SERVICES_DIR]="${ZINIT[HOME_DIR]}/services"
ZINIT[ZCOMPDUMP_PATH]="${ZINIT[HOME_DIR]}/.zcompdump"
ZPFX="${ZINIT[HOME_DIR]}/polaris"

source "$ZINIT_HOME/bin/zinit.zsh"
autoload -Uz _zinit
(( ${+_comps} )) && _comps[zinit]=_zinit


## 2: source global shell profile

if [ -f "$HOME/.profile" ]; then
    . "$HOME/.profile"
fi


## 3: configure command history

[ -z "$HISTFILE" ] && HISTFILE="${XDG_CACHE_HOME:-$HOME/.cache}/shell_history"
HISTORY_IGNORE="(ls|clear|pwd|zsh|exit)"
HISTSIZE=50000
SAVEHIST=50000


## 4: configure other directories according to XDG base directory spec

ZSH_CACHE_DIR="${XDG_:-${HOME}/.local/share}/zsh"
[ -d "$ZSH_CACHE_DIR" ] || mkdir -p "$ZSH_CACHE_DIR"
zstyle ':completion:*' cache-path "$ZSH_CACHE_DIR/zcompcache"


## 5: set zsh-specific environment variables and aliases

[ ! -z "$PS1" ] && typeset -U PATH path
export WORDCHARS="*?[]~=&;!#$%^(){}"


## 6: set shell options

# go into directories without requiring explicit cd command
setopt auto_cd

# better command history
setopt append_history
setopt hist_ignore_all_dups
setopt hist_ignore_dups
setopt hist_ignore_space
setopt hist_no_store
setopt hist_reduce_blanks
setopt hist_save_no_dups
setopt share_history
unsetopt hist_verify

# no irritating beep
unsetopt beep

# show menu for completion
unsetopt list_ambiguous
setopt nolistambiguous

# better expansion, menus and completion
setopt prompt_subst
setopt list_packed
setopt auto_param_slash
setopt auto_remove_slash
setopt mark_dirs
setopt list_types
unsetopt menu_complete
setopt auto_list
setopt auto_menu
setopt auto_param_keys
setopt auto_resume
setopt complete_in_word
setopt magic_equal_subst
setopt path_dirs
setopt auto_name_dirs
setopt always_to_end

# globbing
unsetopt nomatch
setopt glob
setopt extended_glob
setopt numeric_glob_sort

# disable flow control
unsetopt flow_control
setopt no_flow_control

# enable corrections
setopt correct

# better directory stack handling
setopt auto_pushd
setopt pushd_ignore_dups
setopt pushd_to_home
setopt pushd_silent
setopt pushd_minus

# confirm before rm * is executed
setopt rm_star_wait
unsetopt rm_star_silent

# other
setopt hash_cmds
setopt no_hup
setopt ignore_eof
setopt long_list_jobs
setopt short_loops
setopt notify
setopt interactive_comments


## 7: define completion behavior

# show completion only if there is more than one possible candidate
zstyle ':completion:*:default' menu select=2
# explain the completion
zstyle ':completion:*' verbose yes
zstyle ':completion:*:options' auto-description '%d'
zstyle ':completion:*:options' description yes
# define completion method
zstyle ':completion:*' completer _oldlist _complete _match _approximate
# define completion formatting
zstyle ':completion:*:messages' format '%F{yellow} %d'
zstyle ':completion:*:warnings' format '%B%F{red} %F{white}%d%b'
zstyle ':completion:*:descriptions' format '%B%F{cyan} %d%f%b'
zstyle ':completion:*:corrections' format '%B%F{green} %d ( %e) %f%b'
# group completions
zstyle ':completion:*:matches' group 'yes'
zstyle ':completion:*' group-name ''
# case insensitive + hyphen/underscore insensitive matching
zstyle ':completion:*' matcher-list 'm:{a-zA-Z-_}={A-Za-z_-}' 'r:|=*' 'l:|=* r:|=*'
# colorize filename completion with LS_COLORS
zstyle ':completion:*' list-colors "${LS_COLORS}"
zstyle ':completion:*' special-dirs true
# enable caching since some command definitions take longer
zstyle ':completion:*' use-cache yes
# sort files in completion menu by name
zstyle ':completion:*' file-sort name
# correction options
zstyle ':completion:*:correct:*' insert-unambiguous true
zstyle ':completion:*:correct:*' original true
# make chpwd_recent_dirs respect XDG spec
zstyle ':chpwd:*' recent-dirs-file "${XDG_CACHE_HOME:="$HOME/.cache"}/chpwd-recent-dirs"
# shell history completion options
zstyle ':completion:*:history-words' list false
zstyle ':completion:*:history-words' menu yes
zstyle ':completion:*:history-words' remove-all-dups yes
zstyle ':completion:*:history-words' stop yes
# autocorrection
zstyle ':completion:*:match:*' original only
zstyle -e ':completion:*:approximate:*' max-errors 'reply=( $(( ($#PREFIX+$#SUFFIX)/3 )) numeric )'
# enable autocompletion of privileged environments in privileged commands
zstyle ':completion::complete:*' gain-privileges 1
# cd completion
zstyle ':completion:*:*:cd:*:directory-stack' menu yes select
zstyle ':completion:*:cd:*' tag-order local-directories path-directories
zstyle ':completion:*:cd:*' group-order local-directories path-directories
# man completion 
zstyle ':completion:*:manuals' separate-sections true
zstyle ':completion:*:manuals.*' insert-sections true
zstyle ':completion:*:man:*' menu yes select
# process list / kill list completion
zstyle ':completion:*:processes' command 'ps -au$USER'
zstyle ':completion:*:*:*:*:processes' command 'ps -u $LOGNAME -o pid,user,command -w'
zstyle ':completion:*:*:kill:*:processes' list-colors '=(#b) #([0-9]#) ([0-9a-z-]#)*=01;36=0=01'
zstyle ':completion:*:*:kill:*' menu yes select
zstyle ':completion:*:*:kill:*' force-list always
zstyle ':completion:*:*:kill:*' insert-ids single
# make completion
zstyle ':completion:*:make:*:targets' call-command true
zstyle ':completion:*:make::' tag-order targets:
zstyle ':completion:*:*:*make:*:targets' command awk \''/^[a-zA-Z0-9][^\/\t=]+:/ {print $1}'\' \$file
# jobs completion
zstyle ':completion:*:jobs' numbers true

# TODO: options to be reviewed later
# ignore certain patterns
zstyle ':completion:*:complete:-command-::commands' ignored-patterns '*\~'
zstyle ':completion:*:*:zcompile:*' ignored-patterns '(*~|*.zwc)'
zstyle ':completion::(^approximate*):*:functions' ignored-patterns '_*'
# other completion options
zstyle -e ':completion:*' special-dirs '[[ $PREFIX = (../)#(|.|..) ]] && reply=(..)'
zstyle ':completion:*:*:-subscript-:*' tag-order indexes parameters
zstyle ':completion:*:expand:*' tag-order all-expansions
zstyle ':completion:*' accept-exact '*(N)'
zstyle ':completion:*' keep-prefix
zstyle ':completion:*' recent-dirs-insert both
zstyle ':completion:correct:' prompt 'correct to: %e'


## 8: load functions

if [ -f "$ZDOTDIR/functions" ]; then
    . "$ZDOTDIR/functions"
elif [ -f "$ZDOTDIR/functions.zsh" ]; then
    . "$ZDOTDIR/functions.zsh"
fi


## 9: define keybindings

# use emacs keybindings
bindkey -e

if (( ${+terminfo[smkx]} )) && (( ${+terminfo[rmkx]} )); then
    function zle-line-init() { echoti smkx }
    function zle-line-finish() { echoti rmkx }
    zle -N zle-line-init
    zle -N zle-line-finish
fi
# get keys from terminfo
typeset -g -A key

key[Insert]="$terminfo[kich1]"
key[Delete]="$terminfo[kdch1]"
key[Home]="$terminfo[khome]"
key[End]="$terminfo[kend]"
key[PageUp]="$terminfo[kpp]"
key[PageDown]="$terminfo[knp]"

key[Up]="$terminfo[kcuu1]"
key[Down]="$terminfo[kcud1]"
key[Left]="$terminfo[kcub1]"
key[Right]="$terminfo[kcuf1]"

key[Backspace]="$terminfo[kbs]"
key[Enter]="$terminfo[kent]"

key[Function1]="$terminfo[kf1]"
key[Function2]="$terminfo[kf2]"
key[Function3]="$terminfo[kf3]"
key[Function4]="$terminfo[kf4]"
key[Function5]="$terminfo[kf5]"
key[Function6]="$terminfo[kf6]"
key[Function7]="$terminfo[kf7]"
key[Function8]="$terminfo[kf8]"
key[Function9]="$terminfo[kf9]"
key[Function10]="$terminfo[kf10]"
key[Function11]="$terminfo[kf11]"
key[Function12]="$terminfo[kf12]"

key[ShiftTab]="$terminfo[kcbt]"

[[ -n "$key[Insert]" ]] && bindkey - "$key[Insert]" overwrite-mode
[[ -n "$key[Delete]" ]] && bindkey - "$key[Delete]" delete-char
[[ -n "$key[Home]" ]] && bindkey - "$key[Home]" beginning-of-line
[[ -n "$key[End]" ]] && bindkey - "$key[End]" end-of-line
[[ -n "$key[Up]" ]] && bindkey - "$key[Up]" up-line-or-history
[[ -n "$key[Down]" ]] && bindkey - "$key[Down]" down-line-or-history
[[ -n "$key[Left]" ]] && bindkey - "$key[Left]" backward-char
[[ -n "$key[Right]" ]] && bindkey - "$key[Right]" forward-char
[[ -n "$key[Backspace]" ]] && bindkey - "$key[Backspace]" backward-delete-char
[[ -n "$key[ShiftTab]" ]] && bindkey - "$key[ShiftTab]" reverse-menu-complete
[[ -n "$key[PageUp]" ]] && bindkey - "$key[PageUp]" beginning-of-buffer-or-history
[[ -n "$key[PageDown]" ]] && bindkey - "$key[PageDown]" end-of-buffer-or-history

# keybindings w/o terminfo
# TODO: modify these to use terminfo first then the specified keybindings as fallback
# NOTE: this might not work on all terminals
# ctrl+[left,right] for moving one word at a time
bindkey "\e[1;5D" backward-word
bindkey "\e[1;5C" forward-word
# ctrl+backspace to delete the word behind the cursor
bindkey "^H" backward-kill-word
# ctrl+delete to delete the word in front of the cursor
bindkey "\e[3;5~" kill-word
# shift+arrow keys to move around directories
bindkey '^[[1;2D' cd-back
bindkey '^[[1;2C' cd-forward
bindkey '^[[1;2A' cd-up
bindkey '^[[1;2B' cd-down


## 10: plugins

# define hook script directories
ATCLONE_DIR="$ZDOTDIR/scripts_atclone"
ATPULL_DIR="$ZDOTDIR/scripts_atpull"
ATINIT_DIR="$ZDOTDIR/scripts_atinit"
ATLOAD_DIR="$ZDOTDIR/scripts_atload"

# zinit annexes
zinit light-mode for \
        @zdharma-continuum/zinit-annex-readurl \
        @zdharma-continuum/zinit-annex-bin-gem-node \
        @zdharma-continuum/zinit-annex-patch-dl

# basic zsh enhancement plugins - must have in any setup
# TODO: need to experiment replacing with zsh-autocomplete
zinit wait'0' lucid light-mode for \
    id-as'fast-syntax-highlighting' atload'source $ATLOAD_DIR/fastsyntaxhighlighting.zsh' \
        @zdharma-continuum/fast-syntax-highlighting \
    id-as'zsh-autosuggestions' atinit'source $ATINIT_DIR/autosuggestions.zsh' atload'source $ATLOAD_DIR/autosuggestions.zsh' \
        @zsh-users/zsh-autosuggestions \
    id-as'zsh-completions' blockf atpull'source $ATPULL_DIR/completions.zsh' \
        @zsh-users/zsh-completions \
    id-as'zsh-history-substring-search' atload'source $ATLOAD_DIR/hss.zsh' \
        @zsh-users/zsh-history-substring-search

# fuzzy finder and integrations
# NOTE: the following may override some completion styles we've defined earlier
#       so if fuzzy search is not important, remove the following section
zinit wait'0' lucid from'gh-r' nocompile light-mode for \
    id-as'fzf' \
    dl'https://raw.githubusercontent.com/junegunn/fzf/master/bin/fzf-tmux' \
    dl'https://raw.githubusercontent.com/junegunn/fzf/master/shell/completion.zsh -> completion.zsh' \
    dl'https://raw.githubusercontent.com/junegunn/fzf/master/shell/key-bindings.zsh -> key-bindings.zsh' \
    dl'https://raw.githubusercontent.com/junegunn/fzf/master/man/man1/fzf-tmux.1 -> man/fzf-tmux.1' \
    dl'https://raw.githubusercontent.com/junegunn/fzf/master/man/man1/fzf.1 -> man/fzf.1' \
    atclone'source $ATCLONE_DIR/fzf.zsh' \
    atpull'%atclone' \
    atload'source $ATLOAD_DIR/fzf.zsh' \
    pick'/dev/null' \
    sbin'fzf' \
    sbin'fzf-tmux' \
    multisrc'key-bindings.zsh' \
    multisrc'completion.zsh' \
        @junegunn/fzf
# NOTE: @amaya382/zsh-fzf-widgets has a bug with fzf-history widget, using the fix repo instead
zinit wait'0b' lucid light-mode for \
    id-as'fz' atinit'source $ATINIT_DIR/fz.zsh' \
        @mrjohannchang/fz.sh \
    id-as'fzf-tab' atload'source $ATLOAD_DIR/fzftab.zsh' \
        @Aloxaf/fzf-tab \
    id-as'fzf-widgets' atload'source $ATLOAD_DIR/fzfwidgets.zsh' \
        @magthe/zsh-fzf-widgets \
    id-as'fzf-finder' \
        @leophys/zsh-plugin-fzf-finder

# enhance git
zinit wait'0a' lucid light-mode for \
    id-as'forgit' atload'source $ATLOAD_DIR/forgit.zsh' \
        @wfxr/forgit \
    id-as'git-extras' as'program' pick'$ZPFX/bin/git-*' make'PREFIX=$ZPFX' nocompile \
        @tj/git-extras \
    id-as'git-extra-commands' as'program' pick'bin/git-*' nocompile \
        @unixorn/git-extra-commands \
    id-as'git-cal' nocompile atclone'source $ATCLONE_DIR/gitcal.zsh' atpull'%atclone' make'install' sbin'git-cal' \
        @k4rthik/git-cal \
    id-as'git-open' sbin'git-open' \
        @paulirish/git-open \
    id-as'git-recent' nocompile sbin'git-recent' \
        @paulirish/git-recent \
    id-as'git-my' nocompile sbin'git-my' \
        @davidosomething/git-my \
    id-as'gitcd' atload'source $ATLOAD_DIR/gitcd.zsh' \
        @viko16/gitcd.plugin.zsh

# enhance cd
zinit wait'0' lucid light-mode for \
    id-as'zoxide' from'gh-r' as'program' pick'zoxide-*/zoxide' atload'source $ATLOAD_DIR/zoxide.zsh' \
        @ajeetdsouza/zoxide \
    id-as'autoenv' \
        @Tarrasch/zsh-autoenv \
    id-as'cd-gitroot' atinit'source $ATINIT_DIR/cdgitroot.zsh' \
        @mollifier/cd-gitroot \
    id-as'bd' \
        @Tarrasch/zsh-bd \
    id-as'marks' atinit'source $ATINIT_DIR/marks.zsh' \
        @jocelynmallon/zshmarks

# colorize command output 
zinit wait'0' lucid light-mode for \
    id-as'grc' atclone'source $ATCLONE_DIR/grc.zsh' atpull'%atclone' compile'grc.zsh' src'grc.zsh' sbin'(grc|grcat)' \
        @garabik/grc

# correct commands
zinit wait'0' lucid light-mode for \
    id-as'zsh-thefuck' \
        @laggardkernel/zsh-thefuck

# pair brackets and quotations
zinit wait'0' lucid light-mode for \
    id-as'zsh-autopair' atinit'source $ATINIT_DIR/autopair.zsh' atload'source $ATLOAD_DIR/autopair.zsh' \
        @hlissner/zsh-autopair

# command to copy to clipboard
zinit wait'0' lucid light-mode for \
    id-as'yank' sbin'$ZPFX/bin/yank' make'PREFIX=$ZPFX install' nocompile \
        @mptre/yank

# use ctrl-z to jump both in and out of the program
zinit wait'0' lucid light-mode for \
    id-as'fancy-ctrl-z' \
        @mdumitru/fancy-ctrl-z

# emojis, cause why not?
zinit wait'0' lucid light-mode for \
    id-as'emoji-cli' atinit'source $ATINIT_DIR/emojicli.zsh' \
        @babarot/emoji-cli

# remind you of your aliases
zinit wait'0' lucid light-mode for \
    id-as'zsh-you-should-use' atinit'source $ATINIT_DIR/ysu.zsh' \
        @MichaelAquilina/zsh-you-should-use

# input sudo in the current command
zinit wait'0' lucid light-mode for \
    id-as'sudo' \
        OMZP::sudo

# extract command
zinit wait'0' lucid light-mode for \
    id-as'extract' \
        OMZP::extract

# pip helper
zinit wait'0' lucid light-mode for \
    id-as'pip' \
        OMZP::pip

# alias expansion
zinit wait'0' lucid light-mode for \
    id-as'zsh-abbrev-alias' atload'source $ATLOAD_DIR/abbrev-alias.zsh' \
        @momo-lab/zsh-abbrev-alias

# let the shell set the terminal window name
zinit wait'0' lucid light-mode for \
    id-as'tab-title' atload'source $ATLOAD_DIR/tabtitle.zsh' \
        @trystan2k/zsh-tab-title

# have notifications for long-running commands
zinit wait'0' lucid light-mode for \
    id-as'auto-notify' atload'source $ATLOAD_DIR/autonotify.zsh' patch"$ZDOTDIR/patches/auto-notify.patch" atclone'rm -f ./auto-notify.plugin.zsh.zwc && zcompile auto-notify.plugin.zsh' \
        @MichaelAquilina/zsh-auto-notify

# more completions (don't use wait-ice for this one or else compinit doesn't load these completions)
zinit wait'0' lucid light-mode for \
    id-as'more-completions' nocompile nocompletions \
        @MenkeTechnologies/zsh-more-completions \
    id-as'completion-generator' atinit'source $ATINIT_DIR/completion-generator.zsh' \
        @RobSis/zsh-completion-generator

# programs from github releases - load binaries using zinit
zinit wait'1' lucid from'gh-r' nocompile light-mode for \
    id-as'gh-cli' bpick'gh_*.tar.gz' mv'gh*/bin/gh -> gh' sbin'gh' atload'$ATLOAD_DIR/gh.zsh' \
        @cli/cli \
    id-as'gh-hub' cp'hub-*/etc/hub.zsh_completion -> _hub' pick'hub-*' mv'hub-*/bin/hub -> hub' sbin'hub' \
        @mislav/hub \
    id-as'eza' bpick'eza-*' sbin'eza' \
        @eza-community/eza \
    id-as'ripgrep' blockf nocompletions bpick'ripgrep-*' mv'ripgrep-*/rg -> rg' sbin'rg' atclone'source $ATCLONE_DIR/ripgrep.zsh' atpull'%atclone' \
        @BurntSushi/ripgrep \
    id-as'fd' blockf nocompletions bpick'fd-*' mv'fd-*/fd -> fd' sbin'fd' atclone'source $ATCLONE_DIR/fd.zsh' atpull'%atclone' \
        @sharkdp/fd \
    id-as'bat' bpick'bat-*' mv'bat-*/bat -> bat' sbin'bat' \
        @sharkdp/bat \
    id-as'bottom' bpick'bottom_*' sbin'btm' \
        @ClementTsang/bottom \
    id-as'delta' bpick'delta-*' mv'delta-*/delta -> delta' sbin'delta' \
        @dandavison/delta \
    id-as'navi' bpick'navi-*' sbin'navi' \
        @denisidoro/navi \
    id-as'tealdeer' pick'tealdeer-*' mv'tealdeer-* -> tldr' sbin'tldr' \
        @tealdeer-rs/tealdeer \
    id-as'mmv' bpick'mmv_*' mv'mmv_*/mmv -> mmv' sbin'mmv' \
        @itchyny/mmv \
    id-as'hexyl' bpick'hexyl-*' mv'hexyl-*/hexyl -> hexyl' sbin'hexyl' \
        @sharkdp/hexyl \
    id-as'glow' bpick'*.tar.gz' sbin'glow' \
        @charmbracelet/glow \
    id-as'hyperfine' bpick'hyperfine-*' mv'hyperfine-*/hyperfine -> hyperfine' sbin'hyperfine' \
        @sharkdp/hyperfine \
    id-as'jq' pick'jq-*' mv'jq-* -> jq' sbin'jq' \
        @jqlang/jq \
    id-as'xh' bpick'*.tar.gz' mv'xh-*/xh -> xh' sbin'xh' \
        @ducaale/xh \
    id-as'yq' bpick'yq_*' mv'yq_* -> yq' sbin'yq' \
        @mikefarah/yq \
    id-as'bandwhich' bpick'bandwhich*' sbin'bandwhich' \
        @imsnif/bandwhich \
    id-as'duf' bpick'duf_*.tar.gz' sbin'duf' \
        @muesli/duf \
    id-as'trashy' bpick'trash-*.tar.gz' nocompile nocompletions sbin'trash' \
        @oberblastmeister/trashy \
    id-as'vivid' bpick'vivid-*' mv'vivid-*/vivid -> vivid' sbin'vivid' \
        @sharkdp/vivid \
    id-as'shfmt' mv'shfmt* -> shfmt' sbin'shfmt' \
        @mvdan/sh \
    id-as'mise' bpick'mise-*.tar.gz' atclone'source $ATCLONE_DIR/mise.zsh' atpull'%atclone' atload'source $ATLOAD_DIR/mise.zsh' nocompile nocompletions mv'mise/bin/mise -> mise' sbin'mise' \
        @jdx/mise \
    id-as'stylua' bpick'*.zip' sbin'stylua' \
        @JohnnyMorganz/StyLua \
    id-as'fx' bpick'fx*' mv'fx* -> fx' sbin'fx' \
        @antonmedv/fx \
    id-as'lemmeknow' bpick'lemmeknow-*' mv'lemmeknow-* -> lemmeknow' sbin'lemmeknow' \
        @swanandx/lemmeknow \
    id-as'difftastic' bpick'difft-*' sbin'difft' \
        @wilfred/difftastic \
    id-as'shellcheck' bpick'shellcheck-*' mv'shellcheck-*/shellcheck -> shellcheck' sbin'shellcheck' \
        @koalaman/shellcheck \
    id-as'cocogitto' bpick'cocogitto-*' mv'*/cog -> cog' sbin'cog' atload'$ATLOAD_DIR/cocogitto.zsh' \
        @cocogitto/cocogitto \
    id-as'gron' bpick'gron*' sbin'gron' \
        @tomnomnom/gron

# programs from github (without releases/binaries) - load / source using zinit
zinit wait'1' lucid light-mode for \
    id-as'translate-shell' ver"stable" pullopts"--rebase" \
        @soimort/translate-shell \
    id-as'zsh-sweep' sbin'bin/zsweep' \
        @psprint/zsh-sweep \
    id-as'pathpicker' sbin'fpp' atclone'$ATCLONE_DIR/pathpicker.zsh' \
        @facebook/PathPicker

# completions for some of the above programs
zinit wait'1' lucid as'completion' light-mode for \
    id-as'tealdeer-completion' mv'tealdeer-completion -> _tldr' \
        https://github.com/dbrgn/tealdeer/raw/main/completion/zsh_tealdeer \
    id-as'pip-completion' \
        OMZP::pip/_pip \
    id-as'eza-completion' \
        https://github.com/eza-community/eza/raw/main/completions/zsh/_eza


## 11: prompt theme

# using starship for the consistent prompt across shells
eval "$(starship init zsh)"
if [ ! -f "$ZINIT[COMPLETIONS_DIR]/_starship" ]; then
    starship completions zsh > "$ZINIT[COMPLETIONS_DIR]/_starship"
fi


## 12: post-startup actions

# source all system-provided completions
if [[ -d "/usr/share/zsh/site-functions" ]]; then
    for FILE in "/usr/share/zsh/site-functions/*"; do
        if [[ -f "$FILE" ]]; then
            zinit wait'1' lucid as'completion' blockf "$FILE"
        fi
    done
fi

# add plugin-related manpages into the MANPATH
export MANPATH="$MANPATH:$ZPFX/share/man"

# compinit + cdreplay
autoload -Uz compinit
if [[ $ZINIT[ZCOMPDUMP_PATH](#qNmh-20) ]]; then
    compinit -C -d ${ZINIT[ZCOMPDUMP_PATH]:-${ZDOTDIR:-$HOME}/.zcompdump} "${(Q@)${(z@)ZINIT[COMPINIT_OPTS]}}"
else
    mkdir -p "$ZINIT[ZCOMPDUMP_PATH]:h"
    compinit -i -d ${ZINIT[ZCOMPDUMP_PATH]:-${ZDOTDIR:-$HOME}/.zcompdump} "${(Q@)${(z@)ZINIT[COMPINIT_OPTS]}}"
    touch "$ZINIT[ZCOMPDUMP_PATH]"
fi
zinit cdreplay
