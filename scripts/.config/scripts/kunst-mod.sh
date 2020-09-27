#!/usr/bin/env bash

# Source: KUNST from https://github.com/sdushantha/kunst
# stripped image previews and added a notification option

COVER=/tmp/mpd_albumart.jpg
MUSIC_DIR=~/Music/
SIZE=250x250
POSITION="+0+0"
ONLINE_ALBUM_ART=false

show_help() {
printf "%s" "\
usage: kunst [-h] [--size \"px\"] [--position \"+x+y\"][--music_dir \"path/to/dir\"] [--silent] [--version]
┬┌─┬ ┬┌┐┌┌─┐┌┬┐
├┴┐│ ││││└─┐ │
┴ ┴└─┘┘└┘└─┘ ┴
Download and display album art or display embedded album art
optional arguments:
   -h, --help            show this help message and exit
   --size                what size to display the album art in
   --music_dir           the music directory which MPD plays from
   --silent              dont show the output
   --force-online        force getting cover from the internet
   --notify              send notification on song change
"
}


# Parse the arguments
OPTIONS=$(getopt -o h --long size:,music_dir:,version,force-online,silent,notify,help -- "$@")
eval set -- "$OPTIONS"

while true; do
    case "$1" in
        --size)
            shift;
            SIZE=$1
            ;;
        --music_dir)
            shift;
            MUSIC_DIR=$1
            ;;
        -h|--help)
            show_help
            exit
            ;;
        --force-online)
            ONLINE_ALBUM_ART=true
            ;;
        --silent)
            SILENT=true
            ;;
        --notify)
            NOTIFICATION=true
            ;;
        --)
            shift
            break
            ;;
    esac
    shift
done

# This is a base64 endcoded image which will be used if
# the file does not have an emmbeded album art.
# The image is an image of a music note
read -r -d '' MUSIC_NOTE << EOF
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ITEgQVFhkfBxgaEwsdHB4fH/2gAIAQEAAT8QPCPZeXwgcENvCzyd3Ds8QGbYj/AYUQww8bbMy8IPI8jbEuTvu67uBKGGG222WWWZcFwe03dwZl4GXB8FKUoZQww222yyyy4KXI8im2IlOUoZShhhhhtttllllLKXBzyKVsRyKUpQwwwww222yyyyylPeXhBltjwgpQyhhhhtttttllllllmeRcHg4LgoZSiGGGGG3hsstq7h273f5SEmGms6vndCj5SzKZcim3gZSlKGGGGGG2221utzBMH5XpZQeq3f4fN5GyP5Bh/WyiL/APMBdOXShfMzLLLKUpTbDEpSlDDDDDDbOyTyx/tnLvLPf6j4GIVnZH9Og+L2mgiPx2HxeWeXgUf3P+5ZZllKUy8DDKUoYYYYYYZH4NjQMYp07vafoXdvzPifd5mCd1TsfnhQvmZZZZSlKWW2GGGUpShhhhh8CV6GvQhoZ89n8rD+2237j/wHy2eD9yfjh87HRmZy7eRxYXzMsssspSlLbwMpSlDDDDDDw1ExqY7War7yw157X+r+T3mOPU/fQ/RGAAB2HQP1bbP6vpx4XzMssspSlKbYYZSlKGGGGGHiqs+h0W2222y+z6cOF8zLLLKUpSlthhhlKUMMMMMM9kfqPRbbbbbP6PpwIXzMsssspSlltthlKUoYYYYYZbA/Wei22222X1fTicvmZZZZSlKWW3ghlKGGGGGGHiD9Z6LbbbbZ/d9L7n0y+ZllllKUpeNtiGUMoYYYYYZb9TpXn0ui23h7CWQ+Wfhb/wDe3BR0R5el9z6ZfMyyyyylKWXkiUoYYYYYYb6T0rz7XRwJsLVMA9VtCZ3C38nl7v0S1N8z/t0P1Yeh8RgBGBZp6PrfY+mXzMssspSlm3khiGGGGGGHext1O4/E9+h0rz7XRbOHQC9XX8Hm/rw/W+mfzMsssspZZ8IwwwwwycML4A81sHw6dk+//q/E1DPmi/WC91Ef9MiB16K6zevd7He6frdEtB6uSYq118gQHwHh80gPsLX8J0r69ZZZZSlnw7wMMMQiYToy6D3XqD2P34Vn1umEdScSL8gjen4dPChilsd70H2Dp+304MYxiy28aW2222wwwze4xfRAP9u3Tw9Iu8PdT/5bYCdr3d7ep6k8eQV1z3fU/s9GPJ/4xoVeWF+8R+Bb1teydU9g/cftQDAHYC2WWWWXjed52IYYYNtYTzQB/PF1vebvhgf11/dtvvb72vV8228GMYststvg222222GMRb9nt08z+fp8XQaIqX9tPU+Yw0fN8Py9j5ts+egPJfZz0On5/wAIAzWYzbbbbbbbbbeBNt5PbhQD+3u0w1/1IAADyOh/kAB+UzbbbbbbbW2223/EAPy8A/LxA3wDbfe222222223htttvhDbfANttt4bbw22222222222222222222222222222222220tttttt422222222222222222223jbeN43jbbeN43jbbfFttvG8bxttttvJ4i8/8zP8Ag//Z
EOF

is_connected() {
    # Check if internet is connected. We are using api.deezer.com to test
    # if the internet is connected because if api.deezer.com is down or
    # the internet is not connected this script will work as expected
    if ping -q -c 1 -W 1 api.deezer.com >/dev/null; then
        connected=true
    else
        [ ! "$SILENT" ] && echo "kunst: unable to check online for the album art"
        connected=false
    fi
}


get_cover_online() {
    # Check if connected to internet
    is_connected

    if [ "$connected" == false ];then
        ARTLESS=true
        return
    fi

    # If the current playing song ends with .mp3 or something similar, remove
    # it before searching for the album art because including the file extension
    # reduces the chance of good results in the search query
    QUERY=$(mpc current | sed 's/\.[^.]*$//' | iconv -t ascii//TRANSLIT -f utf8)

    # Try to get the album cover online from api.deezer.com
    API_URL="https://api.deezer.com/search/autocomplete?q=$QUERY" && API_URL=${API_URL//' '/'%20'}

    # Extract the albumcover from the json returned
    IMG_URL=$(curl -s "$API_URL" | jq -r '.tracks.data[0].album.cover_big')

    if [ "$IMG_URL" = '' ] || [ "$IMG_URL" = 'null' ];then
        [ ! "$SILENT" ] && echo "error: cover not found online"
        ARTLESS=true
    else
        [ ! "$SILENT" ] && echo "kunst: cover found online"
        curl -o "$COVER" -s "$IMG_URL"
        ARTLESS=false
    fi
}

find_album_art(){
    # Check if the user wants to get the album art from the internet,
    # regardless if the curent song has an embedded album art or not
    if [ "$ONLINE_ALBUM_ART" == true ];then
        [ ! "$SILENT" ] && echo "kunst: getting cover from internet"
        get_cover_online
        return
    fi

    # Extract the album art from the mp3 file and dont show the messsy
    # output of ffmpeg
    ffmpeg -i "$MUSIC_DIR$(mpc current -f %file%)" "$COVER" -y &> /dev/null

    # Get the status of the previous command
    STATUS=$?

    # Check if the file has a embbeded album art
    if [ "$STATUS" -eq 0 ];then
        [ ! "$SILENT" ] && echo "kunst: extracted album art"
        ARTLESS=false
    else
        DIR="$MUSIC_DIR$(dirname "$(mpc current -f %file%)")"
        [ ! "$SILENT" ] && echo "kunst: inspecting $DIR"

        # Check if there is an album cover/art in the folder.
        # Look at issue #9 for more details
        for CANDIDATE in "$DIR/cover."{png,jpg}; do
            if [ -f "$CANDIDATE" ]; then
                STATUS=0
                ARTLESS=false
                convert "$CANDIDATE" $COVER &> /dev/null
                [ ! "$SILENT" ] && echo "kunst: found cover.png"
            fi
        done
    fi

    if [ "$STATUS" -ne 0 ];then
        [ ! "$SILENT" ] && echo "error: file does not have an album art"
        get_cover_online
    fi
}


update_cover() {
    find_album_art

    if [ "$ARTLESS" == false ]; then
        convert "$COVER" -resize "$SIZE" "$COVER" &> /dev/null
        [ ! "$SILENT" ] && echo "kunst: resized album art to $SIZE"
    fi
}

pre_exit() {
    # Get the proccess ID of kunst and kill it.
    # We are dumping the output of kill to /dev/null
    # because if the user quits sxiv before they
    # exit kunst, an error will be shown
    # from kill and we dont want that
    kill -9 "$(cat /tmp/kunst.pid)" &>/dev/null
}

main() {
    DEPENDENCIES=(convert bash ffmpeg mpc jq mpd)
    for DEPENDENCY in "${DEPENDENCIES[@]}"; do
        type -p "$DEPENDENCY" &>/dev/null || {
            echo "error: Could not find '${DEPENDENCY}', is it installed?" >&2
            exit 1
        }
    done

    [ "$KUNST_MUSIC_DIR" != "" ] && MUSIC_DIR="$KUNST_MUSIC_DIR"
    [ "$KUNST_SIZE" != "" ] && SIZE="$KUNST_SIZE"

    # Flag to run some commands only once in the loop
    FIRST_RUN=true

    while true; do
        update_cover

        if [ "$ARTLESS" == true ];then
            # Decode the base64 encoded image and save it
            echo "$MUSIC_NOTE" | base64 --decode > "$COVER"
        fi

        if [ ! "$SILENT" ];then
            echo "kunst: swapped album art to $(mpc current)"
            printf '%*s\n' "${COLUMNS:-$(tput cols)}" '' | tr ' ' -
        fi

        if [ "$FIRST_RUN" != true ] && [ "$NOTIFICATION" == true ]; then
            TITLE=$( mpc current --format "[%title%]" )
            if [ "$TITLE" != "" ]; then
                ALBUM=$( mpc current --format "[%album%]" )
                ARTIST=$( mpc current --format "[%artist%]" )
                if [ "$ALBUM" = "$TITLE" ]; then
                    notify-send -u low -a "Now Playing" " $TITLE" "by $ARTIST" -i "$COVER"
                else
                    notify-send -u low -a "Now Playing" " $TITLE" "from $ALBUM by $ARTIST" -i "$COVER"
                fi
            else
                notify-send -u low -a "Now Playing" " $( mpc current --format '[%file%]' )" "" -i "$COVER"
            fi
        fi

        if [ "$FIRST_RUN" == true ]; then
            FIRST_RUN=false
            # Save the process ID
            echo $! >/tmp/kunst.pid
        fi

        # Waiting for an event from mpd; next/previous
        # this is lets kunst use less CPU :)
        # we don't necessarily need to update album art when
        # the song pauses/plays, only when it changes,
        # so we keep track of the current song and compare it
        # on every player event update
        CURRENT_SONG=$( mpc status | head -1 )
        while true; do
            mpc idle player &>/dev/null && (mpc status | grep "\[playing\]" &>/dev/null) && [ "$CURRENT_SONG" != "$( mpc status | head -1 )" ] && break
        done
        [ ! "$SILENT" ] && echo "kunst: received event from mpd"
    done
}

trap pre_exit EXIT
main
