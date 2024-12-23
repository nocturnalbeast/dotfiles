<div align="center">
    <picture>
        <source media="(prefers-color-scheme: dark)" srcset="https://github.com/nocturnalbeast/dotfiles/blob/master/repo_resources/logo-dark.png?raw=true">
      <img alt="logo" src="https://github.com/nocturnalbeast/dotfiles/blob/master/repo_resources/logo-light.png?raw=true">
    </picture>
</div>

## Usage

These dotfiles are managed with [GNU stow](https://www.gnu.org/software/stow/), so you'll need it installed.

To install these dotfiles, there is an installer script included. Clone the repository, and run the script `install.sh` to install all available packages.

For a quick guide for managing and using dotfiles managed with [GNU stow](https://www.gnu.org/software/stow/), I recommend [alexpearce's guide](https://alexpearce.me/2016/02/managing-dotfiles-with-stow/) on the same.


## Components

 * Desktop:
    * [bspwm](https://github.com/baskerville/bspwm): A tiling window manager based on binary space partitioning.
    * [spectrwm](https://github.com/conformal/spectrwm): A small dynamic tiling window manager for X11.
    * [sxhkd](https://github.com/baskerville/sxhkd): Simple X hotkey daemon
    * [polybar](https://github.com/polybar/polybar): A fast and easy-to-use status bar.
    * [dmenu](https://tools.suckless.org/dmenu): Dynamic menu for X.
        * [clipmenu](https://github.com/cdown/clipmenu): Clipboard management using dmenu.
    * [picom](https://github.com/yshui/picom): A lightweight compositor for X11.
    * [dunst](https://github.com/dunst-project/dunst): Lightweight and customizable notification daemon.

 * Applications:
    * [kitty](https://github.com/kovidgoyal/kitty):  Cross-platform, fast, feature-rich, GPU based terminal.
    * [neovim](https://github.com/neovim/neovim): Vim fork focused on extensibility and usability.
        * [vim-plug](https://github.com/junegunn/vim-plug): Minimalist vim plugin manager.
    * [mopidy](https://github.com/mopidy/mopidy): Extensible music server written in Python.
        * [mopidy-mpd](https://github.com/mopidy/mopidy-mpd): Extension for controlling playback from MPD clients.
        * [mopidy-soundcloud](https://github.com/mopidy/mopidy-soundcloud): Extension for playing music from SoundCloud.
        * [mopidy-scrobbler](https://github.com/mopidy/mopidy-scrobbler): Extension for scrobbling played tracks to Last.fm.
        * [mopidy-spotify](https://github.com/mopidy/mopidy-spotify): Extension for playing music from Spotify.
        * [mopidy-alsamixer](https://github.com/mopidy/mopidy-alsamixer): Extension for ALSA volume control.
        * [mopidy-local](https://github.com/mopidy/mopidy-local): Extension for playing music from your local music archive.
        * [mopidy-youtube](https://github.com/natumbri/mopidy-youtube): Extension for playing music from YouTube.
        * [mopidy-mpris](https://github.com/mopidy/mopidy-mpris): Extension for controlling Mopidy through the MPRIS D-Bus interface.
    * [ncmpcpp](https://github.com/ncmpcpp/ncmpcpp): Featureful ncurses based MPD client.
    * [mpc](https://github.com/MusicPlayerDaemon/mpc): Command-line client for MPD.
    * [firefox](https://www.mozilla.org/firefox): A free and open-source web browser developed by the Mozilla Foundation.
    * [xwallpaper](https://github.com/stoeckmann/xwallpaper): Wallpaper setting utility for X.
    * [newsboat](https://github.com/newsboat/newsboat): An RSS/Atom feed reader for text terminals.
    * [castero](https://github.com/xgi/castero): TUI podcast client for the terminal.
    * [bottom](https://github.com/ClementTsang/bottom): Yet another cross-platform graphical process/system monitor.
    * [cava](https://github.com/karlstav/cava): Console-based Audio Visualizer for Alsa.
    * [thunar](https://gitlab.xfce.org/xfce/thunar): Modern, fast and easy-to-use file manager for XFCE.
    * [engrampa](https://github.com/mate-desktop/engrampa): A file archiver for MATE.
    * [mpv](https://github.com/mpv-player/mpv): A free, open source, and cross-platform media player.
    * [zathura](https://git.pwmt.org/pwmt/zathura): A highly customizable and functional document viewer.
    * [pqiv](https://github.com/phillipberndt/pqiv): Powerful image viewer with minimal UI.
    * [maim](https://github.com/naelstrof/maim): Screenshot utility.

 * Shell:
    * [zsh](http://zsh.sourceforge.net): The Z SHell - designed for interactive use and powerful scripting.
        * [zinit](https://github.com/zdharma/zinit): Ultra-flexible and fast ZSH plugin manager.
    * [bash](https://git.savannah.gnu.org/cgit/bash.git): The Bourne Again SHell - the GNU standard shell.

 * Shell utilities:
    * [surfraw](https://gitlab.com/surfraw/Surfraw): Utility to search the web using multiple search engines from the command line.
    * [ueberzug](https://github.com/seebye/ueberzug): Command line util which allows to draw images on terminals by using child windows.
    * [vivid](https://github.com/sharkdp/vivid): A generator for LS_COLORS with support for multiple color themes.
    * [exa](https://github.com/ogham/exa): A modern replacement for ‘ls’.
    * [bat](https://github.com/sharkdp/bat): A cat(1) clone with wings.
    * [dtrx](https://github.com/brettcs/dtrx): CLI tool that extracts archives in a number of different formats.
    * [trash-cli](https://github.com/andreafrancia/trash-cli): Command line interface to the freedesktop.org trashcan.
    * [ripgrep](https://github.com/BurntSushi/ripgrep): CLI that recursively searches directories for a regex pattern while respecting your gitignore.
    * [fzf](https://github.com/junegunn/fzf): A command-line fuzzy finder.
    * [lyricwikia](https://github.com/enricobacis/lyricwikia): Python API to get song lyrics from LyricWikia.
    * [neofetch](https://github.com/dylanaraps/neofetch): A command-line system information tool written in bash 3.2+.
    * [bc](http://phodd.net/gnu-bc): A fairly ubiquitous, useful and powerful calculator.
    * [wmctrl](http://tripie.sweb.cz/utils/wmctrl): Command line tool to interact with an EWMH/NetWM compatible X Window Manager.
    * [xdotool](https://github.com/jordansissel/xdotool): Fake keyboard/mouse input, window management, and more.
    * [playerctl](https://github.com/altdesktop/playerctl): MPRIS media player command-line controller.
    * [youtube-dl](https://github.com/ytdl-org/youtube-dl): Command-line program to download videos from YouTube.com and other video sites.

 * Appearance-related resources:
    * Shell prompt:
        * [Starship](https://github.com/starship/starship): The minimal, blazing-fast, and infinitely customizable prompt for any shell!
    * Fonts:
        * [Iosevka](https://github.com/be5invis/Iosevka): Slender typeface for code, from code.
        * [nerd-fonts](https://github.com/ryanoasis/nerd-fonts): Iconic font aggregator, collection, & patcher.
    * Themes:
        * [bnw](https://github.com/nocturnalbeast/dotfiles/tree/master/gtk/.themes/bnw): My personal theme (made with [themix](https://github.com/themix-project)). High contrast, and as dark as possible!
    * Cursors:
        * [Bibata](https://github.com/ful1e5/Bibata_Cursor): Material based cursors.
    * Icons:
        * [papirus-bnw](https://github.com/nocturnalbeast/dotfiles/tree/master/gtk/.icons/oomox-bnw): A variant of [Papirus](https://github.com/PapirusDevelopmentTeam/papirus-icon-theme) made with [themix](https://github.com/themix-project) to compliment the main theme.
    * Wallpapers:
        * All wallpapers are obtained from [wallhaven](https://wallhaven.cc).


## Keybinding layout

All the global keybindings use the `Super/Win` key as the main modifier.
You can use these layout diagrams to familiarize yourself with the key bindings, or you can customize them to fit your liking!

#### Tiling WM keybindings

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
