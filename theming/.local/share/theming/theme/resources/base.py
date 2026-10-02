"""Resource ABC + registries: attrs (source/naming/anchors) + bespoke recipes per pack class; new pack = new class."""

from __future__ import annotations

from abc import ABC, abstractmethod
from dataclasses import dataclass, field
from pathlib import Path
from typing import Any

from theme.sources import SourceResult, ensure_source
from theme.state import CACHE_DIR

GTK_THEMES: dict[str, type["Resource"]] = {}
ICON_PACKS: dict[str, type["Resource"]] = {}
CURSOR_PACKS: dict[str, type["Resource"]] = {}
KVANTUM_THEMES: dict[str, type["Resource"]] = {}


@dataclass
class Context:
    """What a Resource/Component sees. Constructed by the CLI layer."""

    config: dict[str, Any]
    palette: dict[str, Any]
    dry_run: bool = False
    offline: bool = False
    force: bool = False
    no_build: bool = False
    log: list[str] = field(default_factory=list)
    restart_hints: list[str] = field(default_factory=list)
    jobs: int = 1

    @property
    def themes_dir(self) -> Path:
        return Path.home() / ".local/share/themes"

    @property
    def icons_dir(self) -> Path:
        return Path.home() / ".local/share/icons"


class Resource(ABC):
    key: str = ""
    family: str = ""
    source_url: str = ""
    naming: dict[str, str] = field(default_factory=dict)

    def __init_subclass__(cls, **kw: Any) -> None:
        super().__init_subclass__(**kw)
        if not cls.key:
            return
        registries = {
            "gtk_themes": GTK_THEMES,
            "icon_packs": ICON_PACKS,
            "cursor_packs": CURSOR_PACKS,
            "kvantum_themes": KVANTUM_THEMES,
        }
        reg = registries.get(cls.family)
        if reg is None:
            raise TypeError(f"{cls.__name__}: unknown family {cls.family!r}")
        reg[cls.key] = cls

    # -- source management ------------------------------------------------
    def ensure_source(self, ctx: Context) -> SourceResult:
        from theme.sources import ensure_source as _ensure

        return _ensure(
            self.key, self.source_url, ctx.offline, ctx.dry_run, family=self.family
        )

    # -- recipes -----------------------------------------------------------
    @abstractmethod
    def install(self, ctx: Context, src: SourceResult) -> Path:
        """Build/install the artifact; returns the installed theme dir."""

    def naming_for(self, ctx: Context) -> str:
        from theme.palette import mode

        return self.naming[mode(ctx.palette)]

    def installed_dirs(self, ctx: Context) -> list[Path]:
        return [self.base_dir(ctx) / n for n in self.naming.values()]

    def base_dir(self, ctx: Context) -> Path:
        raise NotImplementedError
