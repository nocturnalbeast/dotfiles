"""Icon pack resources: tela, tela_circle, fluent, nordzy, colloid; recolor via native hex arg + rename (class a) or post-install base-hex sed (class b)."""

from __future__ import annotations

import re
import shutil
import subprocess
from pathlib import Path

from theme.helpers.logio import warn
from theme.palette import mode, resolve_accent
from theme.resources.base import Context, Resource, SourceResult


class IconPack(Resource):
    family = "icon_packs"
    base_hex: str = ""

    def base_dir(self, ctx: Context) -> Path:
        return ctx.icons_dir

    def post_install(self, ctx: Context, theme_dir: Path) -> None:
        """Sed only files containing the pack's base hex — the anchor itself scopes the rewrite, so no dir allowlist is needed."""
        accent = resolve_accent(ctx.palette)
        anchor = self.base_hex.lower()
        found = 0
        import os as _os

        for dirpath, _dirs, files in _os.walk(theme_dir, followlinks=True):
            for fname in files:
                if not fname.endswith(".svg"):
                    continue
                fpath = Path(dirpath) / fname
                try:
                    text = fpath.read_text()
                except OSError:
                    continue
                if anchor in text.lower():
                    fpath.write_text(re.sub(anchor, accent, text, flags=re.IGNORECASE))
                    found += 1
        if found == 0:
            raise RuntimeError(
                f"{self.key}: sed found 0 occurrences of base hex {anchor} — "
                "upstream anchor changed; resource class stale"
            )


class TelaBase(IconPack):
    def _install(self, ctx: Context, src: SourceResult, extra: list[str]) -> None:
        cmd = [
            "bash",
            str(src.path / "install.sh"),
            "-d",
            str(ctx.icons_dir),
            *extra,
        ]
        r = subprocess.run(cmd, capture_output=True, text=True)
        if r.returncode != 0:
            raise RuntimeError(f"{self.key} install failed: {r.stderr[-300:]}")

    def install(self, ctx: Context, src: SourceResult) -> Path:
        raise NotImplementedError


class Tela(TelaBase):
    key = "tela"
    source_url = "https://github.com/vinceliuice/Tela-icon-theme"
    naming = {"dark": "Tela-dark", "light": "Tela-light"}
    base_hex = "#5294e2"

    def install(self, ctx: Context, src: SourceResult) -> Path:
        self._install(ctx, src, [])
        theme_dir = ctx.icons_dir / self.naming_for(ctx)
        self.post_install(ctx, theme_dir)
        return theme_dir


class TelaCircle(TelaBase):
    key = "tela_circle"
    source_url = "https://github.com/vinceliuice/Tela-circle-icon-theme"
    naming = {"dark": "Tela-Circle-dark", "light": "Tela-Circle-light"}
    base_hex = "#5294e2"

    def install(self, ctx: Context, src: SourceResult) -> Path:
        # class a: native hex arg; upstream hex-embedded dirs are renamed
        # to the stable name on install
        accent = resolve_accent(ctx.palette)[1:].upper()
        self._install(ctx, src, [accent])
        upstream = ctx.icons_dir / f"Tela-circle-{accent}-{mode(ctx.palette)}"
        stable = ctx.icons_dir / f"Tela-Circle-{mode(ctx.palette)}"
        if upstream.exists():
            if stable.exists():
                shutil.rmtree(stable)
            upstream.rename(stable)
            # siblings (-light/-dark) from the same install
            for sibling in upstream.parent.glob(f"Tela-circle-{accent}-*"):
                tag = sibling.name.split(f"{accent}-", 1)[1]
                target = sibling.parent / f"Tela-Circle-{tag}"
                if not target.exists():
                    sibling.rename(target)
        else:
            raise RuntimeError(
                f"tela_circle: upstream {upstream.name} not found after install"
            )
        self.post_install(ctx, stable)
        return stable


class FluentIcons(IconPack):
    key = "fluent"
    source_url = "https://github.com/vinceliuice/Fluent-icon-theme"
    naming = {"dark": "Fluent-dark", "light": "Fluent-light"}
    base_hex = "#198ee6"

    def install(self, ctx: Context, src: SourceResult) -> Path:
        r = subprocess.run(
            ["bash", str(src.path / "install.sh"), "-d", str(ctx.icons_dir)],
            capture_output=True,
            text=True,
        )
        if r.returncode != 0:
            raise RuntimeError(f"fluent install failed: {r.stderr[-300:]}")
        theme_dir = ctx.icons_dir / self.naming_for(ctx)
        self.post_install(ctx, theme_dir)
        return theme_dir


class NordzyIcons(IconPack):
    key = "nordzy"
    source_url = "https://github.com/MolassesLover/Nordzy-icon"
    naming = {"dark": "Nordzy-dark", "light": "Nordzy"}
    base_hex = "#81A1C1"

    def install(self, ctx: Context, src: SourceResult) -> Path:
        r = subprocess.run(
            ["bash", str(src.path / "install.sh"), "-d", str(ctx.icons_dir)],
            capture_output=True,
            text=True,
        )
        if r.returncode != 0:
            raise RuntimeError(f"nordzy install failed: {r.stderr[-300:]}")
        theme_dir = ctx.icons_dir / self.naming_for(ctx)
        self.post_install(ctx, theme_dir)
        return theme_dir


class ColloidIcons(IconPack):
    key = "colloid"
    source_url = "https://github.com/vinceliuice/Colloid-icon-theme"
    naming = {"dark": "Colloid-Dark", "light": "Colloid-Light"}
    base_hex = "#60c0f0"

    def install(self, ctx: Context, src: SourceResult) -> Path:
        r = subprocess.run(
            ["bash", str(src.path / "install.sh"), "-d", str(ctx.icons_dir)],
            capture_output=True,
            text=True,
        )
        if r.returncode != 0:
            raise RuntimeError(f"colloid icons install failed: {r.stderr[-300:]}")
        theme_dir = ctx.icons_dir / self.naming_for(ctx)
        self.post_install(ctx, theme_dir)
        return theme_dir
