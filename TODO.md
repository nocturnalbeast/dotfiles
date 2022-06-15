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
 * Set a unified metadata header and code style for all shell scripts in the repository
 * Add window list to Polybar instead of only displaying focused window name
 * Rework how polybar state is managed (which is currently done using the `~/.cache/bar_state` file and uses the `polybar-helper` script)
 * Allow multiple styles of dmenu prompts (grid/top-line/bottom-line/alfred-like etc.) which should support modification using either xresources/sourceable rc file
 * Add `pet` to shell config

### In Progress

 * Work on switching from dmenu to rofi
 * Work on switching from st to kitty
 * Push the changes from this clone
 * Remove suckless configs from repo once done
 * Rename dmenu-helper into menu-helper
 * Rework neovim config
 * Write custom qutebrowser config
 * Integrate MPRIS2 support
 * Revisit window rules for bspwm and spectrwm
 * Add zinit-ices in zsh config to add manpages to $ZPFX
 * Add scroll action script for monitor/workspace icon module in Polybar
 * Write `terminal` script for launching preferred terminal
 * Add ability to specify a monitor in `bspwm-workspace` script
 * Write style guide for scripts
 * Create module for focused monitor in Polybar
 * Assign keybinds for switching focus & window movement across monitors
 * Check if generating custom bat theme is possible
 * Add entries into .gitignore
 * Add method to automatically focus on last window on close in bspwm
 * Rework keybinding help menu prompts
 * Create file association list for mimeo/xdg-open
