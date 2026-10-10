"""Palette resolution: accent chain, mode, slice hashing."""

from __future__ import annotations

import hashlib
import json
from typing import Any

from theme.helpers.convert import normalize_hex


class PaletteError(Exception):
    pass


def active_variant(palette: dict[str, Any]) -> dict[str, Any]:
    m = mode(palette)
    variants = palette.get("variants", {})
    variant = variants.get(m)
    if not isinstance(variant, dict):
        raise PaletteError(f"palette.variants.{m}: missing")
    return variant


def variant_base16(variant: dict[str, Any]) -> dict[str, str]:
    """Terminal slots from extensions.terminal, v1 base16 fallback."""
    base16 = (
        (variant.get("extensions") or {}).get("terminal") or variant.get("base16") or {}
    )
    if not base16:
        raise PaletteError("variant terminal incomplete")
    return {k: normalize_hex(str(v)) for k, v in base16.items()}


def core_token(palette: dict[str, Any], token: str) -> str:
    """A semantic core token from the active variant."""
    variant = active_variant(palette)
    core = variant.get("core") or {}
    if token not in core:
        raise PaletteError(f"core token {token!r} missing")
    return normalize_hex(str(core[token]))


def variant_core(variant: dict[str, Any]) -> dict[str, str]:
    return variant.get("core") or {}


def resolve_accent(palette: dict[str, Any]) -> str:
    """Accent chain: palette.accent → core.accent → material.primary → terminal.base0D."""
    explicit = palette.get("accent")
    if explicit:
        return normalize_hex(str(explicit))
    variant = active_variant(palette)
    core = variant.get("core") or {}
    if core.get("accent"):
        return normalize_hex(str(core["accent"]))
    material = (variant.get("extensions") or {}).get("material") or {}
    if material.get("primary"):
        return normalize_hex(str(material["primary"]))
    base16 = variant_base16(variant)
    if base16.get("base0D"):
        return base16["base0D"]
    raise PaletteError(
        "accent unresolvable: no palette.accent, core.accent, "
        "material.primary, or terminal.base0D"
    )


def mode(palette: dict[str, Any]) -> str:
    """Resolved mode: effective_mode (set by generation), mode fallback for hand-authored palettes."""
    m = palette.get("effective_mode") or palette.get("mode")
    if m not in ("dark", "light"):
        raise PaletteError(f"palette mode must resolve to dark|light, got {m!r}")
    return m


def slot(palette: dict[str, Any], name: str) -> str:
    """Named base16 slot from the active variant."""
    return variant_base16(active_variant(palette))[name]


def ramp16(palette: dict[str, Any]) -> dict[str, str]:
    """The GUI-engine base16 ramp (base00-base0F) - terminal_gui."""
    variant = palette["variants"][mode(palette)]
    return (variant.get("extensions", {}) or {}).get("terminal_gui") or {}


# semantic anchors for the GUI space: base16 slot → core token
_SLOT16_CROSSWALK = {
    "base00": "background",
    "base01": "background.subtle",
    "base02": "background.selection",
    "base03": "foreground.subtle",
    "base05": "foreground",
    "base06": "border.subtle",
    "base07": "foreground.bright",
    "base08": "status.error",
    "base09": "accent.warm",
    "base0A": "status.warning",
    "base0B": "status.success",
    "base0C": "status.info",
    "base0D": "accent",
    "base0E": "accent.alt",
}


def material_roles(
    palette: dict[str, Any], required: list[str] | tuple[str, ...]
) -> dict[str, str]:
    """Material roles of the active variant; hard-requires `required`
    (missing role raises - no silent fallbacks)."""
    variant = active_variant(palette)
    material = (variant.get("extensions") or {}).get("material") or {}
    missing = [r for r in required if not material.get(r)]
    if missing:
        raise PaletteError(f"material roles missing: {', '.join(missing)}")
    return {r: normalize_hex(str(material[r])) for r in required}


def slot16(palette: dict[str, Any], name: str) -> str:
    """Semantic base16 slot: anchored crosswalk token, terminal_gui ramp fallback."""
    if name in _SLOT16_CROSSWALK:
        return core_token(palette, _SLOT16_CROSSWALK[name])
    ramp = ramp16(palette)
    if name not in ramp:
        raise PaletteError(f"palette ramp missing {name}")
    return normalize_hex(str(ramp[name]))


def slice_hash(obj: Any) -> str:
    """Canonicalized slice hash: sorted-key JSON sha256."""
    canonical = json.dumps(obj, sort_keys=True, separators=(",", ":"), default=str)
    return hashlib.sha256(canonical.encode()).hexdigest()
