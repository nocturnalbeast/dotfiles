#!/usr/bin/env zsh

# Function to determine the need of a zcompile. If the .zwc file
# does not exist, or the base file is newer, we need to compile.
# These jobs are asynchronous, and will not impact the interactive shell
function zcompare() {
    local file=$1
    if [[ -f "$file" && ( ! -f "$file.zwc" || "$file" -nt "$file.zwc" ) ]]; then
        zcompile "$file"
    fi
}

# Run compilation in background
{
    # recursively zcompile all zsh files in ZDOTDIR
    local file
    for file in "${ZDOTDIR}"/**/*(.N); do
        case "$file" in
            *.zsh|*.zshrc|*.zshenv|*.zprofile|*.zlogin|*.zlogout)
                [[ "$file" != *.zwc ]] && zcompare "$file"
                ;;
        esac
    done

    # zcompile the completion cache
    if [[ -d "${XDG_CACHE_HOME:-$HOME/.cache}/zsh/zcompcache" ]]; then
        for file in "${XDG_CACHE_HOME:-$HOME/.cache}/zsh/zcompcache"/*(.N); do
            [[ "$file" != *.zwc ]] && zcompare "$file"
        done
    fi
} &!
