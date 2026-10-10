"""One-time v1→v2 migration (palette restructure, tui.flavor → engines.tui), computed from stored data; idempotent."""

from __future__ import annotations

from pathlib import Path
from typing import Any

from ruamel.yaml import YAML

from theme.engines.base import base24_to_core
from theme.helpers.logio import atomic_write, warn

FLAVOR_TO_ENGINE = {
    "faithful": "matugen-faithful",
    "vibrant": "matugen-vibrant",
    "thaim": "thaim",
}


def _is_v1_palette(data: dict[str, Any]) -> bool:
    palette = data.get("palette") or {}
    variants = palette.get("variants") or {}
    for variant in variants.values():
        if isinstance(variant, dict) and "base16" in variant:
            return True
    return False


def _has_flavor(data: dict[str, Any]) -> bool:
    tui = data.get("tui") or {}
    return "flavor" in tui


def needs_migration(path: Path) -> bool:
    yaml = YAML()
    yaml.preserve_quotes = True
    with path.open(encoding="utf-8") as fh:
        data = yaml.load(fh) or {}
    return _is_v1_palette(data) or _has_flavor(data)


def migrate(path: Path) -> bool:
    """Returns True when a rewrite happened; idempotent - v2 configs pass through untouched."""
    yaml = YAML()
    yaml.preserve_quotes = True
    with path.open(encoding="utf-8") as fh:
        data = yaml.load(fh) or {}

    changed = False

    # config grammar: tui.flavor → engines.tui
    tui = data.get("tui") or {}
    if "flavor" in tui:
        flavor = tui.pop("flavor")
        engines = data.setdefault("engines", {})
        engines["tui"] = FLAVOR_TO_ENGINE.get(str(flavor), "matugen-faithful")
        engines.setdefault("gui", "matugen-faithful")
        changed = True
        warn(
            f"migrated config: tui.flavor {flavor!r} → engines.tui "
            f"{engines['tui']!r} (one-time)"
        )

    # palette section: v1 base16/colors → v2 core/extensions
    palette = data.get("palette") or {}
    variants = palette.get("variants") or {}
    if any(isinstance(v, dict) and "base16" in v for v in variants.values()):
        for m, variant in variants.items():
            if not isinstance(variant, dict) or "base16" not in variant:
                continue
            base16 = variant.pop("base16")
            colors = variant.pop("colors", {})
            variant["core"] = base24_to_core(base16)
            variant["extensions"] = {
                "terminal": dict(base16),
                "terminal_gui": dict(base16),
                "material": colors,
            }
            variant["derived"] = {}
        palette["engines"] = {"gui": "matugen-faithful", "tui": "matugen-faithful"}
        changed = True
        warn(
            "migrated palette section v1 → v2 (stored data; the stored "
            "terminal reflects matugen-faithful - run `theme palette "
            "generate` to populate the selected engines)"
        )

    if not changed:
        return False

    from io import StringIO

    buf = StringIO()
    yaml.dump(data, buf)
    atomic_write(path, buf.getvalue())
    return True
