"""ComponentGroup: composite dispatch over members via run_members."""

from __future__ import annotations

from typing import Any

from theme.components.base import Component
from theme.resources.base import Context


class ComponentGroup(Component):
    """Composite over members; no own stamp — members stamp into their group's file."""

    members: list[Component] = []

    def apply(self, ctx: Context) -> int:
        from theme.apply_phases import run_members

        return run_members(ctx, list(self.members))

    def write_effects(self, ctx: Context):  # type: ignore[override]
        raise RuntimeError("groups are dispatched via apply, not write_effects")

    def status(self, ctx: Context) -> int:
        code = 0
        for member in self.members:
            code = max(code, member.status(ctx))
        return code

    def build(self, ctx: Context) -> dict[str, Any]:
        return {m.key: m.build(ctx) for m in self.members}

    def uninstall(self, ctx: Context) -> None:
        for member in self.members:
            member.uninstall(ctx)
