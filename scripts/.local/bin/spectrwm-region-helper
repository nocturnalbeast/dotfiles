#!/usr/bin/env bash

# paths to config files
POLYBAR_CONFIG_PATH="$XDG_CONFIG_HOME/polybar/config"
SPECTRWM_CONFIG_PATH="$XDG_CONFIG_HOME/spectrwm/spectrwm.conf"

# have an array where we'll be putting those lines to insert in the spectrwm config
declare -a REGION_LINES

# then get the resolution lines into another array
mapfile -t RESOLUTIONS < <( xdpyinfo | awk '/dimensions/{print $2}' )

# check if disable_padding option is set, in which case we don't need to reserve space for polybar
if [ "$1" == "disable_padding" ]; then
    IDX_D=1
    for RESOLUTION in "${RESOLUTIONS[@]}"; do
        REGION_LINES+=("region = screen[$((IDX_D++))]:${RESOLUTION}+0+0")
    done
else
    # get the height reserved for the polybar instance
    BAR_HEIGHT=$(( "$( sed -n "s/^[ ]*bar-height[ ]*=[ ]*\([0-9]*\)[ ]*$/\1/p" "$POLYBAR_CONFIG_PATH" )" + "$( sed -n "s/^[ ]*vert-margin[ ]*=[ ]*\([0-9]*\)[ ]*$/\1/p" "$POLYBAR_CONFIG_PATH" )" ))
    # convert the data above into some entries that we can replace in the spectrwm config file
    for IDX in "${!RESOLUTIONS[@]}"; do
        RES_HEIGHT="$( echo "${RESOLUTIONS[$IDX]}" | cut -f 2 -d 'x' )"
        RES_WIDTH="$( echo "${RESOLUTIONS[$IDX]}" | cut -f 1 -d 'x' )"
        ALLOWED_HEIGHT="$(( $RES_HEIGHT - $BAR_HEIGHT ))"
        SCREEN_IDX="$(( $IDX + 1 ))"
        REGION_LINES+=("region = screen[${SCREEN_IDX}]:${RES_WIDTH}x${ALLOWED_HEIGHT}+0+${BAR_HEIGHT}")
    done
fi

# replace them in the spectrwm config file
REPLACE_LINENR="$( grep -n "^[ ]*region[ ]*=[ ]*screen\[[0-9]*\]:.*$" "$SPECTRWM_CONFIG_PATH" | cut -d : -f 1 | head -1 )"
sed -i '/^[ ]*region[ ]*=[ ]*screen\[[0-9]*\]:.*$/d' "$SPECTRWM_CONFIG_PATH"
for (( IDX=${#REGION_LINES[@]}-1 ; IDX>=0 ; IDX-- )) ; do
    TEMP_FILE="$( mktemp )"
    awk -v n="$REPLACE_LINENR" -v s="${REGION_LINES[IDX]}" 'NR == n {print s} {print}' "$SPECTRWM_CONFIG_PATH" > "$TEMP_FILE"
    mv "$TEMP_FILE" "$SPECTRWM_CONFIG_PATH"
done

# now restart spectrwm so that it reloads the configuration file
kill -1 "$( pidof spectrwm )"
