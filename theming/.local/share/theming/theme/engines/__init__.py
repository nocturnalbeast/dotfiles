"""Engine registry: flavors ARE engines — flat, complete pipelines."""

from __future__ import annotations

from theme.engines.base import (
    CORE_BASE24,
    ENGINE_SUFFIX,
    Engine,
    GenerationError,
    base24_to_core,
    complete_terminal,
    material_to_core,
    ramp_mix,
)
from theme.engines.matugen import MatugenEngine
from theme.engines.thaim import ThaimEngine
from theme.engines.wallust import WallustEngine

ENGINES = {
    "matugen-faithful": MatugenEngine("faithful"),
    "matugen-vibrant": MatugenEngine("vibrant"),
    "thaim": ThaimEngine(),
    "wallust": WallustEngine(),
}

__all__ = [
    "ENGINES",
    "Engine",
    "GenerationError",
    "CORE_BASE24",
    "ENGINE_SUFFIX",
    "base24_to_core",
    "complete_terminal",
    "material_to_core",
    "ramp_mix",
]
