#!/usr/bin/env bash

IGNORE_DIRS=( "repo_resources" )

mapfile -t PACKAGES < <( find . -maxdepth 1 -mindepth 1 -type d -not -name '.*' | cut -f 2 -d '/' )
for PACKAGE in "${PACKAGES[@]}"; do
    if [[ ! " ${IGNORE_DIRS[@]} " =~ " ${PACKAGE} " ]]; then
        stow -t "${HOME}" "${PACKAGE}" >/dev/null 2>&1 
        if [[ "$?" -ne "0" ]]; then
            echo "ERROR: Failed to install package ${PACKAGE}."
        else
            echo "Installed ${PACKAGE}."
        fi
    fi
done
