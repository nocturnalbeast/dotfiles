"""GTK theme resources: colloid, orchis, materia; nearest accent variant = min RGB distance to the mode-matched anchor (ties → default)."""

from __future__ import annotations

import shutil
import subprocess
from pathlib import Path

from theme.helpers.convert import rgb_distance
from theme.helpers.logio import console
from theme.palette import core_token, mode, resolve_accent, slot
from theme.resources.base import Context, Resource, SourceResult


class VinceliuiceGTK(Resource):
    family = "gtk_themes"
    tweaks_supported: list[str] = []

    def install(self, ctx: Context, src: SourceResult) -> Path:
        raise NotImplementedError


class ColloidGTK(VinceliuiceGTK):
    key = "colloid"
    source_url = "https://github.com/vinceliuice/Colloid-gtk-theme"
    naming = {"dark": "Colloid-Dark", "light": "Colloid-Light"}
    tweaks_supported = ["black", "rimless", "normal", "float"]
    accents = {
        "default": ("#5b9bf8", "#3c84f7"),
        "purple": ("#BA68C8", "#AB47BC"),
        "pink": ("#F06292", "#EC407A"),
        "red": ("#F44336", "#E53935"),
        "orange": ("#FF8A65", "#FF7043"),
        "yellow": ("#FFD600", "#FBC02D"),
        "green": ("#66BB6A", "#4CAF50"),
        "teal": ("#4DB6AC", "#009688"),
        "grey": ("#727272", "#727272"),
    }

    def install(self, ctx: Context, src: SourceResult) -> Path:
        tweaks = [t for t in ctx.config["gui"]["tweaks"]]
        unknown = [t for t in tweaks if t not in self.tweaks_supported]
        if unknown:
            raise ValueError(f"colloid: unsupported tweaks {unknown}")
        accent_variant = self.nearest_accent(ctx)
        cmd = [
            "bash",
            str(src.path / "install.sh"),
            "--dest",
            str(ctx.themes_dir),
            "-c",
            mode(ctx.palette),
            "-s",
            ctx.config["gui"]["size"],
            "-t",
            accent_variant,
            "--tweaks",
            *tweaks,
        ]
        r = subprocess.run(cmd, capture_output=True, text=True)
        if r.returncode != 0:
            raise RuntimeError(f"colloid install failed: {r.stderr[-400:]}")
        return ctx.themes_dir / self.naming_for(ctx)

    def nearest_accent(self, ctx: Context) -> str:
        accent = resolve_accent(ctx.palette)
        is_dark = mode(ctx.palette) == "dark"
        best, best_d = "default", float("inf")
        for name, (light_hex, dark_hex) in self.accents.items():
            anchor = dark_hex if is_dark else light_hex
            d = rgb_distance(accent, anchor)
            if d < best_d:
                best, best_d = name, d
        return best

    def base_dir(self, ctx: Context) -> Path:
        return ctx.themes_dir


class OrchisGTK(VinceliuiceGTK):
    key = "orchis"
    source_url = "https://github.com/vinceliuice/Orchis-theme"
    naming = {"dark": "Orchis-Dark", "light": "Orchis-Light"}
    tweaks_supported = ["black", "primary", "solid", "macos", "submenu"]

    def install(self, ctx: Context, src: SourceResult) -> Path:
        tweaks = [t for t in ctx.config["gui"]["tweaks"]]
        unknown = [t for t in tweaks if t not in self.tweaks_supported]
        if unknown:
            raise ValueError(f"orchis: unsupported tweaks {unknown} (no rimless)")
        cmd = [
            "bash",
            str(src.path / "install.sh"),
            "--dest",
            str(ctx.themes_dir),
            "-c",
            mode(ctx.palette),
            "-s",
            ctx.config["gui"]["size"],
            "--tweaks",
            *tweaks,
        ]
        r = subprocess.run(cmd, capture_output=True, text=True)
        if r.returncode != 0:
            raise RuntimeError(f"orchis install failed: {r.stderr[-400:]}")
        return ctx.themes_dir / self.naming_for(ctx)

    def base_dir(self, ctx: Context) -> Path:
        return ctx.themes_dir


class MateriaGTK(Resource):
    key = "materia"
    family = "gtk_themes"
    source_url = "https://github.com/nana-4/materia-theme"
    naming = {
        "dark": "Materia-dark",
        "light": "Materia-light",
        "standard": "Materia",
    }
    # normative adapter table
    adapter_keys = (
        "BG",
        "FG",
        "HDR_BG",
        "HDR_FG",
        "SEL_BG",
        "SEL_FG",
        "MATERIA_VIEW",
        "MATERIA_SURFACE",
        "MATERIA_COLOR_VARIANT",
        "ROUNDNESS",
        "SPACING",
        "MATERIA_PANEL_OPACITY",
        "MATERIA_SELECTION_OPACITY",
    )

    def install(self, ctx: Context, src: SourceResult) -> Path:
        for tool in ("meson", "ninja"):
            if not shutil.which(tool):
                raise RuntimeError(f"materia: {tool} missing (doctor)")
        accent = resolve_accent(ctx.palette)
        fg = core_token(ctx.palette, "foreground")
        bg = core_token(ctx.palette, "background")
        bg_subtle = core_token(ctx.palette, "background.subtle")
        preset = (
            "\n".join(
                [
                    f"BG={bg[1:]}",
                    f"FG={fg[1:]}",
                    f"HDR_BG={bg_subtle[1:]}",
                    f"HDR_FG={fg[1:]}",
                    f"SEL_BG={accent[1:]}",
                    f"SEL_FG={bg[1:]}",
                    f"MATERIA_VIEW={bg[1:]}",
                    f"MATERIA_SURFACE={bg_subtle[1:]}",
                    f"MATERIA_COLOR_VARIANT={mode(ctx.palette)}",
                    "ROUNDNESS=4",
                    "SPACING=3",
                    "MATERIA_PANEL_OPACITY=1",
                    "MATERIA_SELECTION_OPACITY=0.32",
                ]
            )
            + "\n"
        )
        preset_path = src.path / "theming.preset"
        if not ctx.dry_run:
            preset_path.write_text(preset)
            r = subprocess.run(
                [
                    "bash",
                    str(src.path / "change_color.sh"),
                    "-o",
                    "theming-build",
                    "-t",
                    str(ctx.themes_dir),
                    str(preset_path),
                ],
                cwd=str(src.path),
                capture_output=True,
                text=True,
            )
            if r.returncode != 0:
                raise RuntimeError(f"materia build failed: {r.stderr[-400:]}")
        built = ctx.themes_dir / "theming-build"
        stable = ctx.themes_dir / self.naming_for(ctx)
        if stable.exists():
            shutil.rmtree(stable)
        built.rename(stable)
        return stable

    def naming_for(self, ctx: Context) -> str:
        return self.naming[mode(ctx.palette)]

    def base_dir(self, ctx: Context) -> Path:
        return ctx.themes_dir
