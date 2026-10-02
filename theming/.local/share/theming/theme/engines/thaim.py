"""thaim engine: thaimeleon 45-key Oklab palette → core + terminal; no contrast post-processing by design."""

from __future__ import annotations

import shutil
import subprocess
import tempfile
from pathlib import Path
from typing import Any

from ruamel.yaml import YAML

from theme.engines.base import (
    Engine,
    GenerationError,
    base24_to_core,
    complete_terminal,
)
from theme.helpers.logio import atomic_write

CACHE_BASE = Path(
    __import__("os").environ.get("XDG_CACHE_HOME", Path.home() / ".cache")
)
THAIM_CACHE_DIR = CACHE_BASE / "theming" / "thaimeleon"
THAIM_PINNED_VERSION = "0.1.2"

THAIM_SLOT_MAP = {
    "base00": "base",
    "base01": "surface",
    "base02": "overlay",
    "base03": "muted",
    "base04": "subtext",
    "base05": "text",
    "base06": "text",
    "base07": "text",
    "base08": "fg_red",
    "base09": "fg_yellow",
    "base0A": "fg_yellow",
    "base0B": "fg_green",
    "base0C": "fg_cyan",
    "base0D": "fg_blue",
    "base0E": "fg_magenta",
    "base0F": "fg_accent_1",
}

THAIM_FORCED_THRESHOLD = {"dark": 1.0, "light": 0.0}


def _configs() -> dict[str, Path]:
    THAIM_CACHE_DIR.mkdir(parents=True, exist_ok=True)
    paths: dict[str, Path] = {}
    for m, threshold in THAIM_FORCED_THRESHOLD.items():
        p = THAIM_CACHE_DIR / f"{m}.toml"
        atomic_write(
            p,
            (
                f"[main]\n"
                f"light_theme_threshold = {threshold}\n"
                f"write_to_cache = false\n"
                f"read_cache = false\n"
            ),
        )
        paths[m] = p
    return paths


def extract_thaimeleon(image: str) -> dict[str, dict[str, str]]:
    """Extract thaimeleon's full palette for both forced modes.

    Returns:
        {mode: palette45}; success is judged on exit code + parsed YAML, never stdout.
    """
    if not shutil.which("thaimeleon"):
        raise GenerationError("thaimeleon not found (pinned 0.1.2)")

    configs = _configs()
    yaml = YAML()
    result: dict[str, dict[str, str]] = {}
    with tempfile.TemporaryDirectory(prefix="thaim-") as tmp:
        for m in ("dark", "light"):
            out = Path(tmp) / f"{m}.yaml"
            r = subprocess.run(
                [
                    "thaimeleon",
                    image,
                    "--config",
                    str(configs[m]),
                    "--write-palette-to",
                    str(out),
                ],
                capture_output=True,
                text=True,
            )
            if r.returncode != 0:
                raise GenerationError(
                    f"thaimeleon ({m}) failed rc={r.returncode}: {r.stderr[-200:]}"
                )
            if not out.exists():
                raise GenerationError(f"thaimeleon ({m}) wrote no output")
            data = yaml.load(out.read_text())
            if not isinstance(data, dict) or "base" not in data or "text" not in data:
                raise GenerationError(f"thaimeleon ({m}): unparseable palette YAML")
            if bool(data.get("is_light_theme")) != (m == "light"):
                raise GenerationError(
                    f"thaimeleon ({m}): is_light_theme mismatch — mode forcing failed"
                )
            result[m] = {k: v for k, v in data.items() if k != "is_light_theme"}
    return result


def thaim_slots(palette45: dict[str, str], mode: str) -> dict[str, str]:
    """45-key palette → base24 slots + brights."""
    from theme.engines.matugen import derive_brights

    slots: dict[str, str] = {}
    for slot, key in THAIM_SLOT_MAP.items():
        if key not in palette45:
            raise GenerationError(f"thaimeleon palette missing key {key!r}")
        slots[slot] = palette45[key]
    return derive_brights(slots, mode)


class ThaimEngine(Engine):
    name = "thaim"
    provides = ["core", "terminal"]
    critical = False  # soft-degrade in the daemon

    def extract(
        self, source_image: str, forced_mode: str | None = None
    ) -> dict[str, Any]:
        extracted = extract_thaimeleon(source_image)
        variants: dict[str, dict[str, Any]] = {}
        for m in ("dark", "light"):
            terminal, derived_t = complete_terminal(thaim_slots(extracted[m], m), m)
            variants[m] = {
                "core": base24_to_core(terminal),
                "extensions": {"terminal": terminal},
                "derived": {f"terminal.{k}": v for k, v in derived_t.items()},
            }
        return {"variants": variants, "detected_mode": None}
