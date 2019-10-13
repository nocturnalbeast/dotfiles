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
  * [st](https://github.com/nocturnalbeast/st) - My fork of suckless.org's simple terminal emulator.
  * [zsh](https://sourceforge.net/projects/zsh) - A powerful alternative shell.
    * [zplugin](https://github.com/zdharma/zplugin) - Fast Z shell plugin manager with advanced reporting, services and more.
    * [zsh-completions](github.com/zsh-users/zsh-completions) - Additional completion definitions for Z shell.
    * [fast-syntax-highlighting](https://github.com/zdharma/fast-syntax-highlighting) - Faster syntax highlighting for Z shell.
    * [zsh-autosuggestions](https://github.com/zsh-users/zsh-autosuggestions) - FISH-like autosuggestions for Z shell.
    * [history-search-multi-word](https://github.com/zdharma/history-search-multi-word) - Multi-word, syntax-highlighted history searches for Z shell.
    * [enhancd](https://github.com/b4b4r07/enhancd) - Better cd command with customizable interactive filter.
    * [LS_COLORS](https://github.com/trapd00r/LS_COLORS) - A collection of LS_COLORS used to colorize output of ls command.
    * [exa](https://github.com/ogham/exa) - Replacement for ls written in Rust.
    * [bat](https://github.com/sharkdp/bat) - A cat clone with syntax highlighting and Git integration.
    * [warhol](https://github.com/unixorn/warhol.plugin.zsh) - Colorize output of common commands.
    * [zsh-colored-man-pages](https://github.com/ael-code/zsh-colored-man-pages) - Colorize options and such in man pages.
    * [zsh-diff-so-fancy](https://github.com/zdharma/zsh-diff-so-fancy) - Supercharged git diff with better highlighting.
    * [git-now](https://github.com/iwata/git-now) - A temporary commit tool for git.
    * [git-extras](https://github.com/tj/git-extras) - Adds extra commands to git, including repo summary, repl and more.
    * [git-cal](https://github.com/k4rthik/git-cal) - Github-like contributions chart in the terminal.
    * [thefuck](https://github.com/nvbn/thefuck) - Program that corrects previous mistyped command.
    * [spaceship-prompt](https://github.com/maximbaz/spaceship-prompt) - A prompt for astronauts - asynchronous version. 
  * [neovim](https://github.com/neovim/neovim) - VIM fork focused on extensibility and usability.
    * [vim-plug](https://github.com/junegunn/vim-plug) - A minimalist VIM plugin manager.
    * [vim-sensible](https://github.com/tpope/vim-sensible) - Sensible defaults for VIM.
    * [ale](https://github.com/dense-analysis/ale) - Asynchronous Linting Engine fo VIM.
    * [goyo](https://github.com/junegunn/goyo.vim) - Distraction-free writing in VIM.
    * [limelight](https://github.com/junegunn/limelight.vim) - Selective highlighting in VIM. (used in tandem with goyo)
    * [lightline](https://github.com/itchyny/lightline.vim) - A light and configurable statusline/tabline plugin for VIM.
    * [vim-startify](https://github.com/mhinz/vim-startify) - The fancy startscreen for VIM.
    * [vim-polyglot](https://github.com/sheerun/vim-polyglot) - A solid language pack for VIM.
    * [nerdcommenter](https://github.com/scrooloose/nerdcommenter) - VIM plugin for intensely orgamsic commenting.
    * [vim-surround](https://github.com/tpope/vim-surround) - Quoting/parenthesizing made simple.
    * [challenger-deep-theme](https://github.com/challenger-deep-theme/vim) - Dark colorscheme for VIM.
    * [vim-devicons](https://github.com/ryanoasis/vim-devicons) - VIM plugin that adds file type glyphs/icons to popular VIM plugins.
    * [fzf](https://github.com/junegunn/fzf) - Fuzzy finding for VIM.
    * [vim-gitgutter](https://github.com/airblade/vim-gitgutter) - VIM plugin that shows git diff in the sign column.
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
  * [termite](https://github.com/thestinger/termite/) - A keyboard centric VTE-based terminal, aimed at use within a window manager with tiling and/or tabbing support.

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
