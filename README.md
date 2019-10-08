<h2 align="center">

    ██████╗  ██████╗ ████████╗███████╗██╗██╗     ███████╗███████╗
    ██╔══██╗██╔═══██╗╚══██╔══╝██╔════╝██║██║     ██╔════╝██╔════╝
    ██║  ██║██║   ██║   ██║   █████╗  ██║██║     █████╗  ███████╗
    ██║  ██║██║   ██║   ██║   ██╔══╝  ██║██║     ██╔══╝  ╚════██║
    ██████╔╝╚██████╔╝   ██║   ██║     ██║███████╗███████╗███████║
    ╚═════╝  ╚═════╝    ╚═╝   ╚═╝     ╚═╝╚══════╝╚══════╝╚══════╝

</h2>

![nocturnalbeast's dotfiles](https://github.com/nocturnalbeast/dotfiles/raw/master/.screenshots/main.png)


## Usage

These dotfiles are managed with [GNU stow](https://www.gnu.org/software/stow/), so you'll need it installed.

Clone the repository, and install the configuration files for any program that's included by running
```
$ stow <package-name>
```

To install everything, just run
```
$ stow *
```

For a quick guide for managing and using dotfiles managed with [GNU stow](https://www.gnu.org/software/stow/), I recommend [alexpearce's guide](https://alexpearce.me/2016/02/managing-dotfiles-with-stow/) on the same.


## Details

* CLI
  * [termite](https://github.com/thestinger/termite/) - A keyboard centric VTE-based terminal, aimed at use within a window manager with tiling and/or tabbing support.
  * [neovim](https://github.com/neovim/neovim) - VIM fork focused on extensibility and usability.
    * [vim-plug](https://github.com/junegunn/vim-plug) - A minimalist VIM plugin manager.
    * [vim-surround](https://github.com/tpope/vim-surround) - Quoting/parenthesizing made simple.
    * [nerdtree](https://github.com/scrooloose/nerdtree) - A tree explorer plugin for VIM.
    * [deoplete](https://github.com/Shougo/deoplete.nvim) - Dark powered asynchronous completion framework for neovim/Vim8.
    * [syntastic](https://github.com/vim-syntastic/syntastic) - Syntax checking hacks for VIM.
    * [nerdcommenter](https://github.com/scrooloose/nerdcommenter) - VIM plugin for intensely orgamsic commenting.
    * [vim-polyglot](https://github.com/sheerun/vim-polyglot) - A solid language pack for VIM.
    * [vim-airline](https://github.com/vim-airline/vim-airline) - Lean & mean status/tabline for vim that's light as air.
    * [neverland-vim-theme](https://github.com/trapd00r/neverland-vim-theme) - A colorscheme that doesn't suck.
    * [vim-devicons](https://github.com/ryanoasis/vim-devicons) - VIM plugin that adds file type glyphs/icons to popular VIM plugins.
  * [mpd](https://github.com/MusicPlayerDaemon/MPD) - Music Player Daemon - a daemon for playing music of various formats.
  * [ncmpcpp](https://github.com/arybczak/ncmpcpp) - Featureful ncurses based MPD client inspired by ncmpc.
  * [mpc](https://github.com/MusicPlayerDaemon/mpc) - Command line client for mpd. (used in custom polybar controls)
  * [surfraw](https://gitlab.com/surfraw/Surfraw) - Shell Users' Revolutionary Front Rage Against the Web - a command line utility to search from multiple search engines and sources.
  * [cava](https://github.com/karlstav/cava) - Console-based Audio Visualizer for Alsa. (used only for MPD here)
  * [neofetch](https://github.com/dylanaraps/neofetch) - A command-line system information tool written in Bash.

* GUI
  * [bspwm](https://github.com/baskerville/bspwm) - The binary-space partitioning window manager.
  * [sxhkd](https://github.com/baskerville/sxhkd) - Simple X hotkey daemon.
  * [polybar](https://github.com/jaagr/polybar) - A fast and easy-to-use status bar.
  * [compton](https://github.com/tryone144/compton) - A compositor for X11. (fork with that sexy dual kawase blur mode)
  * [rofi](https://github.com/davatorium/rofi) - A window switcher, application launcher, and dmenu replacement.
    * [tnekcir-no-sidebar](https://github.com/ricwtk/rofi-themes) - A modern-looking theme that I've slightly modified for my use.
    * [libqalculate](https://github.com/Qalculate/libqalculate) - CLI for Qalculate! used in rofi with a helper script.
    * [greenclip](https://github.com/erebe/greenclip) - Simple clipboard manager to be integrated with rofi. 
  * [nitrogen](https://github.com/l3ib/nitrogen) - Background browser and setter for X windows.
  * [thunar](https://git.xfce.org/xfce/thunar/) - Modern, fast and easy-to-use file manager.
  * [firefox](https://www.mozilla.org/firefox/) - I use [MaterialFox](https://github.com/muckSponge/MaterialFox) with my Firefox installation. There's a script (inside the ```scripts``` directory) that helps to install it.

* Themes, fonts and other resources
  * [Pragmata Pro](https://www.fsd.it/shop/fonts/pragmatapro/) - A monospaced font family designed for coding texts by [Fabrizio Schiavi](https://github.com/fabrizioschiavi).
  * [San Francisco Pro Display](https://github.com/sahibjotsaggu/San-Francisco-Pro-Fonts) - Apple's default system UI font for their platforms.
  * [nerd-fonts](https://github.com/ryanoasis/nerd-fonts) - A collection of developer targeted fonts, patched with lots of glyphs/icons.
  * [fontconfig](https://gitlab.freedesktop.org/fontconfig/fontconfig) - Font configuration that dictates hinting and antialiasing options for font rendering.
  * colorscheme - Based on the visibone color scheme from [here](http://dotshare.it/dots/27/).
  * [Tela-grey](https://github.com/vinceliuice/Tela-icon-theme) - A modern icon set that fits well with my theme.
  * [Super Flat Remix](https://github.com/daniruiz/flat-remix-gtk) - A modern dark theme for the GTK applications that I use.
  * wallpapers - Some monochrome ones that I found from [WallHaven](https://alpha.wallhaven.cc). Links are given below.
    * [w_one](https://alpha.wallhaven.cc/wallpaper/62856)
    * [w_two](https://alpha.wallhaven.cc/wallpaper/161144) 
    * [w_three](https://alpha.wallhaven.cc/wallpaper/314722) 
    * [w_four](https://alpha.wallhaven.cc/wallpaper/727255) 
    * [w_five](https://alpha.wallhaven.cc/wallpaper/742779) 

* Some alternative configs are also present in this repo that aren't used in the default setup. They are listed below:
  * [i3-gaps](https://github.com/Airblader/i3) - A fork of i3 with more features, including support for gaps in window layouts.

## Screenshots
<div align="center">
  <img src="https://github.com/nocturnalbeast/dotfiles/raw/master/.screenshots/code.png">
  <br>
  <img src="https://github.com/nocturnalbeast/dotfiles/raw/master/.screenshots/dolphin.png">
  <br>
  <img src="https://github.com/nocturnalbeast/dotfiles/raw/master/.screenshots/settings.png">
  <br>
  <img src="https://github.com/nocturnalbeast/dotfiles/raw/master/.screenshots/chrome.png">
  <br>
  <img src="https://github.com/nocturnalbeast/dotfiles/raw/master/.screenshots/clean.png">
  <br>
  <img src="https://github.com/nocturnalbeast/dotfiles/raw/master/.screenshots/rofi.png">
</div>
