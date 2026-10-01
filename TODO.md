# TODO

- castero:
  - add configuration

- shell/zsh:
  - rework atuin config and fix old shell_history leaking in
  - add theming for vivid, lazygit

- dmenu/menu:
  - allow multiple styles of menu prompts (grid/top-line/bottom-line/alfred-like etc.) which should support modification using either xresources/sourceable rc file
  - switch menu system backend from dmenu to rofi
  - rework dmenu-helper into backend-agnostic helper

- kitty:
  - update config specifically for kittens

- scripts:
  - implement scratchpad script
  - set unified metadata header for all scripts
  - unify code style for all scripts
  - publish unified style guide / templates for scripts
  - provide option to set the window title in terminal that was launched
  - provide missing scripts referenced by sxhkd mappings
  - add autoscaling/rendering script for wallpapers picked for xsecurelock
  - fix bspwmctl move not moving focused window to empty monitor
  - add ability to specify a monitor in `bspwm-workspace` script
  - rework keybind help menu scripts

- wm:
  - add a stacking window manager as an alternative to the tiling window manager
