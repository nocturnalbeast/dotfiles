#!/usr/bin/env sh

# source profile files
for FILE in "/etc/profile" "$HOME/.profile" "/etc/xprofile" "$HOME/.xprofile"; do
    if [ -f "$FILE" ]; then
        . $FILE
    fi
done

# load resource files
for FILE in "/etc/X11/Xresources" "${XDG_CONFIG_HOME:-"$HOME/.config"}/X11/xresources.d" "${XDG_CONFIG_HOME:-"$HOME/.config"}/X11/xresources" "$HOME/.Xresources"; do
    if [ -f "$FILE" ]; then
        xrdb -merge $FILE
    elif [ -d "$FILE" ]; then
        for SUB_FILE in "$FILE"/*; do
            [ -f "$SUB_FILE" ] && xrdb -merge "$SUB_FILE"
        done
    fi
done

# load keymaps using xkbmap
if type setxkbmap >/dev/null 2>&1; then
    for FILE in "/etc/X11/Xkbmap" "$HOME/.Xkbmap"; do
        if [ -f "$FILE" ]; then
            setxkbmap "$( cat "$FILE" )"
            XKB_IN_USE=yes
        fi
    done
fi

# load keymaps using xmodmap if not using xkbmap
if type xmodmap >/dev/null 2>&1; then
    if [ -z "$XKB_IN_USE" ]; then
        for FILE in "/etc/X11/Xmodmap" "$HOME/.Xmodmap"; do
            if [ -f "$FILE" ]; then
                xmodmap "$FILE"
            fi
        done
    fi
fi
unset XKB_IN_USE

# source all system xinitrc shell scripts
if [ -d /etc/X11/xinit/xinitrc.d ]; then
    for FILE in /etc/X11/xinit/xinitrc.d/* ; do
        if [ -x "$FILE" ] && [ ! -d "$FILE" ]; then
            . "$FILE"
        fi
    done
fi

# launch with dbus if it exists and if there is no environment variable defined to disable it
if type dbus-launch >/dev/null 2>&1 && [ "$DBUS_LAUNCH" != "false" ]; then
    exec dbus-launch $@
else
    exec $@
fi
