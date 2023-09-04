#!/usr/bin/env zsh

#          _
#  ___ ___| |_
# |- _|_ -|   |
# |___|___|_|_|


# compile zcompdump into bytecode on interactive shells
{
    if [[ -s "$ZINIT[ZCOMPDUMP_PATH]" && (! -s "${ZINIT[ZCOMPDUMP_PATH]}.zwc" || "$ZINIT[ZCOMPDUMP_PATH]" -nt "${ZINIT[ZCOMPDUMP_PATH]}.zwc") ]]; then
        if command mkdir "${ZINIT[ZCOMPDUMP_PATH]}.zwc.lock" 2>/dev/null; then
            zcompile "$ZINIT[ZCOMPDUMP_PATH]"
            command rmdir  "${ZINIT[ZCOMPDUMP_PATH]}.zwc.lock" 2>/dev/null
        fi
    fi
} &!
