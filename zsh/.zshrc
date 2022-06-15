#!/usr/bin/env zsh

#          _
#  ___ ___| |_
# |- _|_ -|   |
# |___|___|_|_|


## 1: setup plugin manager

if [ -z "$ZINIT_HOME" ]; then
    ZINIT_HOME="${XDG_CONFIG_HOME:-$HOME/.config}/zinit"
fi

if ! test -d "$ZINIT_HOME"; then
    mkdir -p "$ZINIT_HOME"
    chmod g-rwX "$ZINIT_HOME"
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


## 2: configure command history

[ -z "$HISTFILE" ] && HISTFILE="${XDG_CACHE_HOME:-$HOME/.cache}/shell_history"
HISTORY_IGNORE="(ls|clear|pwd|zsh|exit)"
HISTSIZE=50000
SAVEHIST=50000


## 3: import generic environment variables and aliases

# just source .profile, it will source required environment variables and aliases
source "$HOME/.profile"


## 4: set zsh-specific environment variables and aliases

[ ! -z "$PS1" ] && typeset -U PATH path
export WORDCHARS="*?[]~=&;!#$%^(){}"


## 5: set shell options

# go into directories without requiring explicit cd command
setopt auto_cd

# better command history
setopt append_history
setopt share_history
setopt hist_ignore_all_dups
setopt hist_ignore_dups
setopt hist_ignore_space
unsetopt hist_verify
setopt hist_reduce_blanks
setopt hist_save_no_dups
setopt hist_no_store

# no irritating beep
unsetopt beep

# better expansion, menus and completion
setopt prompt_subst
setopt list_packed
setopt auto_param_slash
setopt auto_remove_slash
setopt mark_dirs
setopt list_types
unsetopt menu_complete
setopt auto_list
unsetopt list_ambiguous
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

# enable corrections
setopt correct

# better directory stack handling
setopt auto_pushd
setopt pushd_ignore_dups
setopt pushd_to_home
setopt pushd_silent
setopt pushd_minus

# other
setopt hash_cmds
setopt no_hup
setopt ignore_eof
setopt long_list_jobs
setopt short_loops
setopt notify
setopt interactive_comments


## 6: define completion behavior

# enable caching
zstyle ':completion:*' accept-exact '*(N)'
zstyle ':completion:*' use-cache yes
zstyle ':completion:*' cache-path $ZSH_CACHE_DIR

# autocorrection
zstyle ':completion:*' completer _complete _match _approximate
zstyle ':completion:*:match:*' original only
zstyle -e ':completion:*:approximate:*' max-errors 'reply=( $(( ($#PREFIX+$#SUFFIX)/3 )) numeric )'

# formatting on completion
zstyle ':completion:*:messages' format '%F{yellow} %d'
zstyle ':completion:*:warnings' format '%B%F{red} %F{white}%d%b'
zstyle ':completion:*:descriptions' format '%B%F{cyan} %d%f%b'
zstyle ':completion:*:corrections' format '%B%F{green} %d ( %e) %f%b'

# colorize filename completion with LS_COLORS
zstyle ':completion:*:default' list-colors ${(s.:.)LS_COLORS}

# completion grouping
zstyle ':completion:*:matches' group 'yes'
zstyle ':completion:*' group-name ''

# sort files in completion menu by name
zstyle ':completion:*' file-sort name

# correction options
zstyle ':completion:*:correct:*' insert-unambiguous true
zstyle ':completion:*:correct:*' original true

# show directory stack menu completion
zstyle ':completion:*:correct:*' original true

# show directory stack menu completion
zstyle ':completion:*:*:cd:*:directory-stack' menu yes select

# shell history completion options
zstyle ':completion:*:history-words' list false
zstyle ':completion:*:history-words' menu yes
zstyle ':completion:*:history-words' remove-all-dups yes
zstyle ':completion:*:history-words' stop yes

# ignore certain patterns
zstyle ':completion:*:complete:-command-::commands' ignored-patterns '*\~'
zstyle ':completion:*:*:zcompile:*' ignored-patterns '(*~|*.zwc)'
zstyle ':completion::(^approximate*):*:functions' ignored-patterns '_*'

# case insensitive + hyphen/underscore insensitive matching
zstyle ':completion:*' matcher-list 'm:{a-zA-Z-_}={A-Za-z_-}' 'r:|=*' 'l:|=* r:|=*'

# other completion options
zstyle ':completion:*' menu select=2
zstyle ':completion:*' verbose true
zstyle -e ':completion:*' special-dirs '[[ $PREFIX = (../)#(|.|..) ]] && reply=(..)'
zstyle ':completion:*:options' auto-description '%d'
zstyle ':completion:*:options' description 'yes'
zstyle ':completion:*:expand:*' tag-order all-expansions
zstyle ':completion:*:jobs' numbers true
zstyle ':completion:*:*:-subscript-:*' tag-order indexes parameters
zstyle ':completion:correct:' prompt 'correct to: %e'
zstyle ':completion::complete:*' gain-privileges 1

# make chpwd_recent_dirs respect XDG spec
zstyle ':chpwd:*' recent-dirs-file "${XDG_CACHE_HOME:="$HOME/.cache"}/chpwd-recent-dirs"

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

# taskwarrior completion
zstyle ':completion:*:*:task:*' verbose yes
zstyle ':completion:*:*:task:*:descriptions' format '%U%B%d%b%u'
zstyle ':completion:*:*:task:*' group-name ''

# make completion
zstyle ':completion:*:make:*:targets' call-command true
zstyle ':completion:*:make::' tag-order targets:
zstyle ':completion:*:*:*make:*:targets' command awk \''/^[a-zA-Z0-9][^\/\t=]+:/ {print $1}'\' \$file


## 7: define keybindings

bindkey -e

if (( ${+terminfo[smkx]} )) && (( ${+terminfo[rmkx]} )); then
    function zle-line-init() { echoti smkx }
    function zle-line-finish() { echoti rmkx }
    zle -N zle-line-init
    zle -N zle-line-finish
fi

typeset -g -A key

# get keys from terminfo

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

# keybindings w/o terminfo
# NOTE: this might not work on all terminals
# ctrl+[left,right] for moving one word at a time
bindkey "\e[1;5D" backward-word
bindkey "\e[1;5C" forward-word
# ctrl+backspace to delete the word behind the cursor
bindkey "^H" backward-kill-word
# ctrl+delete to delete the word in front of the cursor
bindkey "\e[3;5~" kill-word


## 8: plugins

# define hook script directories
HOOKSCRIPT_DIR="${XDG_CONFIG_HOME:-$HOME/.config}/zsh"
ATCLONE_DIR="$HOOKSCRIPT_DIR/scripts_atclone"
ATPULL_DIR="$HOOKSCRIPT_DIR/scripts_atpull"
ATINIT_DIR="$HOOKSCRIPT_DIR/scripts_atinit"
ATLOAD_DIR="$HOOKSCRIPT_DIR/scripts_atload"

# zinit annexes
zinit light-mode for \
        @zdharma-continuum/zinit-annex-readurl \
        @zdharma-continuum/zinit-annex-bin-gem-node

# basic zsh enhancement plugins - must have in any setup
zinit wait'0' lucid light-mode for \
    id-as'fast-syntax-highlighting' \
        @zdharma-continuum/fast-syntax-highlighting \
    atinit'source $ATINIT_DIR/autosuggestions.zsh' atload'source $ATLOAD_DIR/autosuggestions.zsh' id-as'zsh-autosuggestions' \
        @zsh-users/zsh-autosuggestions \
    blockf atpull'source $ATPULL_DIR/completions.zsh' id-as'zsh-completions' \
        @zsh-users/zsh-completions \
    atload'source $ATLOAD_DIR/hss.zsh' id-as'zsh-history-substring-search' \
        @zsh-users/zsh-history-substring-search

# enhance git
zinit wait'0' lucid light-mode for \
    atinit'source $ATINIT_DIR/forgit.zsh' id-as'forgit' \
        @wfxr/forgit \
    as'program' pick'$ZPFX/bin/git-*' make'PREFIX=$ZPFX' nocompile id-as'git-extras' \
        @tj/git-extras \
    as'program' pick'bin/git-*' nocompile id-as'git-extra-commands' \
        @unixorn/git-extra-commands \
    atclone'source $ATCLONE_DIR/gitcal.zsh' atpull'%atclone' make'install' sbin'bin/git-cal' id-as'git-cal' \
        @k4rthik/git-cal \
    sbin'git-open' id-as'git-open' \
        @paulirish/git-open \
    sbin'git-recent' id-as'git-recent' \
        @paulirish/git-recent \
    sbin'git-my' id-as'git-my' \
        @davidosomething/git-my \
    atload'source $ATLOAD_DIR/gitcd.zsh' id-as'gitcd' \
        @viko16/gitcd.plugin.zsh

# enhance cd
zinit wait'0' lucid light-mode for \
    id-as'zsh-autoenv' \
        @Tarrasch/zsh-autoenv \
    atinit'source $ATINIT_DIR/z.zsh' id-as'zsh-z' \
        @agkozak/zsh-z \
    atinit'source $ATINIT_DIR/cdgitroot.zsh' id-as'cd-gitroot' \
        @mollifier/cd-gitroot \
    id-as'zsh-bd' \
        @Tarrasch/zsh-bd \
    atinit'source $ATINIT_DIR/marks.zsh' id-as'zshmarks' \
        @jocelynmallon/zshmarks \
    id-as'up' \
        @peterhurford/up.zsh

# colorize command output 
zinit wait'0' lucid light-mode for \
    atclone'source $ATCLONE_DIR/grc.zsh' atpull'%atclone' compile'grc.zsh' src'grc.zsh' sbin'(grc|grcat)' id-as'grc' \
        @garabik/grc

# correct commands
zinit wait'0' lucid light-mode for \
    id-as'zsh-thefuck' \
        @laggardkernel/zsh-thefuck

# pair brackets and quotations
zinit wait'0' lucid light-mode for \
    atinit'source $ATINIT_DIR/autopair.zsh' atload'source $ATLOAD_DIR/autopair.zsh' id-as'zsh-autopair' \
        @hlissner/zsh-autopair

# command to copy to clipboard
zinit wait'0' lucid light-mode for \
    sbin'$ZPFX/bin/yank' make'PREFIX=$ZPFX install' nocompile id-as'yank' \
        @mptre/yank

# use ctrl-z to jump both in and out of the program
zinit wait'0' lucid light-mode for \
    id-as'fancy-ctrl-z' \
        @mdumitru/fancy-ctrl-z

# emojis, cause why not?
zinit wait'0' lucid light-mode for \
    atinit'source $ATINIT_DIR/emojicli.zsh' id-as'emoji-cli' \
        @b4b4r07/emoji-cli

# remind you of your aliases
zinit wait'0' lucid light-mode for \
    atinit'source $ATINIT_DIR/ysu.zsh' id-as'zsh-you-should-use' \
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

# let the shell set the terminal window name
zinit wait'0' lucid light-mode for \
    atload'source $ATLOAD_DIR/tabtitle.zsh' id-as'tab-title' \
        @trystan2k/zsh-tab-title

# a ton more completions (don't use wait-ice for this one or else compinit doesn't load these completions)
zinit lucid light-mode for \
    nocompile nocompletions id-as'zsh-more-completions' \
        @MenkeTechnologies/zsh-more-completions

# programs from github releases - load binaries using zinit
zinit wait'0' lucid from'gh-r' nocompile light-mode for \
    bpick'gh_*.tar.gz' mv'gh*/bin/gh -> gh' sbin'gh' atload'source $ATLOAD_DIR/gh.zsh' id-as'gh-cli' \
        @cli/cli \
    bpick'hub-*' mv'hub-*/bin/hub -> hub' sbin'hub' id-as'gh-hub' \
        @github/hub \
    bpick'exa-*' mv'bin/exa -> exa' sbin'exa' atclone'source $ATCLONE_DIR/exa.zsh' id-as'exa' \
        @ogham/exa \
    blockf nocompletions bpick'ripgrep-*' mv'ripgrep-*/rg -> rg' sbin'rg' atclone'source $ATCLONE_DIR/ripgrep.zsh' atpull'%atclone' id-as'ripgrep' \
        @BurntSushi/ripgrep \
    blockf nocompletions bpick'fd-*' mv'fd-*/fd -> fd' sbin'fd' atclone'source $ATCLONE_DIR/fd.zsh' atpull'%atclone' id-as'fd' \
        @sharkdp/fd \
    bpick'bat-*' mv'bat-*/bat -> bat' sbin'bat' id-as'bat' \
        @sharkdp/bat \
    bpick'bottom_*' sbin'btm' id-as'bottom' \
        @ClementTsang/bottom \
    bpick'delta-*' mv'delta-*/delta -> delta' sbin'delta' id-as'delta' \
        @dandavison/delta \
    bpick'navi-*' sbin'navi' id-as'navi' \
        @denisidoro/navi \
    pick'tealdeer-*' mv'tealdeer-* -> tldr' sbin'tldr' id-as'tealdeer' \
        @dbrgn/tealdeer \
    bpick'mmv_*' mv'mmv_*/mmv -> mmv' sbin'mmv' id-as'mmv' \
        @itchyny/mmv \
    bpick'hexyl-*' mv'hexyl-*/hexyl -> hexyl' sbin'hexyl' id-as'hexyl' \
        @sharkdp/hexyl \
    bpick'tokei-*' sbin'tokei' id-as'tokei' \
        @XAMPPRocky/tokei \
    bpick'*.tar.gz' sbin'glow' id-as'glow' \
        @charmbracelet/glow \
    bpick'hyperfine-*' mv'hyperfine-*/hyperfine -> hyperfine' sbin'hyperfine' id-as'hyperfine' \
        @sharkdp/hyperfine \
    pick'jq-*' mv'jq-* -> jq' sbin'jq' id-as'jq' \
        @stedolan/jq \
    bpick'*.tar.gz' mv'xh-*/xh -> xh' sbin'xh' id-as'xh' \
        @ducaale/xh \
    pick'yq_*' mv'yq_* -> yq' sbin'yq' id-as'yq' \
        @mikefarah/yq \
    bpick'bandwhich*' sbin'bandwhich' id-as'bandwhich' \
        @imsnif/bandwhich \
    bpick'duf_*.tar.gz' sbin'duf' id-as'duf' \
        @muesli/duf

# completions for some of the above programs
zinit wait'0' lucid as'completion' light-mode for \
    mv'tealdeer-completion -> _tldr' id-as'tealdeer-completion' \
        https://github.com/dbrgn/tealdeer/raw/main/completion/zsh_tealdeer \
    mv'hub-completion -> _hub' id-as'hub-completion' \
        https://github.com/github/hub/raw/master/etc/hub.zsh_completion \
    id-as'pip-completion' \
        OMZP::pip/_pip

# tmux - thank you @yutakatay for this one!
if ldconfig -p | grep -q 'libevent-' && ldconfig -p | grep -q 'libncurses'; then
    zinit wait'0' lucid from'gh-r' light-mode for \
        bpick'tmux-*.tar.gz' sbin'tmux' atclone'source $ATCLONE_DIR/tmux.zsh' atpull'%atclone' id-as'tmux' \
            @tmux/tmux
elif builtin command -v tmux > /dev/null 2>&1 && test $(echo "$(tmux -V | cut -d' ' -f2) <= "2.5"" | tr -d '[:alpha:]' | bc) -eq 1; then
    zinit wait'0' lucid from'gh-r' light-mode for \
        bpick'*AppImage*' mv'tmux* -> tmux' sbin'tmux' id-as'tmux' \
            @tmux/tmux
fi

# NOTE: the following may override some completion styles we've defined earlier
#       so if fuzzy search is not important, remove the following section

# fuzzy finder
zinit wait'0' lucid from'gh-r' nocompile light-mode for \
    bpick'fzf-*.tar.gz' sbin'fzf' atload'source $ATLOAD_DIR/fzf.zsh' id-as'fzf' \
        @junegunn/fzf
zinit wait'0' lucid as'completion' light-mode for \
    mv'fzf-completion -> _fzf' id-as'fzf-completion' \
        https://github.com/junegunn/fzf/raw/master/shell/completion.zsh
zinit wait'1' lucid light-mode for \
    sbin'bin/fzf-tmux' nocompile id-as'fzf-tmux' \
        @junegunn/fzf \
    atload'source $ATLOAD_DIR/fzfwidgets.zsh' id-as'fzf-widgets' \
        @crater2150-zsh/fzf-widgets \
    atinit'source $ATINIT_DIR/fz.zsh' id-as'fz' \
        @changyuheng/fz \
    atload'source $ATLOAD_DIR/fzftab.zsh' id-as'fzf-tab' \
        @Aloxaf/fzf-tab


## 9: prompt theme

# using starship for the consistent prompt across shells
eval "$(starship init zsh)"
if [ ! -f "$ZINIT[COMPLETIONS_DIR]/_starship" ]; then
    starship completions zsh > "$ZINIT[COMPLETIONS_DIR]/_starship"
fi


## 10: post-startup actions

# source all system-provided completions
if [[ -d "/usr/share/zsh/site-functions" ]]; then
    for FILE in "/usr/share/zsh/site-functions/*"; do
        if [[ -f "$FILE" ]]; then
            zinit wait'1' lucid as'completion' blockf "$FILE"
	fi
    done
fi

# add plugin-related manpages into the MANPATH
export MANPATH=":$ZPFX/share/man"

# compinit + cdreplay
autoload -Uz compinit
COMPINIT_INTERVAL=3600
if [ $( date +'%s' ) -gt $(( $( stat -c '%Y' $ZINIT[ZCOMPDUMP_PATH] ) + $COMPINIT_INTERVAL )) ]; then
    ZINIT[COMPINIT_OPTS]=-C
fi
compinit -d ${ZINIT[ZCOMPDUMP_PATH]:-${ZDOTDIR:-$HOME}/.zcompdump} "${(Q@)${(z@)ZINIT[COMPINIT_OPTS]}}"
zinit cdreplay
