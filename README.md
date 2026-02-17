<div align="center">
    <picture>
        <source media="(prefers-color-scheme: dark)" srcset="https://github.com/nocturnalbeast/dotfiles/blob/master/repo_resources/logo-dark.png?raw=true">
      <img alt="logo" src="https://github.com/nocturnalbeast/dotfiles/blob/master/repo_resources/logo-light.png?raw=true">
    </picture>
</div>

## Usage

These dotfiles are managed with [GNU stow](https://www.gnu.org/software/stow/), so you'll need it installed. Python 3.11+ is required for the installer script.

### Basic Installation

Clone the repository and run the installer:

```sh
./install install              # Install all packages
./install install git zsh      # Install specific packages
./install install --tag cli    # Install all CLI packages
```

### Commands

| Command | Description |
|---------|-------------|
| `install` | Install packages |
| `reinstall` | Reinstall packages (force override) |
| `uninstall` | Uninstall packages |
| `check` | Check installation status and conflicts |
| `list` | List all packages |
| `list-tags` | List all available tags |
| `status` | Show installation status of all packages |

### Tag-based Management

Packages can be managed using tags for easy grouping:

```sh
./install install --tag shell                 # Install all shell packages
./install install --tag x11 --tag gui         # Install packages matching ANY tag
./install list --tag x11 --tag wayland --and  # Packages with BOTH tags
./install uninstall --tag wayland             # Uninstall all Wayland packages
```

### Cross-Platform Support

Packages are tagged with supported platforms. By default, only packages compatible with your OS are installed:

```sh
./install install              # Only installs packages for current OS
./install list --platform      # Show platform info for all packages
./install --os macos list      # Simulate macOS (for testing)
./install --os macos status    # See what's available on macOS
```

| Flag | Description |
|------|-------------|
| `--os` | Target OS (linux, macos, windows) |
| `--arch` | Target architecture (x86_64, arm64) |
| `--platform` | Show OS/arch info in list output |
| `--all`, `-a` | Show all packages including unavailable ones |
| `--include-unavailable` | Install even if platform doesn't match |

### Package Metadata

Each package has a `.package.toml` file with metadata:

```toml
enabled = true  # set false to skip package
description = "example description"
tags = ["tag1", "tag2"]
os = ["linux", "macos"]  # supported platforms (empty = all)
arch = []  # architecture restrictions (empty = all)
condition = "<shell command>"
```

## Components

* Desktop:
  * [bspwm](https://github.com/baskerville/bspwm): A tiling window manager based on binary space partitioning
  * [dunst](https://github.com/dunst-project/dunst): Lightweight notification daemon for X11
  * [mako](https://github.com/emersion/mako): Lightweight notification daemon for Wayland
  * [picom](https://github.com/yshui/picom): A lightweight compositor for X11
  * [polybar](https://github.com/polybar/polybar): A fast and easy-to-use status bar
  * [sxhkd](https://github.com/baskerville/sxhkd): Simple X hotkey daemon
  * [swww](https://github.com/Horus645/swww): Efficient animated wallpaper daemon for wayland
  * [swaybg](https://github.com/swaywm/swaybg): Wallpaper tool for Wayland compositors
  * [xwallpaper](https://github.com/stoeckmann/xwallpaper): Wallpaper setting utility for X11
  * [feh](https://feh.finalrewind.org): Image viewer and wallpaper setter

* Shell:
  * [zsh](https://www.zsh.org): The Z Shell
  * [bash](https://www.gnu.org/software/bash): The Bourne Again SHell

* Applications:
  * GUI:
    * [dmenu](https://tools.suckless.org/dmenu): Dynamic menu for X11
    * [fastfetch](https://github.com/fastfetch-cli/fastfetch): Fast system information tool
    * [imv](https://sr.ht/~exec64/imv): Image viewer for X11/Wayland
    * [kitty](https://github.com/kovidgoyal/kitty): Fast, feature-rich, GPU-based terminal emulator
    * [mpv](https://mpv.io): Free and open source media player
    * [pqiv](https://github.com/phillipberndt/pqiv): Powerful image viewer with minimal UI
    * [thunar](https://docs.xfce.org/xfce/thunar/start): Modern file manager for Xfce
    * [zathura](https://pwmt.org/projects/zathura): Document viewer with vim-like interface
  * CLI:
    * [bandwhich](https://github.com/imsnif/bandwhich): Network utilization monitor
    * [bat](https://github.com/sharkdp/bat): A cat clone with syntax highlighting
    * [beets](https://beets.io): Music library manager and MusicBrainz tagger
    * [bottom](https://github.com/ClementTsang/bottom): Graphical process/system monitor
    * [brightnessctl](https://github.com/Hummer12007/brightnessctl): Backlight and LED control
    * [cava](https://github.com/karlstav/cava): Console-based audio visualizer
    * [delta](https://github.com/dandavison/delta): A syntax-highlighting pager for git
    * [eza](https://github.com/eza-community/eza): Modern replacement for ls
    * [fd](https://github.com/sharkdp/fd): Simple, fast and user-friendly alternative to find
    * [fzf](https://github.com/junegunn/fzf): Command-line fuzzy finder
    * [gh](https://github.com/cli/cli): GitHub's official command line tool
    * [glow](https://github.com/charmbracelet/glow): Terminal markdown viewer
    * [handlr](https://github.com/Anomalocaridid/handlr-regex): A better xdg-utils implementation with regex support
    * [hexyl](https://github.com/sharkdp/hexyl): Command-line hex viewer
    * [hub](https://github.com/mislav/hub): Extension to command-line git
    * [hyperfine](https://github.com/sharkdp/hyperfine): Command-line benchmarking tool
    * [jq](https://github.com/jqlang/jq): Command-line JSON processor
    * [maim](https://github.com/naelstrof/maim): Screenshot utility for X11
    * [mimeo](https://xyne.dev/projects/mimeo): Open files by MIME-type and handle associated applications
    * [mmv](https://github.com/itchyny/mmv): Mass rename utility
    * [mopidy](https://github.com/mopidy/mopidy): Extensible music server
    * [navi](https://github.com/denisidoro/navi): Interactive command-line cheatsheet
    * [rmpc](https://github.com/mierak/rmpc): Rusty Music Player Client - a modern MPD client
    * [neovim](https://github.com/neovim/neovim): Hyperextensible Vim-based text editor
    * [newsboat](https://newsboat.org): Terminal RSS/Atom feed reader
    * [pipewire](https://pipewire.org): Low-latency audio/video router and processor
    * [playerctl](https://github.com/altdesktop/playerctl): MPRIS media player controller
    * [ripgrep](https://github.com/BurntSushi/ripgrep): Fast grep alternative
    * [slop](https://github.com/naelstrof/slop): Select Operation - region selector for X11
    * [surfraw](https://gitlab.com/surfraw/Surfraw): CLI to search engines
    * [tealdeer](https://github.com/dbrgn/tealdeer): A fast tldr client in Rust
    * [tmux](https://github.com/tmux/tmux): Terminal multiplexer
    * [trash-cli](https://github.com/andreafrancia/trash-cli): CLI interface to FreeDesktop.org trash
    * [udiskie](https://github.com/coldfix/udiskie): Automounter for removable media
    * [ueberzug](https://github.com/seebye/ueberzug): X11 image display for terminals
    * [vivid](https://github.com/sharkdp/vivid): LS_COLORS generator
    * [xdotool](https://github.com/jordansissel/xdotool): Command-line X11 automation tool
    * [xh](https://github.com/ducaale/xh): Friendly and fast HTTP tool
    * [xsecurelock](https://github.com/google/xsecurelock): X11 screen lock utility
    * [yq](https://github.com/mikefarah/yq): YAML processor
    * [yt-dlp](https://github.com/yt-dlp/yt-dlp): Command-line program to download videos

* Theming:
  * [oomox](https://github.com/themix-project/oomox): Theme generator for GTK and icons
  * [papirus-icon-theme](https://github.com/PapirusDevelopmentTeam/papirus-icon-theme): SVG icon theme base
  * GTK/Qt Themes:
    * `bnw`: Custom black and white theme generated with oomox
  * Icon Themes:
    * `bnw`: Custom monochrome variant of Papirus
  * Cursor Theme:
    * [Bibata](https://github.com/ful1e5/Bibata_Cursor): Modern material-based cursor theme
  * Supported Environments:
    * GTK 2.0/3.0/4.0: Complete theme support
    * Qt 5/6: Theme integration via qt5ct and qt6ct

## Keybinding layout

All the global keybindings use the `Super/Win` key as the main modifier.
You can use these layout diagrams to familiarize yourself with the key bindings, or you can customize them to fit your liking!

### Tiling WM keybindings

<img align="center" src="https://github.com/nocturnalbeast/dotfiles/blob/master/repo_resources/key_layouts/images/tiling.png?raw=true" alt="tiling-layout">

## Screenshots

* Default desktop - clean

   (to be added)

* Default desktop - floating window with alternate bar

   (to be added)

* Default desktop - busy

   (to be added)

* Menu interaction

   (to be added)

* Sample GTK application (file manager)

   (to be added)
