#!/usr/bin/env sh

# A dotfiles package installer script.

# Global configuration
IGNORE_DIRS="repo_resources"

usage() {
    cat << EOF
Usage: $(basename "$0") [OPTIONS] [PACKAGES...]

Install dotfiles using GNU stow.
If no packages are specified, all packages will be installed.

Options:
    -h, --help      Show this help message and exit
    -r, --reinstall Reinstall (restow) packages even if they are already installed
    -u, --uninstall Uninstall (remove) packages instead of installing them

Arguments:
    PACKAGES    Space-separated list of packages to install

Example:
    $(basename "$0")           # Install all packages
    $(basename "$0") nvim zsh  # Install only nvim and zsh packages
    $(basename "$0") -r        # Reinstall all packages
    $(basename "$0") -u nvim   # Uninstall nvim package
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

# Manage a package using stow (install, reinstall, or uninstall)
#
# Arguments:
#   $1 - Package name
#   $2 - Action: "install", "reinstall", or "uninstall"
stow_package() {
    if ! contains "$1" "$IGNORE_DIRS"; then
        case "$2" in
            "reinstall")
                if stow --override='.*' -Rt "$HOME" "$1" > /dev/null 2>&1; then
                    echo "Reinstalled $1"
                else
                    echo "ERROR: Failed to reinstall package $1" >&2
                    return 1
                fi
                ;;
            "uninstall")
                if stow -Dt "$HOME" "$1" > /dev/null 2>&1; then
                    echo "Uninstalled $1"
                else
                    echo "ERROR: Failed to uninstall package $1" >&2
                    return 1
                fi
                ;;
            "install")
                if stow -t "$HOME" "$1" > /dev/null 2>&1; then
                    echo "Installed $1"
                else
                    echo "ERROR: Failed to install package $1" >&2
                    return 1
                fi
                ;;
            *)
                echo "ERROR: Invalid action '$2' for package $1" >&2
                return 1
                ;;
        esac
    fi
}

# Main entry point that processes command-line arguments.
#
# Arguments:
#   $@ - Optional list of packages to install (if not provided, all packages will be installed)
main() {
    action="install"
    while [ $# -gt 0 ]; do
        case "$1" in
            -h | --help)
                usage
                exit 0
                ;;
            -r | --reinstall)
                action="reinstall"
                shift
                ;;
            -u | --uninstall)
                action="uninstall"
                shift
                ;;
            *)
                break
                ;;
        esac
    done

    if [ $# -eq 0 ]; then
        # Process all packages
        for pkg in $(find . -maxdepth 1 -mindepth 1 -type d -not -name '.*' | cut -f 2 -d '/'); do
            stow_package "$pkg" "$action"
        done
    else
        # Process specified packages
        for pkg in "$@"; do
            if [ -d "$pkg" ]; then
                stow_package "$pkg" "$action"
            else
                echo "ERROR: Package $pkg not found" >&2
            fi
        done
    fi
}

main "$@"
