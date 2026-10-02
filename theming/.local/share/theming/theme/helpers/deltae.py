"""CIEDE2000 color difference + weighted scheme distance + catalog.

Pure-stdlib math: sRGB → linear → XYZ (D65) → CIELAB → CIEDE2000
(Sharma-Wu-Dalal 2005; kL=kC=kH=1). ruamel imports live in
load_catalog.
"""

from __future__ import annotations

import math
from pathlib import Path

from theme.helpers.convert import normalize_hex

# Weighted ΔE00 mean weights per: bg/fg dominate (what the
# terminal renders most); brights excluded (rarely visible).
# Insertion order base00→base0F pins the dedup iteration order.
SLOT_WEIGHTS: dict[str, float] = {
    "base00": 3.0,
    "base01": 2.0,
    "base02": 2.0,
    "base03": 1.5,
    "base04": 1.0,
    "base05": 3.0,
    "base06": 1.5,
    "base07": 1.0,
    "base08": 1.0,
    "base09": 1.0,
    "base0A": 1.0,
    "base0B": 1.0,
    "base0C": 1.0,
    "base0D": 1.0,
    "base0E": 1.0,
    "base0F": 1.0,
}

REQUIRED_SLOTS = tuple(f"base{i:02X}" for i in range(18))  # base00..base17

DEFAULT_CATALOG_DIR = Path(
    "~/.local/share/tinted-theming/tinty/repos/schemes/base24"
).expanduser()

# sRGB (D65) → XYZ matrix.
_SRGB_TO_XYZ = (
    (0.4124564, 0.3575761, 0.1804375),
    (0.2126729, 0.7151522, 0.0721750),
    (0.0193339, 0.1191920, 0.9503041),
)

# CIELAB white point (D65).
_XN, _YN, _ZN = 0.95047, 1.0, 1.08883
_DELTA = 6 / 29  # CIE threshold constant


def _srgb_to_lab(hex_color: str) -> tuple[float, float, float]:
    """#rrggbb (or rrggbb, case-insensitive) → CIELAB (D65)."""
    h = normalize_hex(hex_color, prefix=False)
    rgb = [int(h[i : i + 2], 16) / 255.0 for i in (0, 2, 4)]
    lin = [c / 12.92 if c <= 0.04045 else ((c + 0.055) / 1.055) ** 2.4 for c in rgb]
    xyz = [
        sum(coef * c for coef, c in zip(row, lin)) / wp
        for row, wp in zip(_SRGB_TO_XYZ, (_XN, _YN, _ZN))
    ]

    def f(t: float) -> float:
        return t ** (1 / 3) if t > _DELTA**3 else t / (3 * _DELTA**2) + 4 / 29

    fx, fy, fz = (f(t) for t in xyz)
    return 116 * fy - 16, 500 * (fx - fy), 200 * (fy - fz)


def _delta_e2000_lab(
    lab1: tuple[float, float, float],
    lab2: tuple[float, float, float],
    kL: float = 1.0,
    kC: float = 1.0,
    kH: float = 1.0,
) -> float:
    """CIEDE2000 between two CIELAB tuples (Sharma 2005 eqs. 1–26)."""
    L1, a1, b1 = lab1
    L2, a2, b2 = lab2

    C1 = math.hypot(a1, b1)
    C2 = math.hypot(a2, b2)
    C_bar = (C1 + C2) / 2
    G = 0.5 * (1 - math.sqrt(C_bar**7 / (C_bar**7 + 25**7)))

    a1p = (1 + G) * a1
    a2p = (1 + G) * a2
    C1p = math.hypot(a1p, b1)
    C2p = math.hypot(a2p, b2)
    h1p = math.degrees(math.atan2(b1, a1p)) % 360 if C1p else 0.0
    h2p = math.degrees(math.atan2(b2, a2p)) % 360 if C2p else 0.0

    dLp = L2 - L1
    dCp = C2p - C1p
    if C1p * C2p:
        dhp = h2p - h1p
        if dhp > 180:
            dhp -= 360
        elif dhp < -180:
            dhp += 360
    else:
        dhp = 0.0
    dHp = 2 * math.sqrt(C1p * C2p) * math.sin(math.radians(dhp) / 2)

    L_bar_p = (L1 + L2) / 2
    C_bar_p = (C1p + C2p) / 2
    if C1p * C2p == 0:
        h_bar_p = h1p + h2p
    elif abs(h1p - h2p) <= 180:
        h_bar_p = (h1p + h2p) / 2
    elif h1p + h2p < 360:
        h_bar_p = (h1p + h2p + 360) / 2
    else:
        h_bar_p = (h1p + h2p - 360) / 2

    T = (
        1
        - 0.17 * math.cos(math.radians(h_bar_p - 30))
        + 0.24 * math.cos(math.radians(2 * h_bar_p))
        + 0.32 * math.cos(math.radians(3 * h_bar_p + 6))
        - 0.20 * math.cos(math.radians(4 * h_bar_p - 63))
    )
    d_theta = 30 * math.exp(-(((h_bar_p - 275) / 25) ** 2))
    R_C = 2 * math.sqrt(C_bar_p**7 / (C_bar_p**7 + 25**7))
    S_L = 1 + 0.015 * (L_bar_p - 50) ** 2 / math.sqrt(20 + (L_bar_p - 50) ** 2)
    S_C = 1 + 0.045 * C_bar_p
    S_H = 1 + 0.015 * C_bar_p * T
    R_T = -math.sin(math.radians(2 * d_theta)) * R_C

    tC = dCp / (kC * S_C)
    tH = dHp / (kH * S_H)
    return math.sqrt((dLp / (kL * S_L)) ** 2 + tC**2 + tH**2 + R_T * tC * tH)


def delta_e2000(hex1: str, hex2: str) -> float:
    """CIEDE2000 color difference between two #rrggbb strings. Sharma-Wu-Dalal 2005 formulation."""
    return _delta_e2000_lab(_srgb_to_lab(hex1), _srgb_to_lab(hex2))


def scheme_distance(query: dict[str, str], candidate: dict[str, str]) -> float:
    """Weighted mean ΔE00 between two base00-base0F slot dicts.

    Slots iterate base00→base0F (SLOT_WEIGHTS order). A query slot whose
    normalized hex equals an earlier query slot's is DROPPED — its weight
    leaves the denominator (one comparison per distinct query color).
    Slots missing from either dict are skipped and the mean renormalizes
    over the remaining Σw. With nothing comparable, returns +inf.
    """
    seen: set[str] = set()
    total = 0.0
    weight_sum = 0.0
    for slot, weight in SLOT_WEIGHTS.items():
        if slot not in query or slot not in candidate:
            continue
        q_hex = normalize_hex(query[slot])
        if q_hex in seen:
            continue
        seen.add(q_hex)
        total += weight * delta_e2000(q_hex, candidate[slot])
        weight_sum += weight
    return total / weight_sum if weight_sum else math.inf


def load_catalog(catalog_dir: Path | None = None) -> list[dict]:
    """Parse tinty base24 catalog into deterministic scheme records.

    Each record: {"name": "base24-<stem>", "variant": "dark"|"light",
    "slots": {base00..base17: "#rrggbb"}}. Hex values are normalized
    (catalog files may omit the '#' prefix, base16 convention). Files
    that fail to parse or lack required fields are skipped, never
    raised. Sorted by name.
    """
    from ruamel.yaml import YAML

    directory = DEFAULT_CATALOG_DIR if catalog_dir is None else Path(catalog_dir)
    yaml = YAML(typ="safe", pure=True)
    records: list[dict] = []
    for path in sorted(directory.glob("*.yaml")):
        try:
            doc = yaml.load(path)
            if not isinstance(doc, dict):
                continue
            if doc.get("system") != "base24":
                continue
            variant = doc.get("variant")
            if variant not in ("dark", "light"):
                continue
            palette = doc.get("palette")
            if not isinstance(palette, dict) or any(
                slot not in palette for slot in REQUIRED_SLOTS
            ):
                continue
            slots = {slot: normalize_hex(str(palette[slot])) for slot in REQUIRED_SLOTS}
        except Exception:
            continue
        records.append(
            {"name": f"base24-{path.stem}", "variant": variant, "slots": slots}
        )
    records.sort(key=lambda rec: rec["name"])
    return records


def nearest_schemes(
    query: dict[str, str], catalog: list[dict], variant: str, k: int = 3
) -> list[tuple[str, float]]:
    """Top-k (name, distance) among records matching variant.

    Ascending by distance; ties break by name (deterministic).
    """
    scored = [
        (rec["name"], scheme_distance(query, rec["slots"]))
        for rec in catalog
        if rec["variant"] == variant
    ]
    scored.sort(key=lambda pair: (pair[1], pair[0]))
    return scored[:k]
