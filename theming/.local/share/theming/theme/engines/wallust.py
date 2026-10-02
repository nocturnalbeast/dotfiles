"""wallust engine: version-gated 3.5.2 pin (git-tag only, not on crates.io), 19-key palette → core + terminal."""

from __future__ import annotations

import json
import re
import shutil
import subprocess
import tempfile
from pathlib import Path
from typing import Any

from theme.engines.base import (
    Engine,
    GenerationError,
    base24_to_core,
    complete_terminal,
    ramp_mix,
)
from theme.helpers.logio import atomic_write

CACHE_BASE = Path(
    __import__("os").environ.get("XDG_CACHE_HOME", Path.home() / ".cache")
)
WALLUST_CACHE_DIR = CACHE_BASE / "theming" / "wallust"
WALLUST_PINNED_VERSION = "3.5.2"

# family per mode
PALETTE_FAMILY = {"dark": "dark", "light": "light"}

# wallust key -> base24 slot (native); color0 ≈ background, unused
WALLUST_SLOT_MAP = {
    "background": "base00",
    "color8": "base01",
    "foreground": "base05",
    "color15": "base07",
    "color1": "base08",
    "color3": "base0A",
    "color2": "base0B",
    "color6": "base0C",
    "color4": "base0D",
    "color5": "base0E",
    "color9": "base0F",
    "color11": "base12",
    "color10": "base13",
    "color14": "base14",
    "color12": "base15",
    "color13": "base16",
}

_HEX_RE = re.compile(r"^#[0-9A-Fa-f]{6}$")

_TEMPLATE_JSON = (
    "{\n"
    + ",\n".join(
        f'  "{key}": "{{{{ {key} }}}}"'
        for key in ["background", "foreground"] + [f"color{i}" for i in range(16)]
    )
    + "\n}\n"
)


def wallust_version() -> str | None:
    """`wallust 3.5.2 (sha date)` — the second token is the semver."""
    if not shutil.which("wallust"):
        return None
    r = subprocess.run(["wallust", "--version"], capture_output=True, text=True)
    parts = (r.stdout + r.stderr).split()
    return parts[1] if len(parts) > 1 else None


def version_ok() -> bool:
    return wallust_version() == WALLUST_PINNED_VERSION


def _setup() -> tuple[Path, Path]:
    """Generated config + template dir (disposable cache)."""
    templates = WALLUST_CACHE_DIR / "templates"
    templates.mkdir(parents=True, exist_ok=True)
    atomic_write(templates / "colors.json", _TEMPLATE_JSON)
    return WALLUST_CACHE_DIR, templates


def extract_wallust(image: str, mode: str, target: Path) -> dict[str, str]:
    """One forced-family run → validated 19-key dict parsed from `target`.

    Raises:
        GenerationError: on any failure, incl. silent empty template variables.
    """
    if not shutil.which("wallust"):
        raise GenerationError(
            "wallust not found (pin 3.5.2; install: cargo install "
            "--git https://codeberg.org/explosion-mental/wallust.git "
            "--tag 3.5.2 --locked)"
        )
    if not version_ok():
        raise GenerationError(
            f"wallust version gate: expected {WALLUST_PINNED_VERSION}, "
            f"got {wallust_version()!r}"
        )

    cache_dir, templates = _setup()
    config = cache_dir / "wallust.toml"
    atomic_write(
        config,
        (
            'backend = "resized"\n'
            'color_space = "lab"\n'
            f'palette = "{PALETTE_FAMILY[mode]}"\n'
            "threshold = 20\n"
            "check_contrast = true\n"
            "\n"
            "[templates]\n"
            f'colors = {{ template = "colors.json", target = "{target}" }}\n'
        ),
    )

    import os

    env = {
        **os.environ,
        "XDG_CONFIG_HOME": str(cache_dir / "xdg-config"),
        "XDG_CACHE_HOME": str(cache_dir / "xdg-cache"),
    }
    # wallust ANSI-prints to stdout even when piped — output comes from the rendered target file
    r = subprocess.run(
        [
            "wallust",
            "run",
            image,
            "-C",
            str(config),
            "--templates-dir",
            str(templates),
            "-p",
            PALETTE_FAMILY[mode],
            "-s",
            "-n",
            "-q",
        ],
        capture_output=True,
        text=True,
        env=env,
        timeout=120,
    )
    if r.returncode != 0:
        raise GenerationError(
            f"wallust ({mode}) failed rc={r.returncode}: {r.stderr[-200:]}"
        )
    if not target.exists():
        raise GenerationError(
            f"wallust ({mode}) wrote no output (template warning — see stderr)"
        )

    try:
        data = json.loads(target.read_text())
    except json.JSONDecodeError:
        raise GenerationError(f"wallust ({mode}): unparseable JSON output")

    for key in ("background", "foreground", *(f"color{i}" for i in range(16))):
        value = data.get(key)
        if not isinstance(value, str) or not _HEX_RE.match(value):
            raise GenerationError(
                f"wallust ({mode}): {key!r} missing/invalid ({value!r}) — "
                "template variables must never be trusted"
            )
    return data


def _hue_shift(hex_color: str, degrees: float) -> str:
    import colorsys

    r, g, b = (int(hex_color[i : i + 2], 16) / 255 for i in (1, 3, 5))
    h, l, s = colorsys.rgb_to_hls(r, g, b)
    r, g, b = colorsys.hls_to_rgb((h + degrees / 360) % 1, l, s)
    return "#{:02x}{:02x}{:02x}".format(round(r * 255), round(g * 255), round(b * 255))


def wallust_slots(
    keys: dict[str, str], mode: str
) -> tuple[dict[str, str], dict[str, str]]:
    """19-key → base24 native map + {slot: rule} derived marks; brights complete in complete_terminal."""
    from theme.engines.matugen import post_process_contrast

    slots: dict[str, str] = {}
    for key, slot in WALLUST_SLOT_MAP.items():
        slots[slot] = keys[key].upper()

    # base09: +30° hue-shift of base08 — ANSI palettes have no orange.
    slots["base09"] = _hue_shift(slots["base08"], 30)
    derived: dict[str, str] = {"base09": "hue-shift:+30"}

    # check_contrast can't rescue light-mode gray-on-gray; AA-shift with an EMPTY wheel — gray character is wallust's honest output.
    shifted = post_process_contrast(slots, mode, {})
    for slot, value in shifted.items():
        if slots.get(slot) != value:
            derived[slot] = "aa-shift"
    return shifted, derived


class WallustEngine(Engine):
    name = "wallust"
    provides = ["core", "terminal"]
    critical = False  # soft-degrade in the daemon

    def extract(
        self, source_image: str, forced_mode: str | None = None
    ) -> dict[str, Any]:
        variants: dict[str, dict[str, Any]] = {}
        with tempfile.TemporaryDirectory(prefix="wallust-") as tmp:
            for m in ("dark", "light"):
                target = Path(tmp) / f"{m}.json"
                keys = extract_wallust(source_image, m, target)
                native, marks = wallust_slots(keys, m)
                terminal, derived_t = complete_terminal(native, m)
                derived = {**marks, **derived_t}
                variants[m] = {
                    "core": base24_to_core(terminal),
                    "extensions": {"terminal": terminal},
                    "derived": {f"terminal.{k}": v for k, v in derived.items()},
                }
        return {"variants": variants, "detected_mode": None}
