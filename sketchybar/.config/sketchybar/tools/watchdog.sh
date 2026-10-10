#!/bin/sh
# sketchybar watchdog - auto-recover a wedged daemon (AGENT.md fact 21).
#
# Failure mode: the daemon's mach endpoint stops answering, so
# `sketchybar --query bar` blocks forever. launchd runs this every 10 min
# (com.user.sketchybar-watchdog); each run probes under an 8s timeout and
# TWO consecutive failures trigger `brew services restart sketchybar`
# (two strikes bounds recovery at <=20 min while riding out transient
# system stalls).
#
#   --once   purely observational single probe: prints healthy|hung,
#            exits 0|1, never touches counter/lock/log.
#
# Recovery is ALWAYS `brew services restart` - never a second daemon
# alongside the service (mach-port collision, fact 2).

set -u

CACHE="$HOME/.cache/sketchybar"
FAIL="$CACHE/watchdog.failures"
LOG="$CACHE/watchdog.log"
LOCK="$CACHE/watchdog.lock"
SB=/opt/homebrew/bin/sketchybar
BREW=/opt/homebrew/bin/brew

# --- resolve a timeout binary (probe safety net) -----------------------
TIMEOUT_BIN=""
if ls /opt/homebrew/bin/timeout > /dev/null 2>&1; then
    TIMEOUT_BIN=/opt/homebrew/bin/timeout
elif ls /opt/homebrew/bin/gtimeout > /dev/null 2>&1; then
    TIMEOUT_BIN=/opt/homebrew/bin/gtimeout
else
    echo "watchdog: no timeout binary (/opt/homebrew/bin/timeout or gtimeout) - skipping." >&2
    exit 0
fi

probe() {
    "$TIMEOUT_BIN" 8 "$SB" --query bar > /dev/null 2>&1
}

# --- --once: one observational probe, no state mutation ----------------
if [ "${1:-}" = "--once" ]; then
    if probe; then
        echo healthy
        exit 0
    fi
    echo hung
    exit 1
fi

# --- concurrency guard: skip if a lock <5 min old is held --------------
mkdir -p "$CACHE"
if [ -f "$LOCK" ]; then
    lock_mtime=$(/usr/bin/stat -f %m "$LOCK" 2> /dev/null || echo 0)
    age=$(($(date +%s) - lock_mtime))
    if [ "$age" -lt 300 ]; then
        echo "watchdog: lock held (${age}s old) - skipping run." >&2
        exit 0
    fi
fi
printf '%s\n' "$$" > "$LOCK"
trap 'rm -f "$LOCK"' EXIT
trap 'rm -f "$LOCK"; exit 1' INT TERM

# --- probe cycle --------------------------------------------------------
if probe; then
    rm -f "$FAIL" # healthy: zero the consecutive-failure counter
    exit 0
fi

failures=$(cat "$FAIL" 2> /dev/null || echo 0)
case "$failures" in *[!0-9]* | "") failures=0 ;; esac
failures=$((failures + 1))

if [ "$failures" -ge 2 ]; then
    echo "$(date '+%F %T') watchdog: restarting wedged sketchybar" >> "$LOG"
    "$BREW" services restart sketchybar > /dev/null 2>&1
    rm -f "$FAIL" # reset counter after action
else
    printf '%s\n' "$failures" > "$FAIL"
fi
exit 0
