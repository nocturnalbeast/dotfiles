"""Source management: clone-if-missing, pull --ff-only, HEADs."""

from __future__ import annotations

import subprocess
from dataclasses import dataclass
from pathlib import Path

from theme.helpers.logio import action
from theme.state import CACHE_DIR

SOURCES_DIR = CACHE_DIR / "sources"


class SourceError(RuntimeError):
    pass


@dataclass
class SourceResult:
    path: Path
    head: str
    cloned: bool
    pulled: bool
    pull_warning: str | None = None


def _git(cwd: Path | None, *args: str) -> subprocess.CompletedProcess:
    return subprocess.run(
        ["git", *args],
        cwd=str(cwd) if cwd else None,
        capture_output=True,
        text=True,
    )


def ensure_source(
    key: str,
    url: str,
    offline: bool = False,
    dry_run: bool = False,
    family: str = "",
) -> SourceResult:
    """Clone if missing → pull --ff-only → HEAD.

    Offline + missing clone is a hard error; pull failure downgrades to
    a warning when a usable clone exists; dry_run reports only. Cache
    dirs are namespaced by family — same-key clones (colloid gtk vs
    icons) would shadow each other; flat clones migrate on access.
    """
    path = SOURCES_DIR / key
    if family:
        namespaced = SOURCES_DIR / family / key
        if not namespaced.exists() and path.exists():
            if (path / ".git").exists():
                namespaced.parent.mkdir(parents=True, exist_ok=True)
                path.rename(namespaced)
        path = namespaced
    cloned = pulled = False
    warning = None

    if not path.exists():
        if offline:
            raise SourceError(
                f"{key}: clone missing under --offline (warm the cache first)"
            )
        if dry_run:
            return SourceResult(path, "unknown", False, False)
        action(f"cloning {key}…")
        r = _git(None, "clone", url, str(path))
        if r.returncode != 0:
            raise SourceError(f"{key}: clone failed: {r.stderr.strip()[:300]}")
        cloned = True
    elif not dry_run and not offline:
        r = _git(path, "pull", "--ff-only")
        if r.returncode != 0:
            warning = f"{key}: pull failed ({r.stderr.strip()[:120]})"
        else:
            pulled = True

    if dry_run and not path.exists():
        return SourceResult(path, "unknown", False, False)
    head = _git(path, "rev-parse", "HEAD")
    if head.returncode != 0:
        raise SourceError(f"{key}: cannot read HEAD")
    return SourceResult(path, head.stdout.strip(), cloned, pulled, warning)
