# TODO

These are the things that are planned to be worked on or in progress right now:

### Planned

 * neovim: add configuration for required GUIs (neovide/fvim/etc.)
 * wm: add a stacking window manager as an alternative to the tiling window manager
 * tmux: add configuration as a fallback to kitty's multiplexing capabilities
 * castero: add configuration
 * scripts: implement scratchpad script
 * install: implement package installation scripts for distros in use
 * gtk: remove all theme files and replace them with oomox/themix config files and have the install/bootstrap script generate them on the fly
 * scripts: set unified metadata header for all scripts
 * scripts: unify code style for all scripts
 * scripts: publish unified style guide / templates for scripts
 * polybar: add window list module
 * polybar: investigate how state management can be reworked (which is currently done using the `~/.cache/bar_state` file and uses the `polybar-helper` script)
 * dmenu/menu: allow multiple styles of menu prompts (grid/top-line/bottom-line/alfred-like etc.) which should support modification using either xresources/sourceable rc file
 * zsh: add `pet` to shell config
 * dmenu/menu: switch menu system backend from dmenu to rofi
 * dmenu/menu: rework dmenu-helper into backend-agnostic helper
 * bat: check possibility of generating custom bat theme

### In Progress

 * kitty: update config specifically for kittens
 * scripts: provide option to set the window title in terminal that was launched
 * scripts: provide missing scripts referenced by sxhkd mappings
 * sxhkd/docs: update keymap diagrams
 * spectrwm: remove deprecated spectrwm config
 * neovim: rewrite config in lua
 * neovim: rename top-level folder from `nvim` to `neovim`
 * zsh: add zinit-ices in `.zshrc` to add manpages to `$ZPFX`
 * dmenu: fix dmenu unified patch for use with latest release
 * gtk: add GTK4 configuration
 * scripts: add autoscaling/rendering script for wallpapers picked for xsecurelock
 * scripts: fix bspwm-move not moving focused window to empty monitor
 * scripts: add scroll action script for monitor/workspace icon module in Polybar
 * scripts: add ability to specify a monitor in `bspwm-workspace` script
 * repo/docs: add entries into .gitignore
 * scripts: rework keybind help menu scripts
