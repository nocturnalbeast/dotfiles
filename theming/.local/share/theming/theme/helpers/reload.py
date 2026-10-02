"""Process side-effects: reloads, gsettings, xsetroot, caches."""

from __future__ import annotations

import shutil
import subprocess
from pathlib import Path

from theme.helpers.logio import action


def _run(cmd: list[str], check: bool = False) -> subprocess.CompletedProcess:
    return subprocess.run(cmd, capture_output=True, text=True, check=check)


def sighup_xsettingsd() -> bool:
    """SIGHUP reload — never kill/respawn. Returns alive-after."""
    r = _run(["pgrep", "-x", "xsettingsd"])
    if r.returncode != 0:
        return False
    _run(["pkill", "-HUP", "xsettingsd"])
    return True


def gsettings_set(schema: str, key: str, value: str) -> bool:
    r = _run(["gsettings", "set", schema, key, value])
    return r.returncode == 0


def gsettings_get(schema: str, key: str) -> str | None:
    r = _run(["gsettings", "get", schema, key])
    if r.returncode != 0:
        return None
    return r.stdout.strip().strip("'")


def xsetroot_cursor(theme: str, icons_dirs: list[Path]) -> bool:
    """S7 root-window cursor refresh."""
    if not shutil.which("xsetroot"):
        return False
    env_path = ":".join(str(p) for p in icons_dirs)
    import os

    env = dict(os.environ, XCURSOR_THEME=theme, XCURSOR_PATH=env_path)
    r = subprocess.run(
        ["xsetroot", "-cursor_name", "left_ptr"],
        capture_output=True,
        text=True,
        env=env,
    )
    return r.returncode == 0


def gtk_update_icon_cache(theme_dir: Path) -> bool:
    if not shutil.which("gtk-update-icon-cache"):
        return False
    r = _run(["gtk-update-icon-cache", "-f", "-t", str(theme_dir)])
    return r.returncode == 0


def fc_cache() -> bool:
    if not shutil.which("fc-cache"):
        return False
    _run(["fc-cache", "-f"])
    return True


def notify_reload(theme: str | None = None, style: str | None = None) -> None:
    """Best-effort visual feedback via notify-send when available."""
    if not shutil.which("notify-send"):
        return
    msg = "theme applied"
    if theme:
        msg = f"{theme} applied"
    if style:
        msg += f" · {style}"
    _run(["notify-send", "-u", "low", "theme", msg])


def report_restart_hint(lines: list[str]) -> None:
    if lines:
        action("restart required for: " + ", ".join(sorted(set(lines))))


def xrdb_merge(xresources: Path) -> bool:
    """W1 live merge; False when xrdb/X session absent."""
    import os

    if not shutil.which("xrdb") or not os.environ.get("DISPLAY"):
        return False
    _run(["xrdb", "-merge", str(xresources)])
    return True


def bspwm_apply_colors(script: Path) -> bool:
    if not shutil.which("bspc"):
        return False
    _run(["sh", str(script)])
    return True


def dunst_reload() -> bool:
    if not shutil.which("dunstctl"):
        return False
    _run(["dunstctl", "reload"])
    return True


def mako_reload() -> bool:
    if not shutil.which("makoctl"):
        return False
    _run(["makoctl", "reload"])
    return True


def awesome_restart() -> bool:
    """W2 reload: awesome re-reads xrdb on restart — MUST run after
    xrdb_merge and LAST overall."""
    if not shutil.which("awesome-client"):
        return False
    try:
        subprocess.run(
            ["awesome-client", "awesome.restart()"],
            capture_output=True,
            timeout=10,
        )
    except subprocess.TimeoutExpired:
        return False
    return True


def sketchybar_reload() -> bool:
    """sketchybar picks up colors_generated.lua on --reload."""
    if not shutil.which("sketchybar"):
        return False
    _run(["sketchybar", "--reload"])
    return True


def borders_relaunch(script: Path) -> bool:
    """Re-exec the generated borders.sh (idempotent: it pkills first)."""
    if not shutil.which("borders"):
        return False
    _run(["sh", str(script)])
    return True
