"""Per-member stamps + the mutation lock."""

from __future__ import annotations

import fcntl
import json
import os
import time
from contextlib import contextmanager
from pathlib import Path
from typing import Any, Iterator

CACHE_DIR = Path(os.environ.get("XDG_CACHE_HOME", Path.home() / ".cache")) / "theming"
LOCK_PATH = CACHE_DIR / "lock"
STATE_DIR = (
    Path(os.environ.get("XDG_STATE_HOME", Path.home() / ".local/state")) / "theming"
)
GROUPS = ("gui", "qt", "wm", "tui", "macos")


class ThemeBusy(RuntimeError):
    pass


@contextmanager
def mutation_lock(timeout: float = 60.0) -> Iterator[None]:
    """Whole-mutation exclusive lock, builds included."""
    CACHE_DIR.mkdir(parents=True, exist_ok=True)
    fd = os.open(LOCK_PATH, os.O_CREAT | os.O_WRONLY, 0o644)
    deadline = time.monotonic() + timeout
    try:
        while True:
            try:
                fcntl.flock(fd, fcntl.LOCK_EX | fcntl.LOCK_NB)
                break
            except BlockingIOError:
                if time.monotonic() >= deadline:
                    raise ThemeBusy(
                        "another theme operation is running (flock timeout)"
                    )
                time.sleep(0.25)
        yield
    finally:
        os.close(fd)


def stamp_path(group: str) -> Path:
    return STATE_DIR / f"{group}.json"


def read_stamp(group: str) -> dict[str, Any]:
    """Corrupt ≡ missing."""
    path = stamp_path(group)
    if not path.exists():
        return {}
    try:
        data = json.loads(path.read_text())
        return data if isinstance(data, dict) else {}
    except (json.JSONDecodeError, OSError):
        return {}


def read_member(group: str, member: str) -> dict[str, Any]:
    return read_stamp(group).get(member, {})


def write_stamp(group: str, data: dict[str, Any]) -> None:
    STATE_DIR.mkdir(parents=True, exist_ok=True)
    tmp = stamp_path(group).with_suffix(".json.tmp")
    tmp.write_text(json.dumps(data, indent=2, sort_keys=True) + "\n")
    os.replace(tmp, stamp_path(group))


def update_member(
    group: str,
    member: str,
    record: dict[str, Any],
) -> None:
    data = read_stamp(group)
    data[member] = record
    write_stamp(group, data)


def commit_members(records: list[tuple[str, str, dict[str, Any]]]) -> None:
    """Batch stamp commit: one read+write per group file — parallel members cannot race it."""
    by_group: dict[str, dict[str, Any]] = {}
    for group, member, record in records:
        by_group.setdefault(group, {})[member] = record
    for group, members in by_group.items():
        data = read_stamp(group)
        data.update(members)
        write_stamp(group, data)


def make_record(
    config_hash: str,
    built_config_hash: str,
    repo_heads: dict[str, str],
    surfaces: dict[str, dict[str, str]],
) -> dict[str, Any]:
    import datetime

    return {
        "config_hash": config_hash,
        "built_config_hash": built_config_hash,
        "repo_heads": repo_heads,
        "applied_at": datetime.datetime.now().isoformat(timespec="seconds"),
        "surfaces": surfaces,
    }
