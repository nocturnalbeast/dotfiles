"""Watch daemon: inotify on the wallpaper tracker, debounce, latest-wins coalescing, generate→apply chain under one flock."""

from __future__ import annotations

import os
import select
import subprocess
import sys
import time
from pathlib import Path

from theme.helpers.logio import action, fail, warn
from theme.state import CACHE_DIR
from theme.state import STATE_DIR, mutation_lock

HEARTBEAT = STATE_DIR / "watch.heartbeat"
DEBOUNCE_SECONDS = 0.3
HEARTBEAT_INTERVAL_SECONDS = 30.0


def resolve_tracker(tracker_path: str) -> str | None:
    p = Path(os.path.expanduser(tracker_path))
    if p.is_symlink():
        return str(p.resolve())
    if p.is_file():
        return p.read_text().strip()
    return None


def _drain_pending(stdout) -> int:
    """Drain queued inotify lines without blocking; returns count drained (latest-wins coalescing)."""
    drained = 0
    while True:
        ready, _, _ = select.select([stdout], [], [], 0)
        if not ready:
            break
        line = stdout.readline()
        if not line:
            break
        drained += 1
    return drained


DAEMON_LOCK = CACHE_DIR / "watch.lock"


def watch_daemon(tracker: str, on_change: list[str], sync: bool = True) -> None:
    """Single long-lived daemon (supervised by wm/autostart); holds an exclusive flock for its lifetime — a second instance exits."""
    import fcntl
    from theme.helpers import logio

    DAEMON_LOCK.parent.mkdir(parents=True, exist_ok=True)
    _daemon_fd = os.open(DAEMON_LOCK, os.O_CREAT | os.O_WRONLY, 0o644)
    try:
        fcntl.flock(_daemon_fd, fcntl.LOCK_EX | fcntl.LOCK_NB)
    except BlockingIOError:
        fail("another watch daemon holds the lock — exiting")
        sys.exit(0)

    # force plain append-only output — in-process applies must not spawn spinners/colors
    logio.configure(verbosity=0, progress=False)

    tracker_path = Path(os.path.expanduser(tracker))
    parent = tracker_path.parent
    action(f"watch monitoring {parent} for {tracker_path.name}")

    if (
        not subprocess.run(["which", "inotifywait"], capture_output=True).returncode
        == 0
    ):
        fail("inotifywait not found — daemon refusing to start")
        sys.exit(1)

    proc = subprocess.Popen(
        [
            "inotifywait",
            "-m",
            "-e",
            "create",
            "-e",
            "moved_to",
            "-e",
            "attrib",
            "--format",
            "%e",
            str(parent),
        ],
        stdout=subprocess.PIPE,
        stderr=subprocess.DEVNULL,
        text=True,
    )
    stdout = proc.stdout
    if stdout is None:
        fail("inotifywait produced no stdout — daemon cannot watch")
        sys.exit(1)

    STATE_DIR.mkdir(parents=True, exist_ok=True)

    # heartbeat is per-event AND periodic — events-only makes quiet sessions look stale to doctor's liveness probe
    import threading

    def _heartbeat_loop():
        while True:
            time.sleep(HEARTBEAT_INTERVAL_SECONDS)
            HEARTBEAT.write_text(f"{time.time()}\n")

    hb_thread = threading.Thread(target=_heartbeat_loop, daemon=True)
    hb_thread.start()

    last_processed: str | None = None
    try:
        while True:
            line = stdout.readline()
            if not line:
                break

            time.sleep(DEBOUNCE_SECONDS)

            HEARTBEAT.write_text(f"{time.time()}\n")

            resolved = resolve_tracker(tracker)
            if not resolved:
                warn("tracker missing/invalid — skipping")
                continue

            # same-value skip: `background restore` re-creates the tracker symlink for the
            # same image — without this check apply → awesome restart → rc.lua autostart →
            # symlink event would loop the chain forever.
            if resolved == last_processed:
                action(
                    f"{time.strftime('%H:%M:%S')} · symlink event, same wallpaper — skipping"
                )
                continue
            last_processed = resolved

            action(
                f"{time.strftime('%H:%M:%S')} · wallpaper changed: {Path(resolved).name}"
            )

            if not sync:
                action(f"{time.strftime('%H:%M:%S')} · sync disabled — logging only")
                continue

            try:
                with mutation_lock(timeout=5.0):
                    from theme.generate import generate
                    from theme.registry import REGISTRY

                    logio.RUN.records = []
                    from theme.config import resolve as _resolve

                    palette = generate(
                        resolved, soft_tui=True, engines=_resolve().get("engines")
                    )
                    for target in on_change:
                        if target in REGISTRY:
                            component = REGISTRY[target]
                            component.apply(_make_ctx(palette))
                        else:
                            warn(f"unknown on_change target: {target}")
            except Exception as e:
                fail(
                    f"chain failed: {e} — event NOT dropped, "
                    "will retry on next wallpaper change"
                )

            coalesced = _drain_pending(stdout)
            if coalesced:
                action(
                    f"{time.strftime('%H:%M:%S')} · coalesced {coalesced} queued event(s) — "
                    "latest-wins, tracker state is current"
                )

    except KeyboardInterrupt:
        pass
    finally:
        proc.terminate()
        proc.wait()


def _make_ctx(palette: dict) -> "Context":
    from theme.config import resolve
    from theme.resources.base import Context

    config = resolve()
    config["palette"] = palette
    return Context(config=config, palette=palette)
