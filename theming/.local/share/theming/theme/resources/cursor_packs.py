"""Cursor pack resources: bibata_modern, bibata_original, nordzy, breezex, colloid, fluent; params resolve from palette slots, never hardcoded."""

from __future__ import annotations

import shutil
import subprocess
import zipfile
from pathlib import Path

from theme.helpers.logio import console
from theme.palette import core_token, mode, resolve_accent, slot
from theme.resources.base import Context, Resource, SourceResult
from theme.sources import CACHE_DIR


class CursorPack(Resource):
    family = "cursor_packs"

    def base_dir(self, ctx: Context) -> Path:
        return ctx.icons_dir

    def params(self, ctx: Context) -> dict[str, str]:
        """Fill = foreground.bright (max-emphasis fg, not the wallpaper-faithful text token); outline = accent, watch = accent."""
        accent = resolve_accent(ctx.palette)
        return {
            "fill": core_token(ctx.palette, "foreground.bright"),
            "outline": accent,
            "watch": accent,
        }


class BibataBase(CursorPack):
    source_url = "https://github.com/ful1e5/Bibata_Cursor"
    shape = "svg/modern"  # per subclass

    @property
    def stable_name(self) -> str:
        raise NotImplementedError

    def install(self, ctx: Context, src: SourceResult) -> Path:
        name = self.stable_name
        p = self.params(ctx)
        bitmaps = src.path / "bitmaps" / name
        theme_out = src.path / "themes" / name

        # 1. statics via cbmp (npx; fetches toolchain on first run)
        r = subprocess.run(
            [
                "npx",
                "--yes",
                "cbmp",
                "-d",
                self.shape,
                "-o",
                f"bitmaps/{name}",
                "-bc",
                p["fill"],
                "-oc",
                p["outline"],
                "-wc",
                p["watch"],
            ],
            cwd=str(src.path),
            capture_output=True,
            text=True,
        )
        if r.returncode != 0:
            raise RuntimeError(f"{name}: cbmp render failed: {r.stderr[-300:]}")

        # 2. animated-frame transplant (mandatory, not a fallback):
        #    release bitmaps.zip → <variant>-Amber frames → magick recolor.
        amber = self._amber_frames(src, name)
        for frame in amber.iterdir():
            out_frame = bitmaps / frame.name
            r = subprocess.run(
                [
                    "magick",
                    str(frame),
                    "-fuzz",
                    "12%",
                    "-fill",
                    p["fill"],
                    "-opaque",
                    "#FF8300",
                    "-fill",
                    p["outline"],
                    "-opaque",
                    "#FFFFFF",
                    "-fill",
                    p["watch"],
                    "-opaque",
                    "#001524",
                    str(out_frame),
                ],
                capture_output=True,
                text=True,
            )
            if r.returncode != 0:
                raise RuntimeError(f"{name}: frame recolor failed on {frame.name}")

        # 3. normalize (ctgen rejects palette-mode PNGs)
        for png in bitmaps.glob("*.png"):
            subprocess.run(
                ["magick", "mogrify", "-define", "png:color-type=6", str(png)],
                capture_output=True,
                text=True,
            )

        # 4. compile with explicit -o (config's relative out_dir unreliable)
        if theme_out.exists():
            shutil.rmtree(theme_out)
        r = subprocess.run(
            [
                "uvx",
                "--from",
                "clickgen",
                "ctgen",
                str(src.path / "configs/normal/x.build.toml"),
                "-p",
                "x11",
                "-d",
                f"bitmaps/{name}",
                "-n",
                name,
                "-c",
                f"{name} XCursors",
                "-o",
                "themes",
            ],
            cwd=str(src.path),
            capture_output=True,
            text=True,
        )
        if r.returncode != 0:
            raise RuntimeError(f"{name}: ctgen failed: {r.stderr[-400:]}")

        # 5. gate: zero-byte shells are the corruption signature
        built = theme_out / "cursors"
        zero = (
            [f for f in built.iterdir() if f.stat().st_size == 0]
            if built.exists()
            else ["<missing>"]
        )
        if zero:
            raise RuntimeError(f"{name}: 0-byte cursors after build: {zero[:5]}")

        dest = ctx.icons_dir / name
        if dest.exists():
            shutil.rmtree(dest)
        shutil.copytree(theme_out, dest)
        return dest

    def _amber_frames(self, src: SourceResult, name: str) -> Path:
        variant = (
            "Bibata-Original-Amber" if "original" in self.key else "Bibata-Modern-Amber"
        )
        cache = CACHE_DIR / "bitmaps"
        cache.mkdir(parents=True, exist_ok=True)
        zf = cache / "bitmaps.zip"
        out = cache / variant
        if not out.exists() or not any(out.iterdir()):
            if not zf.exists() or zf.stat().st_size < 1000:
                zf.unlink(missing_ok=True)
                r = subprocess.run(
                    [
                        "gh",
                        "release",
                        "download",
                        "v2.0.7",
                        "-R",
                        "ful1e5/Bibata_Cursor",
                        "-p",
                        "bitmaps.zip",
                        "-D",
                        str(cache),
                    ],
                    capture_output=True,
                    text=True,
                )
                if r.returncode != 0 or not zf.exists() or zf.stat().st_size < 1000:
                    raise RuntimeError(
                        f"{name}: bitmaps.zip download failed: {r.stderr[-200:]}"
                    )
            out.mkdir(parents=True, exist_ok=True)
            with zipfile.ZipFile(zf) as z:
                members = [m for m in z.namelist() if f"/{variant}/" in m]
                z.extractall(cache, members=members)
        return out


class BibataModern(BibataBase):
    key = "bibata_modern"
    shape = "svg/modern"

    @property
    def stable_name(self) -> str:
        return "Bibata-Modern"

    naming = {"dark": "Bibata-Modern", "light": "Bibata-Modern"}


class BibataOriginal(BibataBase):
    key = "bibata_original"
    shape = "svg/original"

    @property
    def stable_name(self) -> str:
        return "Bibata-Original"

    naming = {"dark": "Bibata-Original", "light": "Bibata-Original"}


class NordzyCursors(CursorPack):
    key = "nordzy"
    source_url = "https://github.com/guillaumeboehm/Nordzy-cursors"
    naming = {"dark": "Nordzy", "light": "Nordzy"}

    @property
    def stable_name(self) -> str:
        return "Nordzy"

    def install(self, ctx: Context, src: SourceResult) -> Path:
        # upstream ships nordzy-templates/; one template + palette sed
        # produces both styles (body #000000 → foreground flips with mode)
        p = self.params(ctx)
        tools = src.path / "tools"
        theme_name = "theming-nordzy"
        sed_pairs = [
            ("#000000", p["fill"]),
            ("#ffffff", p["outline"]),
            ("#2e3440", core_token(ctx.palette, "background")),
            ("#ff0000", core_token(ctx.palette, "status.error")),
            ("#cc99cc", core_token(ctx.palette, "accent.alt")),
            ("#cccc99", core_token(ctx.palette, "status.warning")),
            ("#99cccc", core_token(ctx.palette, "status.info")),
        ]
        for stem in ("Nordzy-cursors", "Nordzy-cursors-spinner"):
            src_svg = tools / "svgs" / "nordzy-templates" / f"{stem}-template.svg"
            dst = (
                tools
                / "svgs"
                / "themes"
                / (
                    f"{theme_name}-spinner.svg"
                    if stem.endswith("spinner")
                    else f"{theme_name}.svg"
                )
            )
            if not src_svg.exists():
                raise RuntimeError(f"nordzy template missing: {src_svg}")
            text = src_svg.read_text()
            for old, new in sed_pairs:
                text = text.replace(old, new)
            dst.write_text(text)
        for svg in (
            tools / "svgs" / "themes" / f"{theme_name}.svg",
            tools / "svgs" / "themes" / f"{theme_name}-spinner.svg",
        ):
            r = subprocess.run(
                ["python3", str(tools / "render-pngs.py"), str(svg)],
                cwd=str(tools),
                capture_output=True,
                text=True,
            )
            if r.returncode != 0:
                raise RuntimeError(f"nordzy render failed: {r.stderr[-300:]}")
        r = subprocess.run(
            ["bash", str(tools / "make.sh"), theme_name],
            cwd=str(tools),
            capture_output=True,
            text=True,
        )
        if r.returncode != 0:
            raise RuntimeError(f"nordzy make failed: {r.stderr[-300:]}")
        built = tools / theme_name / "cursors"
        zero = [f for f in built.iterdir() if f.stat().st_size == 0]
        if zero:
            raise RuntimeError(f"nordzy: 0-byte cursors: {zero[:5]}")
        dest = ctx.icons_dir / self.stable_name
        if dest.exists():
            shutil.rmtree(dest)
        shutil.copytree(tools / theme_name, dest)
        return dest


class BreezeXCursors(CursorPack):
    key = "breezex"
    source_url = "https://github.com/rose-pine/cursors"
    naming = {"dark": "BreezeX", "light": "BreezeX"}

    @property
    def stable_name(self) -> str:
        return "BreezeX"

    def install(self, ctx: Context, src: SourceResult) -> Path:
        name = self.stable_name
        p = self.params(ctx)
        r = subprocess.run(
            [
                "npx",
                "--yes",
                "cbmp",
                "-d",
                "svg",
                "-o",
                f"bitmaps/{name}",
                "-bc",
                p["fill"],
                "-oc",
                p["outline"],
            ],
            cwd=str(src.path),
            capture_output=True,
            text=True,
        )
        if r.returncode != 0:
            raise RuntimeError(f"breezex cbmp failed: {r.stderr[-300:]}")
        # animated transplant: repo ships no animated SVGs; dark mode →
        # RoséPineDawn frames (light-styled), light → RoséPine (dark-styled)
        if mode(ctx.palette) == "dark":
            shipped = src.path / "bitmaps" / "BreezeX-RoséPineDawn"
            light_anchor, dark_anchor = "#faf4ed", "#575279"
        else:
            shipped = src.path / "bitmaps" / "BreezeX-RoséPine"
            light_anchor, dark_anchor = "#e0def4", "#191724"
        for stem in ("left_ptr_watch", "wait"):
            for frame in sorted(shipped.glob(f"{stem}-*.png")):
                out_frame = src.path / "bitmaps" / name / frame.name
                subprocess.run(
                    [
                        "magick",
                        str(frame),
                        "-fuzz",
                        "12%",
                        "-fill",
                        p["fill"],
                        "-opaque",
                        light_anchor,
                        "-fill",
                        p["outline"],
                        "-opaque",
                        dark_anchor,
                        str(out_frame),
                    ],
                    check=True,
                    capture_output=True,
                    text=True,
                )
        for png in (src.path / "bitmaps" / name).glob("*.png"):
            subprocess.run(
                ["magick", "mogrify", "-define", "png:color-type=6", str(png)],
                capture_output=True,
                text=True,
            )
        r = subprocess.run(
            [
                "uvx",
                "--from",
                "clickgen",
                "ctgen",
                "build.toml",
                "-d",
                f"bitmaps/{name}",
                "-n",
                name,
                "-c",
                f"{name} cursors.",
                "-o",
                "themes",
            ],
            cwd=str(src.path),
            capture_output=True,
            text=True,
        )
        if r.returncode != 0:
            raise RuntimeError(f"breezex ctgen failed: {r.stderr[-400:]}")
        dest = ctx.icons_dir / name
        if dest.exists():
            shutil.rmtree(dest)
        shutil.copytree(src.path / "themes" / name, dest)
        return dest


class PrebuiltCursors(CursorPack):
    """Install the stock dist(-dark) shipped in the upstream repo."""

    repo_subpath = "cursors"

    def install(self, ctx: Context, src: SourceResult) -> Path:
        dist = (
            src.path
            / self.repo_subpath
            / ("dist-dark" if mode(ctx.palette) == "dark" else "dist")
        )
        if not dist.exists():
            raise RuntimeError(f"{self.key}: prebuilt dist missing in source")
        dest = ctx.icons_dir / self.naming_for(ctx)
        if dest.exists():
            shutil.rmtree(dest)
        shutil.copytree(dist, dest)
        return dest


class ColloidCursors(PrebuiltCursors):
    key = "colloid"
    source_url = "https://github.com/vinceliuice/Colloid-icon-theme"
    naming = {"dark": "Colloid-Cursors", "light": "Colloid-Cursors"}


class FluentCursors(PrebuiltCursors):
    key = "fluent"
    source_url = "https://github.com/vinceliuice/Fluent-icon-theme"
    naming = {"dark": "Fluent-Cursors", "light": "Fluent-Cursors"}
