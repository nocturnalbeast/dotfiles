# TODO

* castero:
  * add configuration

* dmenu/menu:
  * allow multiple styles of menu prompts (grid/top-line/bottom-line/alfred-like etc.) which should support modification using either xresources/sourceable rc file
  * switch menu system backend from dmenu to rofi
  * rework dmenu-helper into backend-agnostic helper

* gtk:
  * remove all theme files and replace them with oomox/themix config files and have the install/bootstrap script generate them on the fly
  * add GTK4 configuration

* kitty:
  * update config specifically for kittens

* neovim:
  * add configuration for required GUIs (neovide/fvim/etc.)
  * rewrite config in lua
  * rename top-level folder from `nvim` to `neovim`

* polybar:
  * add window list module
  * investigate how state management can be reworked (which is currently done using the `~/.cache/bar_state` file and uses the `polybar-helper` script)

* scripts:
  * implement scratchpad script
  * set unified metadata header for all scripts
  * unify code style for all scripts
  * publish unified style guide / templates for scripts
  * provide option to set the window title in terminal that was launched
  * provide missing scripts referenced by sxhkd mappings
  * add autoscaling/rendering script for wallpapers picked for xsecurelock
  * fix bspwm-move not moving focused window to empty monitor
  * add scroll action script for monitor/workspace icon module in Polybar
  * add ability to specify a monitor in `bspwm-workspace` script
  * rework keybind help menu scripts

* spectrwm:
  * remove deprecated spectrwm config

* wm:
  * add a stacking window manager as an alternative to the tiling window manager
