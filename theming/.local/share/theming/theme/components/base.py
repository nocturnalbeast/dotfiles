"""Component ABC: the write_effects/status/build/uninstall contract."""

from __future__ import annotations

from abc import ABC, abstractmethod
from dataclasses import dataclass, field
from typing import Any

from theme.resources.base import Context


@dataclass
class Effects:
    """What write_effects produced: S1–S4 shared-surface kv (written
    centrally, never by members), managed S6 env lines, (kind, params)
    reloads, restart hints, and a member stamp record."""

    code: int = 0
    surfaces: dict[str, dict[str, Any]] = field(default_factory=dict)
    managed: list[tuple[str, str, str | None]] = field(default_factory=list)
    reloads: list[tuple[str, dict[str, Any]]] = field(default_factory=list)
    restart_hints: list[str] = field(default_factory=list)
    record: tuple[str, str, dict[str, Any]] | None = None


class Component(ABC):
    key: str = ""
    group: str = ""  # stamp file this member's record lives in; "" for groups
    write_deps: frozenset[str] = frozenset()  # ordering edges among parallel writes

    def __init_subclass__(cls, **kw: Any) -> None:
        super().__init_subclass__(**kw)

    def apply(self, ctx: Context) -> int:
        """Apply through the same run_members pipeline a group uses;
        exit code = max over members."""
        from theme.apply_phases import run_members

        return run_members(ctx, [self])

    @abstractmethod
    def write_effects(self, ctx: Context) -> Effects:
        """Builds + member-owned writes; returns contributions — NO
        shared-surface writes, NO reload signals (runner owns those)."""

    @abstractmethod
    def status(self, ctx: Context) -> int:
        """Three-way report contribution; read-only, no lock."""

    @abstractmethod
    def build(self, ctx: Context) -> dict[str, Any]:
        """Returns the new stamp record; caller persists it AFTER surfaces."""

    def uninstall(self, ctx: Context) -> None:
        raise NotImplementedError(f"{self.key}: uninstall not implemented")

    def upgrade(self, ctx: Context) -> int:
        return self.apply(ctx)
