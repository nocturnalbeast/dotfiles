#!/bin/bash

NAME=$(basename "$0")
VER="0.3-mod"

usage() {
echo -n "Usage: $NAME [OPTIONS]

Options:
  -h, --help        Show this help dialog
  -v, --version     Display script version
  -r, --run         Show app launcher
  -w, --window      Show list of open windows
  -c, --calculate   Calculate an expression
  -b, --clipboard   Show contents of the clipboard
  -p, --power       Display the power menu
"
}


for arg in "$@"; do
	case $arg in
		-h|--help)
			usage
			exit 0
			;;
		-v|--version)
			echo -e "$NAME -- Version $VER"
			exit 0
			;;
		-r|--run)
			rofi -modi run,drun -show drun \
				-hide-scrollbar -show-icons -scroll-method 1
			;;
		-w|--window)
			rofi -modi window -show window \
				-hide-scrollbar -scroll-method 1
			;;
		-c|--calculate)
			! hash qalc &>/dev/null && { echo "Requires 'libqalculate' installed"; exit 1; }
			rofi -modi "calc:qalc +u8 -nocurrencies" -lines 1\
				-show "calc:qalc +u8 -nocurrencies" \
				-hide-scrollbar
			;;
		-b|--clipboard)
			! hash greenclip &>/dev/null && { echo "Requires 'greenclip' installed"; exit 1; }
			rofi -modi "clipboard:greenclip print" \
				-show "clipboard:greenclip print" \
				-hide-scrollbar -scroll-method 1
			;;
		-p|--power)
			ANS="$(rofi -sep "|" -dmenu -i -p 'System' \
				-width 15 \
				-hide-scrollbar -lines 4 <<< " Lock| Logout| Reboot| Shutdown")"
			case "$ANS" in
				*Lock) dm-tool lock ;;
				*Logout) session-logout || pkill -15 -t tty"$XDG_VTNR" Xorg ;;
				*Reboot) shutdown -r now ;;
				*Shutdown) shutdown now ;;
			esac ;;
		*) echo; echo "Option does not exist: $arg"; echo; exit 2
	esac
done