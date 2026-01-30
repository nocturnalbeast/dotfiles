#!/usr/bin/env zsh

#          _
#  ___ ___| |_
# |- _|_ -|   |
# |___|___|_|_|

## 0: make sure this is an interactive shell before setting up interactive shell preferences

[[ $- != *i* ]] && return


## 1: initialize profiling if enabled

source "$ZDOTDIR/include/profile.zsh"
[[ -n "$ZSH_PROFILE" ]] && zprofile_init


## 2: make sure options are reset

emulate -L zsh


## 3: load shell options

zprofile_start "shell_options"
source "$ZDOTDIR/include/options.zsh"
zprofile_end "shell_options"


## 4: setup required directories and paths

zprofile_start "directory_setup"
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
zprofile_end "directory_setup"


## 5: set prompt theme

# using starship for the consistent prompt across shells
zprofile_start "starship_prompt"
source "$ZDOTDIR/include/starship.zsh"
zprofile_end "starship_prompt"


## 6: initialize generic lazy loading

zprofile_start "zsh_defer_setup"
ZSH_DEFER_DIR="${XDG_DATA_HOME}/zsh-defer"
[[ ! -d "$ZSH_DEFER_DIR" ]] && {
    git clone --quiet --depth=1 https://github.com/romkatv/zsh-defer.git "$ZSH_DEFER_DIR" 2>/dev/null || {
        print -P "%F{red}Failed to clone zsh-defer%f"
        return 1
    }
}
fpath+=("$ZSH_DEFER_DIR")
autoload -Uz zsh-defer
zprofile_end "zsh_defer_setup"


## 7: define keybindings

zprofile_start "keybindings.zsh"
source "$ZDOTDIR/include/keybindings.zsh"
zprofile_end "keybindings.zsh"


## 8: load functions

zprofile_start "functions.zsh"
source "$ZDOTDIR/include/functions.zsh"
zprofile_end "functions.zsh"

# load site functions if directory exists
function load_site_functions() {
    local site_funcs=(/usr/share/zsh/site-functions/*(.N:A))
    (( $#site_funcs )) && source $^site_funcs
    unset site_funcs
}
zsh-defer -dmszpr load_site_functions


## 9: setup environment variables

# source profile if it exists
function load_profile() {
    [[ -f "$HOME/.profile" ]] && source "$HOME/.profile"
}
zsh-defer -a load_profile

# source user aliases if it exists
function load_user_aliases() {
    [[ -f "${XDG_CONFIG_HOME}/shell/aliases" ]] && source "${XDG_CONFIG_HOME}/shell/aliases"
}
zsh-defer -a load_user_aliases


## 10: define completion behavior

zprofile_start "completion_defer_schedule"
zsh-defer -a source "$ZDOTDIR/include/completion.zsh"
zprofile_end "completion_defer_schedule"


## 11: miscellaneous settings

# deduplicate PATH
typeset -gU PATH path

# word characters for shell operations
typeset -g WORDCHARS='*?[]~=&;!#$%^(){}'


## 12: setup plugin manager

ZCOMET_HOME="$XDG_DATA_HOME/zsh/zcomet"
ZCOMET_SCRIPT="$ZCOMET_HOME/bin/zcomet.zsh"
zstyle ':zcomet:*' home-dir "$ZCOMET_HOME"
zstyle ':zcomet:compinit' dump-file "$XDG_CACHE_HOME/zcompdump"
zstyle ':*:compinit' arguments $([[ $ZCOMPDUMP_PATH(#qNmh-24) ]] && echo -C || echo -i)

[[ ! -f "$ZCOMET_SCRIPT" ]] && {
    git clone --quiet --depth=1 https://github.com/agkozak/zcomet.git "$ZCOMET_HOME/bin" 2>/dev/null || {
        print -P "%F{red}Failed to clone zcomet%f"
        return 1
    }
}
zprofile_start "zcomet_init"
source "$ZCOMET_SCRIPT"
zprofile_end "zcomet_init"

function load_plugin() {
    setopt extendedglob

    local mode=${1:?"Mode (lazy/eager) required"}
    local plugin=${2:?"Plugin name required"}
    local hook_script="$ZDOTDIR/plughook/${${plugin##*/}%@*}.zsh"
    local plugin_name=${${plugin##*/}%@*}
    shift 2

    zprofile_load_plugin "$mode" "$plugin"

    if [[ ! -d $ZCOMET_HOME/repos/${plugin%%@*} ]]; then
        source $hook_script
        atinit
        zcomet load $plugin $@
        atload
        zprofile_plugin_loaded "$mode" "$plugin"
    elif [[ $mode == lazy ]]; then
        local func_name="_deferred_load_${plugin_name//-/_}"
        eval "function $func_name() {
            source $hook_script
            atinit
            zcomet load $plugin $@
            atload
            zprofile_plugin_loaded '$mode' '$plugin'
            unfunction $func_name 2>/dev/null
        }"
        zsh-defer -12dmspzpr $func_name
    else
        source $hook_script
        atinit
        zcomet load $plugin $@
        atload
        zprofile_plugin_loaded "$mode" "$plugin"
    fi

    unfunction atclone atinit atload 2>/dev/null
}

function load_snippet() {
    local mode=${1:?"Mode (lazy/eager) required"}
    local url=${2:?"URL required"}

    if [[ $mode == "lazy" ]]; then
        zsh-defer -a zcomet snippet "$url"
    else
        zcomet snippet "$url"
    fi
}

function update_plugins() {
    zcomet self-update
    zcomet update
    rm -f "$XDG_CACHE_HOME/zcompdump"
    zcomet compinit
}


## 13: load plugins

# faster cache for binaries that generate initalization scripts which are normally passed into eval()
load_plugin lazy mroth/evalcache

# shell colors
load_plugin lazy tinted-theming/tinted-shell

# smarter cd
# TODO: setup ranked completion for zsh-z
load_plugin lazy agkozak/zsh-z
load_plugin lazy Tarrasch/zsh-bd
load_plugin lazy mollifier/cd-gitroot
load_plugin lazy jocelynmallon/zshmarks

# enhance git
load_plugin lazy wfxr/forgit
load_plugin lazy viko16/gitcd.plugin.zsh
load_plugin lazy unixorn/git-extra-commands
load_plugin lazy tj/git-extras
load_plugin lazy k4rthik/git-cal
load_plugin lazy paulirish/git-open
load_plugin lazy paulirish/git-recent
load_plugin lazy davidosomething/git-my

# fzf integration
load_plugin lazy junegunn/fzf shell completion.zsh
load_plugin lazy Aloxaf/fzf-tab
load_plugin lazy Freed-Wu/fzf-tab-source

# ctrl+z to resume
load_plugin lazy mdumitru/fancy-ctrl-z

# colorize command output
load_plugin lazy garabik/grc

# pair brackets and quotations
load_plugin lazy hlissner/zsh-autopair

# remind you of your aliases
load_plugin lazy MichaelAquilina/zsh-you-should-use

# alias expansion
load_plugin lazy momo-lab/zsh-abbrev-alias

# let the shell set the terminal window name
load_plugin lazy trystan2k/zsh-tab-title

# have notifications for long-running commands
load_plugin lazy kevinywlui/zlong_alert.zsh

# syntax highlighting
load_plugin lazy zdharma-continuum/fast-syntax-highlighting

# history-substring search
load_plugin lazy zsh-users/zsh-history-substring-search

# autosuggestions
load_plugin lazy zsh-users/zsh-autosuggestions

# completions
load_plugin lazy zsh-users/zsh-completions
load_plugin lazy MenkeTechnologies/zsh-more-completions
load_plugin lazy RobSis/zsh-completion-generator

# sudo helper
load_snippet lazy https://github.com/ohmyzsh/ohmyzsh/blob/master/plugins/sudo/sudo.plugin.zsh


## 14: configure command history

zprofile_start "history_defer_schedule"
zsh-defer -a source "$ZDOTDIR/include/history.zsh"
zprofile_end "history_defer_schedule"


## 15: helpers and completions for certain commands using zcomet

zsh-defer +sz zcomet trigger pip ohmyzsh plugins/pip
zsh-defer +sz zcomet trigger git ohmyzsh plugins/gitfast


## 16: post-setup tasks

zprofile_start "widgets_defer_schedule"
zsh-defer -a source "$ZDOTDIR/include/widgets.zsh"
zprofile_end "widgets_defer_schedule"

zprofile_start "compinit"
zcomet compinit
zprofile_end "compinit"

if (( _ZSH_PROFILE_ENABLED && _ZSH_PROFILE_PLUGINS_ENABLED )); then
    # Force all deferred plugins to load for profiling
    while (( $#_zsh_defer_tasks )); do
        local task=${_zsh_defer_tasks[1]}
        shift _zsh_defer_tasks
        _zsh-defer-apply $task 2>/dev/null
    done
fi
zprofile_report
