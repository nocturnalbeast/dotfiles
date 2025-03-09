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
    # zcompile the zshrc
    [[ -f "${ZDOTDIR}/.zshrc" ]] && zcompare "${ZDOTDIR}/.zshrc"

    # zcompile files in the include directory
    if [[ -d "${ZDOTDIR}/include" ]]; then
        local file
        for file in "${ZDOTDIR}/include"/*.zsh(N); do
            zcompare "$file"
        done
    fi

    # zcompile the completion cache
    if [[ -d "$HOME/.cache/zsh/zcompcache" ]]; then
        local file
        for file in "$HOME/.cache/zsh/zcompcache"/*(.N); do
            [[ "$file" != *.zwc ]] && zcompare "$file"
        done
    fi
} &!
