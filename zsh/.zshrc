#!/bin/zsh

# install zplugin if not installed
if [ ! -d "${HOME}/.zplugin" ]; then 
    sh -c "$(curl -fsSL https://raw.githubusercontent.com/zdharma/zplugin/master/doc/install.sh)"
fi

# zplugin init
source '/home/betrant/.zplugin/bin/zplugin.zsh'
autoload -Uz _zplugin
(( ${+_comps} )) && _comps[zplugin]=_zplugin

# helpful exports and aliases
export EDITOR="kak"
alias ls="exa -bh --color=auto"
alias cat="pygmentize -O style=native -g"

# all the plugins

# completions
zplugin ice wait blockf atpull'zplugin creinstall -q .'
zplugin light zsh-users/zsh-completions

# syntax highlighting
zplugin light zdharma/fast-syntax-highlighting

# autosuggestions
zplugin ice wait atload"_zsh_autosuggest_start"
zplugin light zsh-users/zsh-autosuggestions

# history substring searching
zplugin ice wait'2' lucid from"gh" as"program" pick"init.zsh"
zplugin light zsh-users/zsh-history-substring-search

# better cd command with fuzzy matching
zplugin ice wait"0b" lucid 
zplugin light b4b4r07/enhancd 
export ENHANCD_FILTER=fzy
export ENHANCD_DISABLE_HOME=1
export ENHANCD_DISABLE_DOT=1

# time for some rainbows
zplugin ice pick"c.zsh" atclone"dircolors -b LS_COLORS > c.zsh" atpull'%atclone' 
zplugin light trapd00r/LS_COLORS

zplugin light unixorn/warhol.plugin.zsh

zplugin light ael-code/zsh-colored-man-pages

# supercharge git
zplugin ice wait"2" lucid as"program" pick"bin/git-dsf"
zplugin light zdharma/zsh-diff-so-fancy

zplugin ice wait"2" lucid as"program" pick"$ZPFX/bin/git-now" make"prefix=$ZPFX install"
zplugin light iwata/git-now

zplugin ice wait"2" lucid as"program" pick"$ZPFX/bin/git-alias" make"PREFIX=$ZPFX" nocompile
zplugin light tj/git-extras

zplugin ice wait"2" lucid as"program" atclone'perl Makefile.PL PREFIX=$ZPFX' atpull'%atclone' \
            make'install' pick"$ZPFX/bin/git-cal"
            zplugin light k4rthik/git-cal

# correcting wrong commands
zplugin ice wait'1' lucid
zplugin light laggardkernel/zsh-thefuck
eval $(thefuck --alias wtf)

# docker completions
zplugin ice as"completion"
zplugin snippet https://github.com/docker/cli/blob/master/contrib/completion/zsh/_docker

# theme - powerlevel10k with lean mode
zplugin light romkatv/powerlevel10k
[[ -f ~/.p10k.zsh ]] && source ~/.p10k.zsh
