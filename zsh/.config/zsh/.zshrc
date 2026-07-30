#!/usr/bin/env zsh

#          _
#  ___ ___| |_
# |- _|_ -|   |
# |___|___|_|_|

## 0: make sure this is an interactive shell before setting up interactive shell preferences

[[ $- != *i* ]] && return


## 1: setup profiling via zprof

if [ -n "${ZSH_PROFILE_STARTUP:+x}" ]; then
    zmodload zsh/zprof
    echo "Zsh profiling enabled. Run: ZSH_PROFILE_STARTUP=1 zsh -i -c exit"
fi


## 2: make sure options are reset

emulate zsh


## 3: load shell options

source "$ZDOTDIR/include/options.zsh"


## 4: setup required directories and paths

# xdg base directory specification
typeset -gx XDG_DATA_HOME=${XDG_DATA_HOME:-"$HOME/.local/share"}
typeset -gx XDG_STATE_HOME=${XDG_STATE_HOME:-"$HOME/.local/state"}
typeset -gx XDG_CACHE_HOME=${XDG_CACHE_HOME:-"$HOME/.cache"}
typeset -gx XDG_CONFIG_HOME=${XDG_CONFIG_HOME:-"$HOME/.config"}

# source xdg user dirs if present
[[ -f "$XDG_CONFIG_HOME/user-dirs.dirs" ]] && {
    source "$XDG_CONFIG_HOME/user-dirs.dirs"
}

# setup zsh cache directory and completion cache path
ZSH_CACHE_DIR="${XDG_CACHE_HOME}/zsh"
[[ ! -d "$ZSH_CACHE_DIR" ]] && mkdir -p "$ZSH_CACHE_DIR"

# enable completion caching for better performance
zstyle ':completion:*' use-cache yes
zstyle ':completion:*' cache-path "${ZSH_CACHE_DIR}/zcompcache"


## 5: initialize generic lazy loading

ZSH_DEFER_DIR="${XDG_DATA_HOME}/zsh-defer"
[[ ! -d "$ZSH_DEFER_DIR" ]] && {
    git clone --quiet --depth=1 https://github.com/romkatv/zsh-defer.git "$ZSH_DEFER_DIR" 2>/dev/null || {
        print -P "%F{red}Failed to clone zsh-defer%f"
        return 1
    }
}
fpath+=("$ZSH_DEFER_DIR")
autoload -Uz zsh-defer


## 6: set prompt theme

# using starship for the consistent prompt across shells
# we use an intermediate prompt to mitigate the startup lag of starship
export PROMPT='
%B%F{magenta}%1~%f%b
%F{cyan}󰚭%f %F{green}❯%f'
export RPROMPT=''
zsh-defer -a +pr source "$ZDOTDIR/include/starship.zsh"


## 7: define user functions

source "$ZDOTDIR/include/functions.zsh"


## 8: define keybindings

source "$ZDOTDIR/include/keybindings.zsh"


## 9: early initialization - load site functions, profile, and aliases

function load_site_functions() {
    local site_funcs=(/usr/share/zsh/site-functions/^_*(.N:A))
    (( $#site_funcs )) && source $^site_funcs
    unset site_funcs
}

function load_profile() {
    [[ -f "$HOME/.profile" ]] && source "$HOME/.profile"
}

function load_user_aliases() {
    [[ -f "${XDG_CONFIG_HOME}/shell/aliases" ]] && source "${XDG_CONFIG_HOME}/shell/aliases"
}

function _early_init() {
    load_site_functions
    load_profile
    load_user_aliases
    source "$ZDOTDIR/include/completion.zsh"
}
zsh-defer -a _early_init


## 10: miscellaneous settings

# deduplicate PATH
typeset -gU PATH path

# word characters for shell operations
typeset -g WORDCHARS='*?[]~=&;!#$%^(){}'


## 11: setup plugin manager

ZCOMET_HOME="$XDG_DATA_HOME/zsh/zcomet"
ZCOMET_SCRIPT="$ZCOMET_HOME/bin/zcomet.zsh"
zstyle ':zcomet:*' home-dir "$ZCOMET_HOME"
zstyle ':zcomet:compinit' dump-file "$XDG_CACHE_HOME/zcompdump"
zstyle ':*:compinit' arguments $([[ ${XDG_CACHE_HOME}/zcompdump(#qNmh-24) ]] && echo -C || echo -i)

[[ ! -f "$ZCOMET_SCRIPT" ]] && {
    git clone --quiet --depth=1 https://github.com/agkozak/zcomet.git "$ZCOMET_HOME/bin" 2>/dev/null || {
        print -P "%F{red}Failed to clone zcomet%f"
        return 1
    }
}
source "$ZCOMET_SCRIPT"

# Initialize ZCOMET array for internal function access
if [[ -z ${ZCOMET[REPOS_DIR]} ]]; then
    local zcomet_home_dir
    zstyle -s :zcomet: home-dir zcomet_home_dir
    : ${zcomet_home_dir:=$ZCOMET_HOME}
    local zcomet_repos_dir
    zstyle -s :zcomet: repos-dir zcomet_repos_dir
    : ${ZCOMET[REPOS_DIR]:=${zcomet_repos_dir:-${zcomet_home_dir}/repos}}
    local zcomet_git_server
    zstyle -s :zcomet: gitserver zcomet_git_server
    : ${ZCOMET[GITSERVER]:=${zcomet_git_server:-github.com}}
fi

function load_plugins() {
    setopt extendedglob
    local mode=${1:?"Mode (lazy/eager) required"}
    shift
    local plugin plugin_name hook_script
    local -a plugins=("$@")

    for plugin in "${plugins[@]}"; do
        plugin_name=${${plugin##*/}%@*}
        hook_script="$ZDOTDIR/plughook/${plugin_name}.zsh"
        if [[ ! -d $ZCOMET_HOME/repos/${plugin%%@*} ]]; then
            _zcomet_clone_repo $plugin
            if [[ -f $hook_script ]]; then
                source $hook_script
                (( $+functions[atclone] )) && atclone
                unfunction atclone 2>/dev/null
            fi
        fi
    done

    if [[ $mode == lazy ]]; then
        zsh-defer -a _deferred_plugin_load "$mode" "${plugins[@]}"
    else
        _deferred_plugin_load "$mode" "${plugins[@]}"
    fi
}

function _deferred_plugin_load() {
    local mode=$1; shift
    local plugin plugin_name hook_script
    for plugin in "$@"; do
        plugin_name=${${plugin##*/}%@*}
        hook_script="$ZDOTDIR/plughook/${plugin_name}.zsh"
        if [[ -f $hook_script ]]; then
            source $hook_script
            (( $+functions[atinit] )) && atinit
            zcomet load $plugin
            (( $+functions[atload] )) && atload
            unfunction atclone atinit atload 2>/dev/null
        else
            zcomet load $plugin
        fi
    done
}

function update_plugins() {
    zcomet self-update
    zcomet update
    rm -f "$XDG_CACHE_HOME/zcompdump"
    zcomet compinit
}


## 12: load plugins via batching - pre-compinit stage

load_plugins lazy \
    QuarticCat/zsh-smartcache \
    tinted-theming/tinted-shell \
    agkozak/zsh-z \
    mollifier/cd-gitroot \
    jocelynmallon/zshmarks \
    wfxr/forgit \
    viko16/gitcd.plugin.zsh \
    unixorn/git-extra-commands \
    tj/git-extras \
    k4rthik/git-cal \
    paulirish/git-open \
    paulirish/git-recent \
    davidosomething/git-my \
    mdumitru/fancy-ctrl-z \
    garabik/grc \
    Freed-Wu/zsh-help \
    hlissner/zsh-autopair \
    hchbaw/zce.zsh \
    MichaelAquilina/zsh-you-should-use \
    momo-lab/zsh-abbrev-alias \
    trystan2k/zsh-tab-title \
    kevinywlui/zlong_alert.zsh \
    zsh-users/zsh-completions \
    MenkeTechnologies/zsh-more-completions \
    RobSis/zsh-completion-generator


## 13: configure shell history

# set history file eagerly to prevent commands being written to the wrong
# location before the deferred chain runs. overridden by history.zsh if atuin
# is present.
export HISTFILE="$XDG_CACHE_HOME/shell_history"
export HISTSIZE=50000
export SAVEHIST=50000
zsh-defer -a source "$ZDOTDIR/include/history.zsh"


## 14: trigger-based loading for commands (load only on first command invocation) + compinit

function _post_plugin_setup() {
    zcomet snippet "https://github.com/ohmyzsh/ohmyzsh/blob/master/plugins/sudo/sudo.plugin.zsh"
    zcomet trigger bd Tarrasch/zsh-bd
    zcomet trigger pip ohmyzsh plugins/pip
    zcomet trigger git ohmyzsh plugins/gitfast
    source "$ZDOTDIR/include/widgets.zsh"
    zcomet compinit
    # enable command hashing after first prompt so runtime command lookup is fast
    # without paying the ~17ms PATH-scan cost during synchronous startup
    setopt HASH_CMDS
}
zsh-defer -a _post_plugin_setup


## 15: load plugins via batching - post-compinit stage

# these plugins require compinit to have run and/or depend on each other's
# load order. they are queued after _post_plugin_setup via zsh-defer -a and
# execute in FIFO order: fzf -> fzf-tab -> fzf-tab-source -> autosuggestions -> fsyth -> hss
load_plugins lazy \
    junegunn/fzf \
    Aloxaf/fzf-tab \
    Freed-Wu/fzf-tab-source \
    zsh-users/zsh-autosuggestions \
    zdharma-continuum/fast-syntax-highlighting \
    zsh-users/zsh-history-substring-search


## 16: cleanup internal functions (after deferred tasks complete)

zsh-defer -ac 'unfunction _deferred_plugin_load _early_init _post_plugin_setup load_site_functions load_profile load_user_aliases 2>/dev/null'


## 17: show profiling report (if profiling variable is set)

if [ -n "${ZSH_PROFILE_STARTUP:+x}" ]; then
    zprof
fi
