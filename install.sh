#!/usr/bin/env sh

# A dotfiles package installer script.

# Global configuration
IGNORE_DIRS="repo_resources"

usage() {
    cat << EOF
Usage: $(basename "$0") [PACKAGES...]

Install dotfiles using GNU stow.
If no packages are specified, all packages will be installed.

Arguments:
    PACKAGES    Space-separated list of packages to install

Example:
    $(basename "$0")           # Install all packages
    $(basename "$0") nvim zsh  # Install only nvim and zsh packages
EOF
}

# Check if a value exists in a space-separated string
#
# Arguments:
#   $1 - Value to search for
#   $2 - String to search in
#
# Returns:
#   0 if value exists, 1 otherwise
contains() {
    case " $2 " in
        *" $1 "*) return 0 ;;
        *) return 1 ;;
    esac
}

# Install a single package using stow
#
# Arguments:
#   $1 - Package name
install_package() {
    if ! contains "$1" "$IGNORE_DIRS"; then
        if stow -t "$HOME" "$1" > /dev/null 2>&1; then
            echo "Installed $1"
        else
            echo "ERROR: Failed to install package $1" >&2
            return 1
        fi
    fi
}

# Main entry point that processes command-line arguments.
#
# Arguments:
#   $@ - Optional list of packages to install (if not provided, all packages will be installed)
main() {
    case "$1" in
        -h | --help)
            usage
            exit 0
            ;;
    esac

    if [ $# -eq 0 ]; then
        # Install all packages
        for pkg in $(find . -maxdepth 1 -mindepth 1 -type d -not -name '.*' | cut -f 2 -d '/'); do
            install_package "$pkg"
        done
    else
        # Install specified packages
        for pkg in "$@"; do
            if [ -d "$pkg" ]; then
                install_package "$pkg"
            else
                echo "ERROR: Package $pkg not found" >&2
            fi
        done
    fi
}

main "$@"
