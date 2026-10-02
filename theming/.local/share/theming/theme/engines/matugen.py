"""matugen engine: faithful + vibrant flavors over one shared dump cache."""

from __future__ import annotations

import json
import subprocess
from pathlib import Path
from typing import Any

from theme.engines.base import (
    Engine,
    GenerationError,
    base24_to_core,
    complete_terminal,
    material_to_core,
)
from theme.helpers.convert import shift_lightness
from theme.helpers.logio import atomic_write

REPO_ROOT = Path(__file__).resolve().parent.parent.parent
MATUGEN_TOML = REPO_ROOT / "matugen.toml"

WHEEL_TO_BASE16 = {
    "red": "base08",
    "orange": "base09",
    "yellow": "base0A",
    "green": "base0B",
    "teal": "base0C",
    "azure": "base0D",
    "magenta": "base0E",
    "rose": "base0F",
}

L_BUMP = 0.15
L_MAX_DARK = 0.90
L_MIN_LIGHT = 0.10
AA_THRESHOLD = 4.5
ACCENT_FALLBACK_THRESHOLD = 2.0

_DUMP_CACHE: dict[tuple[str, str], dict[str, Any]] = {}


def derive_brights(slots: dict[str, str], mode: str) -> dict[str, str]:
    """base10–base17: HSL lightness shift of base08–base0F."""
    result = dict(slots)
    for i in range(8, 16):
        src = f"base{i:02X}"
        dst = f"base{i + 8:02X}"
        if mode == "dark":
            result[dst] = shift_lightness(slots[src], L_BUMP, L_MAX_DARK)
        else:
            result[dst] = shift_lightness(slots[src], -L_BUMP, L_MIN_LIGHT)
    return result


def _contrast_ratio(hex1: str, hex2: str) -> float:
    def lum(h: str) -> float:
        r, g, b = int(h[1:3], 16) / 255, int(h[3:5], 16) / 255, int(h[5:7], 16) / 255
        lin = lambda c: c / 12.92 if c <= 0.04045 else ((c + 0.055) / 1.055) ** 2.4
        return 0.2126 * lin(r) + 0.7152 * lin(g) + 0.0722 * lin(b)

    l1, l2 = lum(hex1), lum(hex2)
    return (max(l1, l2) + 0.05) / (min(l1, l2) + 0.05)


def _shift_until_contrast(
    color: str, bg: str, target: float, mode: str, max_steps: int = 20
) -> str:
    import colorsys

    r, g, b = (
        int(color[1:3], 16) / 255,
        int(color[3:5], 16) / 255,
        int(color[5:7], 16) / 255,
    )
    h, l, s = colorsys.rgb_to_hls(r, g, b)
    step = 0.04 if mode == "dark" else -0.04
    for _ in range(max_steps):
        if _contrast_ratio(color, bg) >= target:
            return color
        l = max(0.01, min(0.99, l + step))
        r, g, b = colorsys.hls_to_rgb(h, l, s)
        color = "#{:02x}{:02x}{:02x}".format(
            round(r * 255), round(g * 255), round(b * 255)
        )
    return color


def _saturation(hex_color: str) -> float:
    import colorsys

    r, g, b = (
        int(hex_color[1:3], 16) / 255,
        int(hex_color[3:5], 16) / 255,
        int(hex_color[5:7], 16) / 255,
    )
    _, _, s = colorsys.rgb_to_hls(r, g, b)
    return s


def post_process_contrast(
    slots: dict[str, str], mode: str, wheel_colors: dict[str, str]
) -> dict[str, str]:
    """Enforce WCAG AA contrast on neutrals + wheel fallback for accents."""
    bg = slots["base00"]
    result = dict(slots)

    for slot in ("base03", "base04", "base05", "base06"):
        if slot in result:
            result[slot] = _shift_until_contrast(result[slot], bg, AA_THRESHOLD, mode)

    for hue_name, slot in WHEEL_TO_BASE16.items():
        if slot not in result:
            continue
        extracted = result[slot]
        ratio = _contrast_ratio(extracted, bg)
        sat = _saturation(extracted)
        if ratio < ACCENT_FALLBACK_THRESHOLD or sat < 0.05:
            wheel = wheel_colors.get(hue_name)
            if wheel:
                result[slot] = wheel
        if _contrast_ratio(result[slot], bg) < AA_THRESHOLD:
            result[slot] = _shift_until_contrast(result[slot], bg, AA_THRESHOLD, mode)

    return result


def run_matugen(image: str, mode: str = "dark") -> dict[str, Any]:
    key = (image, mode)
    if key in _DUMP_CACHE:
        return _DUMP_CACHE[key]
    r = subprocess.run(
        [
            "matugen",
            "image",
            image,
            "-c",
            str(MATUGEN_TOML),
            "-m",
            mode,
            "-b",
            "wal",
            "--json",
            "hex",
            "--dry-run",
            "--prefer",
            "lightness",
        ],
        capture_output=True,
        text=True,
        timeout=120,
    )
    if r.returncode != 0:
        raise GenerationError(f"matugen failed: {r.stderr[-400:]}")
    try:
        dump = json.loads(r.stdout)
    except json.JSONDecodeError:
        raise GenerationError("matugen produced unparseable JSON output")
    _DUMP_CACHE[key] = dump
    return dump


def resolve_mode(mode_preference: str, dump: dict[str, Any]) -> str:
    """Concrete mode from preference + dump (auto → is_dark_mode)."""

    if mode_preference in ("dark", "light"):
        return mode_preference
    is_dark = dump.get("is_dark_mode")
    if is_dark is None:
        raise GenerationError("matugen -m smart did not produce is_dark_mode")
    return "dark" if is_dark else "light"


def build_variant(
    dump: dict[str, Any], mode: str, flavor: str = "faithful"
) -> dict[str, str]:
    """Materialize one base16 map (base00–base0F) from a matugen dump."""

    b16_src = dump.get("base16", {})
    colors = dump.get("colors", {})
    slots: dict[str, str] = {}

    for i in range(8):
        slot = f"base{i:02X}"
        entry = b16_src.get(f"base{i:02x}", {})
        hex_val = entry.get(mode, {}).get("color") or entry.get("default", {}).get(
            "color"
        )
        if not hex_val:
            raise GenerationError(f"missing {slot} in matugen dump ({mode})")
        slots[slot] = hex_val

    for hue_name, slot in WHEEL_TO_BASE16.items():
        if flavor == "vibrant":
            entry = colors.get(hue_name, {})
            hex_val = entry.get(mode, {}).get("color") or entry.get("default", {}).get(
                "color"
            )
            if not hex_val:
                raise GenerationError(f"wheel hue {hue_name} missing (vibrant flavor)")
            slots[slot] = hex_val
        else:
            entry = b16_src.get(f"base{int(slot[4:], 16):02x}", {})
            hex_val = entry.get(mode, {}).get("color") or entry.get("default", {}).get(
                "color"
            )
            if not hex_val:
                raise GenerationError(
                    f"missing {slot} in matugen dump ({mode} faithful)"
                )
            slots[slot] = hex_val

    return slots


def _material_roles(dump: dict[str, Any], mode: str) -> dict[str, str]:
    roles: dict[str, str] = {}
    for role, entry in dump.get("colors", {}).items():
        hex_val = entry.get(mode, {}).get("color") or entry.get("default", {}).get(
            "color"
        )
        if hex_val:
            roles[role] = hex_val
    return roles


class MatugenEngine(Engine):
    """flavor selects the accent source; both registry entries share the dump cache."""

    def __init__(self, flavor: str = "faithful"):
        self.flavor = flavor
        self.name = f"matugen-{flavor}"
        self.provides = ["core", "terminal", "material"]

    def extract(
        self, source_image: str, forced_mode: str | None = None
    ) -> dict[str, Any]:
        matugen_mode = forced_mode or "smart"
        dump = run_matugen(source_image, matugen_mode)
        detected = None
        if forced_mode is None:
            detected = resolve_mode("auto", dump)

        variants: dict[str, dict[str, Any]] = {}
        for m in ("dark", "light"):
            roles = _material_roles(dump, m)
            native = build_variant(dump, m, self.flavor)
            processed = post_process_contrast(native, m, roles)
            terminal, derived_t = complete_terminal(processed, m)
            core = {**material_to_core(roles), **base24_to_core(terminal)}
            core, derived_c = complete_core_from(core, native, roles)
            variants[m] = {
                "core": core,
                "extensions": {"terminal": terminal, "material": roles},
                "derived": {
                    **{f"terminal.{k}": v for k, v in derived_t.items()},
                    **{f"core.{k}": v for k, v in derived_c.items()},
                },
            }
        return {"variants": variants, "detected_mode": detected}


def complete_core_from(
    core: dict[str, str], native: dict[str, str], roles: dict[str, str]
) -> tuple[dict[str, str], dict[str, str]]:
    """No-op guard: base24 anchors always cover the remaining core tokens."""
    derived: dict[str, str] = {}
    return dict(core), derived
