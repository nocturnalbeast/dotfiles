"""Sketchybar member: colors_generated.lua from Material roles."""

from __future__ import annotations

import re
from pathlib import Path
from typing import Any

from theme.components.base import Component, Effects
from theme.helpers.logio import atomic_write, ok
from theme.palette import material_roles, slice_hash
from theme.resources.base import Context
from theme.state import make_record, read_member

COLORS_GENERATED = Path.home() / ".config/sketchybar/colors_generated.lua"

# exactly what colors.lua reads - the pcall guard checks gen.primary
REQUIRED_ROLES = (
    "surface",
    "surface_container_high",
    "outline",
    "outline_variant",
    "primary",
    "on_surface_variant",
    "on_surface",
    "red",
    "yellow",
    "green",
    "teal",
    "tertiary_container",
)


def argb(hex_color: str) -> str:
    """#rrggbb → 0xffRRGGBB (sketchybar literal)."""
    h = hex_color.lstrip("#").lower()
    if not re.fullmatch(r"[0-9a-f]{6}", h):
        raise RuntimeError(f"malformed hex for argb: {hex_color!r}")
    return f"0xff{h.upper()}"


def colors_lua(roles: dict[str, str]) -> str:
    lines: list[str] = []
    for role in REQUIRED_ROLES:
        lines.append(f"{role} = {argb(roles[role])},")
    return "\n".join(lines) + "\n"


class SketchybarComponent(Component):
    key = "sketchybar"
    group = "macos"
    platform = "darwin"

    def consumed_slice(self, ctx: Context) -> dict[str, Any]:
        return {"roles": material_roles(ctx.palette, REQUIRED_ROLES)}

    def write_effects(self, ctx: Context) -> Effects:
        if ctx.dry_run:
            ok("sketchybar: would write colors_generated.lua")
            return Effects()
        roles = material_roles(ctx.palette, REQUIRED_ROLES)
        atomic_write(COLORS_GENERATED, colors_lua(roles))
        ok("sketchybar: colors_generated.lua written")
        slice = {"roles": roles}
        return Effects(
            reloads=[("sketchybar", {})],
            record=(
                "macos",
                "sketchybar",
                make_record(
                    slice_hash(self.consumed_slice(ctx)),
                    slice_hash(slice),
                    {},
                    {"colors_generated": {"roles": str(len(roles))}},
                ),
            ),
        )

    def status(self, ctx: Context) -> int:
        from theme.helpers.logio import note_state

        old = read_member("macos", "sketchybar")
        code = 0
        detail = None
        if not old or old.get("config_hash") != slice_hash(self.consumed_slice(ctx)):
            code |= 1
            detail = "no stamp or config changed"
        if COLORS_GENERATED.exists():
            if COLORS_GENERATED.read_text() != colors_lua(
                material_roles(ctx.palette, REQUIRED_ROLES)
            ):
                code |= 2
                detail = "colors_generated.lua stale vs palette"
        else:
            code |= 2
            detail = "colors_generated.lua missing"
        note_state(self.group, self.key, code, detail)
        return code

    def build(self, ctx: Context) -> dict[str, Any]:
        return {}
