#!/bin/bash

# paths to config files
POLYBAR_CONFIG_PATH="$XDG_CONFIG_HOME/polybar/config"
SPECTRWM_CONFIG_PATH="$XDG_CONFIG_HOME/spectrwm/spectrwm.conf"

# get the resolution of all the monitors first
IFS=$'\n'
ALL_RESOLUTIONS=$( xdpyinfo | awk '/dimensions/{print $2}' )
unset IFS

# next, get the height reserved for the polybar instance
BAR_HEIGHT=$(( "$( sed -n "s/^[ ]*bar-height[ ]*=[ ]*\([0-9]*\)[ ]*$/\1/p" "$POLYBAR_CONFIG_PATH" )" + "$( sed -n "s/^[ ]*vert-margin[ ]*=[ ]*\([0-9]*\)[ ]*$/\1/p" "$POLYBAR_CONFIG_PATH" )" ))

# convert the data above into some entries that we can replace in the spectrwm config file
REGION_LINES=()
for IDX in "${!ALL_RESOLUTIONS[@]}"; do
    RES_HEIGHT="$( echo "${ALL_RESOLUTIONS[$IDX]}" | cut -f 2 -d 'x' )"
    RES_WIDTH="$( echo "${ALL_RESOLUTIONS[$IDX]}" | cut -f 1 -d 'x' )"
    ALLOWED_HEIGHT="$(( $RES_HEIGHT - $BAR_HEIGHT ))"
    SCREEN_IDX="$(( $IDX + 1 ))"
    REGION_LINES+=("region = screen[${SCREEN_IDX}]:${RES_WIDTH}x${ALLOWED_HEIGHT}+0+${BAR_HEIGHT}")
done

# replace them in the spectrwm config file
REPLACE_LINENR="$( grep -n "^[ ]*region[ ]*=[ ]*screen\[[0-9]*\]:.*$" "$SPECTRWM_CONFIG_PATH" | cut -d : -f 1 | head -1 )"
sed -i '/^[ ]*region[ ]*=[ ]*screen\[[0-9]*\]:.*$/d' "$SPECTRWM_CONFIG_PATH"
for (( IDX=${#REGION_LINES[@]}-1 ; IDX>=0 ; IDX-- )) ; do
    TEMP_FILE="$( mktemp )"
    awk -v n="$REPLACE_LINENR" -v s="${REGION_LINES[IDX]}" 'NR == n {print s} {print}' "$SPECTRWM_CONFIG_PATH" > "$TEMP_FILE"
    mv "$TEMP_FILE" "$SPECTRWM_CONFIG_PATH"
done

# next, figure out the keybinding for restarting spectrwm so we can simulate it and trigger reload of it's config file
KEYBINDING="$( sed -n "s/^[ ]*bind\[restart\][ ]*=[ ]*\(.*\)[ ]*$/\1/p" ~/.config/spectrwm/spectrwm.conf )"
if $( echo "$KEYBINDING" | grep -q "MOD" ); then
    MODKEY="$( sed -n "s/^[ ]*modkey[ ]*=[ ]*\(.*\)[ ]*$/\1/p" ~/.config/spectrwm/spectrwm.conf )"
    if [ "$MODKEY" = "Mod1" ]; then
        MODKEY="alt"
    elif [ "$MODKEY" = "Mod4" ]; then
        MODKEY="super"
    fi
    KEYBINDING="$( echo "$KEYBINDING" | sed "s/MOD/$MODKEY/" )"
fi
xdotool key "$KEYBINDING"
