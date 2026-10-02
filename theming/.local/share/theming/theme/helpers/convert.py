"""Color format conversions for consumer-specific notations."""

from __future__ import annotations

import re

HEX_RE = re.compile(r"^#?([0-9A-Fa-f]{6})$")


def normalize_hex(value: str, prefix: bool = True) -> str:
    m = HEX_RE.match(value.strip())
    if not m:
        raise ValueError(f"malformed hex color: {value!r}")
    h = m.group(1).lower()
    return f"#{h}" if prefix else h


def hex_to_rgb_tuple(value: str) -> tuple[int, int, int]:
    h = normalize_hex(value, prefix=False)
    return int(h[0:2], 16), int(h[2:4], 16), int(h[4:6], 16)


def hex_to_rgb_colon(value: str) -> str:
    """`#ff9999` → `rgb:ff/99/99` (xsecurelock W8 format)."""
    r, g, b = hex_to_rgb_tuple(value)
    return f"rgb:{r:02x}/{g:02x}/{b:02x}"


def hex_to_rgba(value: str, alpha: str = "ff") -> str:
    """`#ff9999` → `rgba(ff9999ff)` (hypr W4 format)."""
    h = normalize_hex(value, prefix=False)
    return f"rgba({h}{alpha})"


def hex_to_rgb_paren(value: str) -> str:
    """`#ff9999` → `rgb(ff9999)` (hyprlock W5 format)."""
    return f"rgb({normalize_hex(value, prefix=False)})"


def rgb_distance(a: str, b: str) -> float:
    """Euclidean distance between two hex colors."""
    ta, tb = hex_to_rgb_tuple(a), hex_to_rgb_tuple(b)
    return sum((x - y) ** 2 for x, y in zip(ta, tb)) ** 0.5


def shift_lightness(value: str, delta: float, clamp: float) -> str:
    """HSL lightness shift for base10–17 derivation."""
    import colorsys

    r, g, b = (x / 255.0 for x in hex_to_rgb_tuple(value))
    h, l, s = colorsys.rgb_to_hls(r, g, b)
    l = min(l + delta, clamp) if delta > 0 else max(l + delta, clamp)
    r, g, b = colorsys.hls_to_rgb(h, l, s)
    return "#{:02x}{:02x}{:02x}".format(round(r * 255), round(g * 255), round(b * 255))
