#!/usr/bin/env sh

# A dotfiles package installer script.

# Global configuration
IGNORE_DIRS="repo_resources bootstrap"

usage() {
    cat << EOF
Usage: $(basename "$0") ACTION [PACKAGES...]

Manage dotfiles using GNU stow.
If no packages are specified, all packages will be installed.

Arguments:
    ACTION       Action to perform: install, reinstall, or uninstall (required)
    PACKAGES     Space-separated list of packages to manage (optional)

Options:
    -h, --help   Show this help message

Example:
    $(basename "$0") install        # Install all packages
    $(basename "$0") install tmux   # Install only tmux package
    $(basename "$0") reinstall zsh  # Reinstall zsh package
    $(basename "$0") uninstall gtk  # Uninstall gtk package
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

# Run a package-specific bootstrap script
#
# Arguments:
#   $1 - Package name
#   $2 - Action: "install" or "uninstall"
run_bootstrap() {
    pkg="$1"
    action="$2"
    bootstrap_script="bootstrap/$pkg"

    if [ -x "$bootstrap_script" ]; then
        echo "INFO: Running bootstrap script for $pkg..."
        if ! "./$bootstrap_script" "$action"; then
            echo "ERROR: Bootstrap script for $pkg failed"
        fi
    fi
}

# Check if a stow package is already installed by checking if any of its files are symlinked
#
# Arguments:
#   $1 - Package name
#   $2 - Target directory
#
# Returns:
#   0 if package is stowed, 1 otherwise
is_stowed() {
    pkg="$1"
    target="$2"
    output="$(stow -n -v -t "$target" "$pkg" 2>&1)"
    if echo "$output" | grep -q "would cause conflicts\|^LINK:"; then
        return 1
    fi
    if [ -z "$output" ] || echo "$output" | grep -q "^WARNING: in simulation mode"; then
        return 0
    fi
    return 1
}

# Manage a package using stow (install, reinstall, or uninstall)
#
# Arguments:
#   $1 - Package name
#   $2 - Action: "install", "reinstall", or "uninstall"
#   $3 - Target directory
stow_package() {
    if ! contains "$1" "$IGNORE_DIRS"; then
        case "$2" in
            "reinstall")
                if stow --override='.*' -Rt "$3" "$1" > /dev/null 2>&1; then
                    echo "INFO: Reinstalled $1"
                else
                    echo "ERROR: Failed to reinstall package $1" >&2
                    return 1
                fi
                ;;
            "uninstall")
                if ! is_stowed "$1" "$3"; then
                    echo "ERROR: Package $1 is not installed"
                    return 1
                fi
                if stow -Dt "$3" "$1" > /dev/null 2>&1; then
                    echo "INFO: Uninstalled $1"
                else
                    echo "ERROR: Failed to uninstall package $1" >&2
                    return 1
                fi
                ;;
            "install")
                if is_stowed "$1" "$3"; then
                    echo "ERROR: Package $1 is already installed"
                    return 1
                fi
                if stow -t "$3" "$1" > /dev/null 2>&1; then
                    echo "INFO: Installed $1"
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

        # Run bootstrap script after stowing
        case "$2" in
            "install" | "reinstall") run_bootstrap "$1" "install" ;;
            "uninstall") run_bootstrap "$1" "uninstall" ;;
        esac
    fi
}

# Setup the git hook directory
setup_git_hook() {
    if [ -d ".git" ]; then
        if ! git config --local core.hooksPath > /dev/null 2>&1; then
            git config --local core.hooksPath repo_resources/git_hooks
        fi
    fi
}

# Main entry point that processes command-line arguments.
#
# Arguments:
#   $1 - Action to perform (install, reinstall, uninstall)
#   $@ - Optional list of packages to manage (if not provided, all packages will be installed)
main() {
    # Show help if no arguments or help requested
    if [ $# -eq 0 ] || [ "$1" = "-h" ] || [ "$1" = "--help" ]; then
        usage
        exit 0
    fi

    # Get the action
    action="$1"
    shift

    # Validate action
    case "$action" in
        install | reinstall | uninstall) ;;
        *)
            echo "ERROR: Invalid action '$action'. Must be install, reinstall, or uninstall" >&2
            usage
            exit 1
            ;;
    esac

    # Check if stow is installed
    if ! command -v stow > /dev/null 2>&1; then
        echo "Error: GNU stow is not installed. Please install it first."
        exit 1
    fi

    if [ "$action" != "uninstall" ]; then
        setup_git_hook
    fi

    if [ $# -eq 0 ]; then
        for dir in $IGNORE_DIRS; do
            ignore_args="$ignore_args -not -name $dir"
        done
        for pkg in $(find . -maxdepth 1 -mindepth 1 -type d -not -name '.*' $ignore_args | cut -f 2 -d '/'); do
            stow_package "$pkg" "$action" "$HOME"
        done
    else
        for pkg in "$@"; do
            if [ -d "$pkg" ]; then
                stow_package "$pkg" "$action" "$HOME"
            else
                echo "ERROR: Package $pkg not found" >&2
            fi
        done
    fi
}

main "$@"
