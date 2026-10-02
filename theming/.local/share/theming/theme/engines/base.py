"""Engine ABC + token contract: core tokens, cross-walks, derivation completion."""

from __future__ import annotations

from abc import ABC, abstractmethod
from typing import Any


class GenerationError(RuntimeError):
    """Raised by engines and the generation pipeline."""


# --- cross-walk ------------------------------------------------------

# core token -> base24 slot; Material anchors live in CORE_MATERIAL (None = derived at assembly)
CORE_BASE24 = {
    "background": "base00",
    "background.subtle": "base01",
    "background.selection": "base02",
    "foreground": "base05",
    "foreground.subtle": "base03",
    "foreground.bright": "base07",
    "accent": "base0D",
    "accent.alt": "base0E",
    "accent.warm": "base09",
    "status.error": "base08",
    "status.warning": "base0A",
    "status.success": "base0B",
    "status.info": "base0C",
    "border.subtle": "base06",
}

CORE_MATERIAL = {
    "background": "surface",
    "background.subtle": "surfaceContainerLow",
    "background.selection": "surfaceContainerHigh",
    "foreground": "onSurface",
    "foreground.subtle": "outline",
    "foreground.bright": None,
    "accent": "primary",
    "accent.alt": "tertiary",
    "accent.warm": None,
    "status.error": "error",
    "status.warning": None,
    "status.success": None,
    "status.info": None,
    "border.subtle": "outlineVariant",
}

CORE_TOKENS = list(CORE_BASE24)

# engine name -> emitted scheme-family suffix
ENGINE_SUFFIX = {
    "matugen-faithful": "",
    "matugen-vibrant": "-vibrant",
    "thaim": "-thaim",
    "wallust": "-wallust",
}

# base00-0F = terminal native floor; base10-17 brights + missing ramp slots are derivation-tier
BASE24_NATIVE = [f"base{i:02X}" for i in range(16)]
BASE24_ALL = [f"base{i:02X}" for i in range(24)]


def base24_to_core(slots: dict[str, str]) -> dict[str, str]:
    """Cross-walk a base24 slot map to the 14 core tokens."""
    return {token: slots[slot] for token, slot in CORE_BASE24.items() if slot in slots}


def material_to_core(roles: dict[str, str]) -> dict[str, str]:
    """Cross-walk Material roles to the core tokens that anchor natively."""
    out: dict[str, str] = {}
    for token, role in CORE_MATERIAL.items():
        if role is not None and role in roles:
            out[token] = roles[role]
    return out


def ramp_mix(bg: str, fg: str, t: float) -> str:
    """bg↔fg linear interpolation (flavours' mix recipe)."""

    def channel(c: str, i: int) -> int:
        return int(c.lstrip("#")[i * 2 : i * 2 + 2], 16)

    mixed = "#"
    for i in range(3):
        v = round(channel(bg, i) * (1 - t) + channel(fg, i) * t)
        mixed += f"{v:02x}"
    return mixed


# neutral ramp fill stops: dark = bg→fg at t, light mirrors (1-t); fills slots an engine lacks natively
RAMP_STOPS = {
    "base01": 0.15,
    "base02": 0.30,
    "base03": 0.45,
    "base04": 0.60,
    "base06": 0.75,
    "base07": 0.90,
}


def complete_terminal(
    slots: dict[str, str], mode: str
) -> tuple[dict[str, str], dict[str, str]]:
    """Fill derivation-tier slots (bg↔fg neutrals, brights); returns (map, {slot: rule} marks)."""
    from theme.engines.matugen import derive_brights

    complete = dict(slots)
    derived: dict[str, str] = {}
    bg, fg = complete["base00"], complete["base05"]
    for slot, t in RAMP_STOPS.items():
        if not complete.get(slot):
            complete[slot] = ramp_mix(bg, fg, t if mode == "dark" else 1 - t)
            derived[slot] = f"ramp-mix:{t}"
    brights = derive_brights(complete, mode)
    for i in range(8, 16):
        src, dst = f"base{i:02X}", f"base{i + 8:02X}"
        if not complete.get(dst):
            complete[dst] = brights[dst]
            derived[dst] = f"brights:{src}"
    return complete, derived


def complete_core(core: dict[str, str]) -> tuple[dict[str, str], dict[str, str]]:
    """No-op guard: adapters always carry base24 anchors, so the core is already complete."""
    complete = dict(core)
    derived: dict[str, str] = {}
    return complete, derived


class Engine(ABC):
    """One color-derivation pipeline: pure, deterministic, no writes."""

    name: str
    provides: list[str]  # NATIVE groups
    omits: dict[str, list[str]] = {}
    critical: bool = True  # False → soft-degrade in daemon

    @abstractmethod
    def extract(
        self, source_image: str, forced_mode: str | None = None
    ) -> dict[str, Any]:
        """Derive both variants from the image.

        Args:
            forced_mode: None = smart/auto; "dark"/"light" forces.
        Returns:
            {"variants": {mode: {"core", "extensions"}}, "detected_mode": str | None}.
        """
