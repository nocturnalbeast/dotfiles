#!/usr/bin/env bash

# Source: mpdmenu from https://github.com/MaryHal/dmenu-suite
# reworked some stuff, added dependency checking script and some styling

# lyrics from python-lyricwikia package
DEPENDENCIES=(mpd mpc lyrics)
for DEPENDENCY in "${DEPENDENCIES[@]}"; do
    type -p "$DEPENDENCY" &>/dev/null || {
        echo "error: Could not find '${DEPENDENCY}', is it installed?" >&2
        exit 1
    }
done

MENU="$HOME/.config/scripts/dmenu-helper.sh run_menu"

MUSIC_DIR="$XDG_MUSIC_DIR"
# current image cover art location
COVER="/tmp/mpd_albumart.jpg"
# editor command
E_COMMAND="st -e nvim"

# get the states from mpc
STATES=$( mpc --format "" | sed -rn 's/.*repeat: (on|off)[ ]+random: (on|off)[ ]+single: (on|off)[ ]+consume: (on|off).*/\1 \2 \3 \4/p' )
REPEAT_STATE=$( echo "$STATES" | cut -f 1 -d ' ' )
RANDOM_STATE=$( echo "$STATES" | cut -f 2 -d ' ' )
SINGLE_STATE=$( echo "$STATES" | cut -f 3 -d ' ' )
CONSUME_STATE=$( echo "$STATES" | cut -f 4 -d ' ' )

# menu options
MAIN_MENU="契 Play\n Pause\n栗 Stop\n玲 Previous\n怜 Next\n Seek\n菱 Replay\n Select\n Current\n Add folder\n Add songs\n蘿 Playlist\n列 Random [$RANDOM_STATE]\n凌 Repeat [$REPEAT_STATE]\n Single [$SINGLE_STATE]\n裸 Consume [$CONSUME_STATE]\n Lyrics\n勒 Rescan"

ACTION=$( $MENU "   " "$MAIN_MENU" )
case "$ACTION" in
    '契 Play')
        mpc -q toggle
        ;;
    ' Pause')
        mpc -q toggle
        ;;
    '栗 Stop')
        mpc -q stop
        ;;
    '玲 Previous')
        mpc -q prev
        ;;
    '怜 Next')
        mpc -q next
        ;;
    ' Seek')
        SEEK_OPTS="0%\n10%\n20%\n30%\n40%\n50%\n60%\n70%\n80%\n90%"
        POSITION=$( $MENU "  Seek: " "$SEEK_OPTS" )
        if [[ -n "$POSITION" ]]; then
            mpc -q seek "$POSITION"
        fi
        ;;
    '菱 Replay')
        mpc -q stop
        mpc -q play
        ;;
    ' Select')
        CANDIDATES=$( mpc playlist --format '%position%  [%title%|%file%]' )
        SELECTION=$( $MENU "  Song:" "$CANDIDATES" )

        # only select song if not in consume ("playback queue") mode
        if [[ "$CONSUME_STATE" != "on" ]]; then
            if [[ -n "$SELECTION" ]]; then
                NUM_SONG=$( awk '{print $1}' <<< "$SELECTION" )
                mpc -q play "$NUM_SONG"
            fi
        fi
        ;;
    ' Current')
        if [ "$( mpc status | wc -l )" != "1" ]; then
            TITLE=$( mpc current --format "[%title%]" )
            if [ "$TITLE" != "" ]; then
                ALBUM=$( mpc current --format "[%album%]" )
                ARTIST=$( mpc current --format "[%artist%]" )
                if [ "$ALBUM" = "$TITLE" ]; then
                    notify-send "Playing $TITLE" "by <b>$ARTIST</b>" -i "$COVER"
                else
                    notify-send "Playing $TITLE" "from <i>$ALBUM</i> by <b>$ARTIST</b>" -i "$COVER"
                fi
            else
                notify-send "Playing $( mpc current --format '[%file%]' )" -i "$COVER"
            fi
        else
            notify-send "Music: No playback"
        fi
        ;;
    ' Add folder')
        pushd $MUSIC_DIR > /dev/null
        MUSIC_DIR_LIST=$( find . -type d | sed -e 's!^\./!!' )
        popd > /dev/null
        QUERY=$( $MENU "  Folder:" "$MUSIC_DIR_LIST" )

        if [[ -n "$QUERY" ]]; then
            mpc ls "$QUERY" | mpc -q add
        fi
        ;;
    ' Add songs')
        FLTR_OPTS="any\nartist\nalbum\ntitle\ntrack\nname\ngenre\ndate\ncomposer\nperformer\ncomment\ndisc\nfilename"
        FLTR_TYPE=$( $MENU "  Filter type:" "$FLTR_OPTS" )
        [[ -z "$FLTR_TYPE" ]] && exit
        QUERY=$( $MENU "  Query [$FLTR_TYPE]:" "" )

        FLTR_LIST=$( mpc search "$FLTR_TYPE" "$QUERY" )

        COUNT=0
        SELECTION="a"
        while [[ -n "$SELECTION" ]]; do
            SELECTION=$( $MENU "  Results [$COUNT]:" "$FLTR_LIST" )
            echo " $SELECTION"
            if [[ -n "$SELECTION" ]]; then
                mpc -q add "$SELECTION"
                ((COUNT++))
            fi
        done
        ;;
    '蘿 Playlist')
        PLIST_OPTS="螺 Add all available\n羅 Remove a song\n裸 Clear\n祝 Load\n Save\n Delete"
        ACTION=$( $MENU "Option: " "$PLIST_OPTS" )
        case "$ACTION" in
            '螺 Add all available')
                mpc -q update
                mpc ls | mpc -q add
                ;;
            '羅 Remove a song')
                SELECTION="a"
                while [[ -n "$SELECTION" ]]; do
                    CANDIDATES=$( mpc playlist --format '%position%  [%title%|%file%]' )
                    SELECTION=$( $MENU "  Song:" "$CANDIDATES" )

                    if [[ -n "$SELECTION" ]]; then
                        NUM_SONG=$(awk '{print $1}' <<< "$SELECTION")
                        mpc -q del "$NUM_SONG"
                    fi
                done
                ;;
            '裸 Clear')
                mpc -q clear
                notify-send "Music: Cleared playlist"
                ;;
            '祝 Load')
                PLAYLIST=$( $MENU "  Load: " "$( mpc lsplaylists )" )
                if [[ -n "PLAYLIST" ]]; then
                    mpc -q stop
                    mpc -q clear
                    mpc -q load "$PLAYLIST"
                    notify-send "Music: Playlist loaded" "$PLAYLIST"
                fi
                ;;
            ' Save')
                PLAYLIST=$( $MENU "  Save: " "$( mpc lsplaylists )" )
                if [[ -n "$PLAYLIST" ]]; then
                    mpc save "$PLAYLIST"
                    notify-send "Music: Playlist saved" "$PLAYLIST"
                fi
                ;;
            ' Delete')
                PLAYLIST=$( $MENU "  Delete: " "$( mpc lsplaylists )" )
                if [[ -n "$PLAYLIST" ]]; then
                    mpc rm "$PLAYLIST"
                    notify-send "Music: Playlist deleted" "$PLAYLIST"
                fi
                ;;
        esac
        ;;
    '列 Random ['*)
        mpc -q random
        ;;
    '凌 Repeat ['*)
        mpc -q repeat
        ;;
    ' Single ['*)
        mpc -q single
        ;;
    '裸 Consume ['*)
        mpc -q consume
        ;;
    ' Lyrics')
        SONG=$( mpc current )
        LYRICS_FILE="$HOME/.lyrics/$SONG.txt"

        if [[ ! -f "$LYRICS_FILE" ]]; then
            HOW=$( $MENU "  Create lyrics? " "auto\nmanual" )
            if [[ "$HOW" == "auto" ]]; then
                lyrics "$( mpc current --format "[%artist%]" )" "$( mpc current --format "[%title%]" )" >> "$LYRICS_FILE"
                if [[ $? -ne 0 ]]; then
                    notify-send "Lyrics not found for the song:" "$SONG"
                else
                    notify-send "Saved lyrics file for the song:" "$SONG at <u>$LYRICS_FILE</u>."
                fi
            else
                touch "$LYRICS_FILE"
                $E_COMMAND "$LYRICS_FILE" &
                notify-send "Created lyrics file for the song:" "$SONG at <u>$LYRICS_FILE</u>."
            fi
        else
            $E_COMMAND "$LYRICS_FILE" &
        fi
        ;;
    '勒 Rescan')
        notify-send "Music: Updating database"
        mpc -q update
        # apparently, since the command above doesn't update mopidy we run mopidy update
        mopidy local scan 2>&1 >/dev/null
        ;;
esac
