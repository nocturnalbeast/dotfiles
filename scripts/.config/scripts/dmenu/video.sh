#!/bin/bash

DEPENDENCIES=(youtube-dl clipmenu)
for DEPENDENCY in "${DEPENDENCIES[@]}"; do
    type -p "$DEPENDENCY" &>/dev/null || {
        echo "error: Could not find '${DEPENDENCY}', is it installed?" >&2
        exit 1
    }
done

source ~/.config/scripts/dmenu-helper.sh
source ~/.config/scripts/polybar-helper.sh
bar_hide_active
trap bar_show_first EXIT

# external downloader args 
ED_ARGS="-c -j 3 -x 3 -s 3 -k 1M"

# destination folder
DEST_DIR="$XDG_VIDEOS_DIR/downloaded"

# use regex to match possible urls from clipboard history
URL=$( menu " 輸 Select URL: " "$( clipdel ".*" | xargs -0 | grep -Eo "(((http|magnet|https|ftp|gopher)|mailto):(//|\?)?[^ <>\"\t]*|(www|ftp)[0-9]?\\.[-a-z0-9.]+)[^ .,;\\n\r<\">\\):]?[^, <>\"\]*[^ .,;\\n\r<\">\\):]" )")
[ "$URL" == "" ] && exit 0

# get the name of the video
VNAME=$( youtube-dl -e "$URL" )

# display options; whether to stream in mpv or in browser or to download
ACTION=$( menu " 輸 What to do with this URL? " "契 Stream\n Open in browser\n Download" )
[ "$ACTION" == "" ] && exit 0

case "$ACTION" in
    '契 Stream')
        # if streaming, send a notification
        notify-send -a "Video" " Opening URL" "$VNAME"
        # and then open in mpv
        mpv "$URL" &
        ;;
    ' Open in browser')
        # if opening in browser, send a notification
        notify-send -a "Video" " Opening URL in browser" "$VNAME"
        # and use xdg-open to open in default browser
        xdg-open "$URL" &
        ;;
    ' Download')
        # if downloading the video, send a notification
        notify-send -a "Video" " Fetching available formats"
        # get the available formats
        AVAIL_FMTS=$( youtube-dl -F "$URL" | tail -n +4 | sed 's/audio only/audio/g; s/ \+/,/g' | tr -s ',' ':' )
        # clean up the format a bit and then show all of them for selection
        QUALITY=$( menu " 輸 Select quality: " "$AVAIL_FMTS" | cut -f 1 -d : )
        # if nothing is selected, exit
        [ "$QUALITY" == "" ] && exit 0
        # if destination folder does not exist, create one
        [ ! -d "$DEST_DIR" ] && mkdir -p "$DEST_DIR"
        # then download in the preferred quality
        if [ "$ED_ARGS" == "" ]; then
            youtube-dl -f $QUALITY -o "$DEST_DIR/%(title)s.%(ext)s" --external-downloader aria2c "$URL"
        else
            youtube-dl -f $QUALITY -o "$DEST_DIR/%(title)s.%(ext)s" --external-downloader aria2c --external-downloader-args "$ED_ARGS" "$URL"
        fi
        # and show a notification once done
        notify-send -a "Video" " Download completed" "$VNAME"
        ;;
esac
