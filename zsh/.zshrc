#!/bin/zsh

# install zinit if not installed
if [ ! -d "${HOME}/.zinit" ]; then 
    sh -c "$(curl -fsSL https://raw.githubusercontent.com/zdharma/zinit/master/doc/install.sh)"
fi

# added by zinit's installer
if [[ ! -f $HOME/.zinit/bin/zinit.zsh ]]; then
    print -P "%F{33}▓▒░ %F{220}Installing DHARMA Initiative Plugin Manager (zdharma/zinit)…%f"
    command mkdir -p "$HOME/.zinit" && command chmod g-rwX "$HOME/.zinit"
    command git clone https://github.com/zdharma/zinit "$HOME/.zinit/bin" && \
        print -P "%F{33}▓▒░ %F{34}Installation successful.%f%b" || \
        print -P "%F{160}▓▒░ The clone has failed.%f%b"
fi

# zinit start
source "$HOME/.zinit/bin/zinit.zsh"
autoload -Uz _zinit
(( ${+_comps} )) && _comps[zinit]=_zinit

# plugins for zinit
zinit light-mode for \
    zinit-zsh/z-a-patch-dl \
    zinit-zsh/z-a-as-monitor \
    zinit-zsh/z-a-bin-gem-node

# setting up history file
[ -z "$HISTFILE" ] && HISTFILE="$HOME/.cache/shell_history"
HISTSIZE=50000
SAVEHIST=10000

# helpful exports and aliases
export EDITOR="nvim"
export BROWSER="qutebrowser"

export XDG_DATA_HOME="$HOME/.local/share"
export XDG_CONFIG_HOME="$HOME/.config"
export XDG_CACHE_HOME="$HOME/.cache"

export GTK2_RC_FILES="$XDG_CONFIG_HOME/gtk-2.0/gtkrc"
export LESSHSTFILE=-

alias ls="exa -bh --color=auto --icons"
alias ll="exa -bhl --color=auto --icons"
alias la="exa -bha --color=auto --icons"
alias lt="exa -bh --tree --color=auto --icons"
alias lal="exa -bhal --color=auto --icons"
alias cat="bat"
alias vim="nvim"
alias vi="nvim"

alias l="exa -bh --color=auto --icons"
alias v="nvim"
alias g="gotop"
alias c="bat"

# fix keybindings (note that plugins can override these)
if (( ${+terminfo[smkx]} )) && (( ${+terminfo[rmkx]} )); then
    function zle-line-init () { echoti smkx }
    function zle-line-finish () { echoti rmkx }
    zle -N zle-line-init
    zle -N zle-line-finish
fi

typeset -g -A key

key[Home]="$terminfo[khome]"
key[End]="$terminfo[kend]"
key[Insert]="$terminfo[kich1]"
key[Backspace]="$terminfo[kbs]"
key[Delete]="$terminfo[kdch1]"
key[Up]="$terminfo[kcuu1]"
key[Down]="$terminfo[kcud1]"
key[Left]="$terminfo[kcub1]"
key[Right]="$terminfo[kcuf1]"
key[PageUp]="$terminfo[kpp]"
key[PageDown]="$terminfo[knp]"

[[ -n "$key[Home]" ]] && bindkey - "$key[Home]" beginning-of-line
[[ -n "$key[End]" ]] && bindkey - "$key[End]" end-of-line
[[ -n "$key[Insert]" ]] && bindkey - "$key[Insert]" overwrite-mode
[[ -n "$key[Backspace]" ]] && bindkey - "$key[Backspace]" backward-delete-char
[[ -n "$key[Delete]" ]] && bindkey - "$key[Delete]" delete-char
[[ -n "$key[Up]" ]] && bindkey - "$key[Up]" up-line-or-history
[[ -n "$key[Down]" ]] && bindkey - "$key[Down]" down-line-or-history
[[ -n "$key[Left]" ]] && bindkey - "$key[Left]" backward-char
[[ -n "$key[Right]" ]] && bindkey - "$key[Right]" forward-char

# user plugins
zinit wait lucid for \
    atinit"ZINIT[COMPINIT_OPTS]=-C; zicompinit; zicdreplay" \
        zdharma/fast-syntax-highlighting \
    blockf \
	zsh-users/zsh-completions \
    atload"!_zsh_autosuggest_start" \
        zsh-users/zsh-autosuggestions

export ZSH_AUTOSUGGEST_STRATEGY=( history match_prev_cmd completion )
export ZSH_AUTOSUGGEST_USE_ASYNC=1

zinit ice nocompile:! pick:c.zsh atpull:%atclone atclone:'dircolors -b LS_COLORS > c.zsh'
zinit light trapd00r/LS_COLORS

zinit light unixorn/warhol.plugin.zsh

zinit light ael-code/zsh-colored-man-pages

zinit ice atclone'./init.sh' nocompile'!' wait'!0'
zinit light b4b4r07/enhancd
export ENHANCD_DIR="$HOME/.cache/.enhancd"

zinit ice wait"1" lucid
zinit light laggardkernel/zsh-thefuck

zinit wait"1" lucid as"program" pick"$ZPFX/bin/fzy*" \
    atclone"cp contrib/fzy-* $ZPFX/bin/" \
    make"!PREFIX=$ZPFX install" for \
    	jhawthorn/fzy

zinit ice wait"1" lucid compile'{hsmw-*,test/*}'
zinit light zdharma/history-search-multi-word

zinit wait"2" lucid as"null" from"gh-r" for \
    mv"exa* -> exa" sbin  ogham/exa \
    mv"fd* -> fd" sbin"fd/fd"  @sharkdp/fd \
    sbin junegunn/fzf-bin

zinit wait"2" lucid for \
    atinit"forgit_ignore='fgi'" \
    	wfxr/forgit

zinit wait"2" lucid as"null" \
    atclone'perl Makefile.PL PREFIX=$ZPFX' \
    atpull'%atclone' make sbin"git-cal" for \
        k4rthik/git-cal

zinit as"null" wait"3" lucid for \
    sbin Fakerr/git-recall \
    sbin paulirish/git-open \
    sbin paulirish/git-recent \
    sbin davidosomething/git-my \
    sbin atload"export _MENU_THEME=legacy" \
    	arzzen/git-quick-stats \
    sbin iwata/git-now \
    make"PREFIX=$ZPFX" tj/git-extras \
    sbin"bin/git-dsf;bin/diff-so-fancy" zdharma/zsh-diff-so-fancy \
    sbin"git-url;git-guclone" make"GITURL_NO_CGITURL=1" zdharma/git-url

# prompt theme
zinit ice depth=1 atload'!source ~/.p10k.zsh' lucid nocd
zinit light romkatv/powerlevel10k
