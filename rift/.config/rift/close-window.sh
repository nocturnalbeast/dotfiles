#!/bin/sh
# close-window.sh - meh+Q: aerospace `close --quit-if-last-window` parity.
# If the focused window is its app's LAST window → quit the app;
# otherwise → rift closes just the window (Command-W semantics).
#
# Quit ladder (some apps reject the AppleScript quit event - e.g. kitty):
#   1. AppleScript 'tell application id X to quit' (standard, graceful)
#   2. SIGTERM to the app's pid (from rift window info)
#   3. fall back to rift close-window
#
# Counts windows GLOBALLY via `query workspaces` - `query windows` is
# scoped to the current macOS space and miscounts multi-workspace apps.
#
# Trace: /tmp/close-window.log (one line per invocation + decision)
set -eu

CLI=/opt/homebrew/bin/rift-cli
JQ=/usr/bin/jq
LOG=/tmp/close-window.log

log() { printf '%s %s\n' "$(date '+%F %T')" "$*" >> "$LOG"; }

win_json=$($CLI query workspaces 2> /dev/null || echo "[]")

app=$(printf '%s' "$win_json" | $JQ -r '
	[.[].windows[]] | map(select(.is_focused == true)) | first
	| if . == null then empty else (.bundle_id // empty) end' 2> /dev/null || true)

if [ -z "$app" ]; then
    log "no focused app resolved - plain close"
    $CLI execute window close 2> /dev/null || true
    exit 0
fi

count=$(printf '%s' "$win_json" | $JQ --arg a "$app" \
    '[.[].windows[] | select(.bundle_id == $a)] | length' 2> /dev/null || echo 0)

if [ "$count" -gt 1 ]; then
    log "app=$app count=$count - close single window"
    $CLI execute window close 2> /dev/null || true
    exit 0
fi

# last window of the app → quit the whole app
log "app=$app count=1 - quitting app"
if /usr/bin/osascript -e "tell application id \"$app\" to quit" 2>> "$LOG"; then
    log "app=$app quit via AppleScript"
    exit 0
fi

# AppleScript quit rejected - SIGTERM the app pid from rift's window info
pid=$(printf '%s' "$win_json" | $JQ -r --arg a "$app" \
    '[.[].windows[] | select(.bundle_id == $a)] | first | .id.pid' 2> /dev/null || true)
if [ -n "$pid" ] && kill -TERM "$pid" 2> /dev/null; then
    log "app=$app pid=$pid quit via SIGTERM"
    exit 0
fi

log "app=$app all quit paths failed - closing window instead"
$CLI execute window close 2> /dev/null || true
