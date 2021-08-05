# TODO

These are the things that are planned to be worked on or in progress right now:

### Planned

 * Switch to neovide for neovim
 * Add a floating window manager as an alternative to the tiling window manager (bspwm) and the dynamic window manager (spectrwm)
 * Integrate any of the following terminal multiplexers - tmux/screen/byobu
 * Create bootstrapping scripts for tools like neovim and zsh
 * Add logiops config for MX Master 3
 * Add castero config
 * Implement scratchpad feature
 * rc.d-style bootstrap directory
 * Remove all theme files and replace them with oomox/themix config files and have the install/bootstrap script generate them on the fly
 * Removing dynamic config values from Polybar config and separating into sourcable `polybar-dynamicrc` file
 * Breaking down the Polybar config into smaller, manageable chunks
 * Rework `setbg` script with better handling of current symlink method and use fallback like `feh`, `xsetroot` etc. if `xwallpaper` isn't present
 * Set a unified metadata header and code style for all shell scripts in the repository
 * Rework keybinding help menu prompts
 * Add window list to Polybar instead of only displaying focused window name
 * Rework how polybar state is managed (which is currently done using the `~/.cache/bar_state` file and uses the `polybar-helper` script)
 * Allow multiple styles of dmenu prompts (grid/top-line/bottom-line/alfred-like etc.) which should support modification using either xresources/sourceable rc file
 * Rework how icon fonts are configured in Polybar.
 * Add `pet` to shell config

### In Progress

 * Rework neovim config
 * Write custom qutebrowser config
 * Integrate MPRIS2 support
 * Revisit window rules for bspwm and spectrwm
 * Add zinit-ices in zsh config to add manpages to $ZPFX
 * Add scroll action script for monitor/workspace icon module in Polybar
 * Write `term` script for launching preferred terminal
 * Update starship config
