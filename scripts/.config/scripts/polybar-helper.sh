#!/bin/bash

bar_show_first() {
    polybar-msg -p $( pidof polybar | tr ' ' '\n' | sort | head -1 ) cmd show
}

bar_show_second() {
    polybar-msg -p $( pidof polybar | tr ' ' '\n' | sort -r | head -1 ) cmd show
}

bar_hide_first() {
    polybar-msg -p $( pidof polybar | tr ' ' '\n' | sort | head -1 ) cmd hide
}

bar_hide_second() {
    polybar-msg -p $( pidof polybar | tr ' ' '\n' | sort -r | head -1 ) cmd hide
}

bar_hide_all() {
    polybar-msg cmd hide
}

bar_hide_active() {
    polybar-msg -p $( xdotool search --sync --onlyvisible --class "Polybar" getwindowpid ) cmd hide
}

bar_toggle() {
    polybar-msg cmd toggle
}
