"""Kvantum theme resources: colloid, orchis, materia - palette-injected KDE ports written to ~/.config/Kvantum/theming/."""

from __future__ import annotations

import re
import shutil
from pathlib import Path

from theme.engines.base import ramp_mix
from theme.palette import core_token
from theme.resources.base import Context, Resource, SourceResult

HOME = Path.home()
KVANTUM_CONFIG_DIR = HOME / ".config/Kvantum"
THEMING_THEME_DIR = KVANTUM_CONFIG_DIR / "theming"

# ladder stops (bg→fg mix ratios - ColloidDark's relative offsets)
LADDER = {
    "window": 0.06,
    "alt_base": 0.08,
    "button": 0.15,
    "light": 0.18,
    "mid_light": 0.13,
    "mid": 0.10,
    "dark": 0.03,
}

# kvconfig key -> role in our palette terms ('' = literal handling below)
KVCONFIG_MAP = {
    "window.color": ("ramp", "window"),
    "alt.base.color": ("ramp", "alt_base"),
    "button.color": ("ramp", "button"),
    "light.color": ("ramp", "light"),
    "mid.light.color": ("ramp", "mid_light"),
    "mid.color": ("ramp", "mid"),
    "dark.color": ("ramp", "dark"),
    "base.color": ("token", "background"),
    "text.color": ("token", "foreground"),
    "window.text.color": ("token", "foreground"),
    "button.text.color": ("token", "foreground"),
    "tooltip.text.color": ("token", "foreground"),
    "progress.indicator.text.color": ("token", "foreground"),
    "disabled.text.color": ("token", "foreground.subtle"),
    "highlight.text.color": ("token", "background"),
    "link.color": ("token", "accent"),
    "link.visited.color": ("token", "accent.alt"),
    "highlight.color": ("accent", None),
    "inactive.highlight.color": ("accent_dim", None),
}

_HEX6 = re.compile(r"^#[0-9a-fA-F]{6}$")


def _palette_values(ctx: Context) -> dict[str, str]:
    bg = core_token(ctx.palette, "background")
    fg = core_token(ctx.palette, "foreground")
    vals = {
        "background": bg,
        "foreground": fg,
        "foreground.subtle": core_token(ctx.palette, "foreground.subtle"),
        "accent": core_token(ctx.palette, "accent"),
        "accent.alt": core_token(ctx.palette, "accent.alt"),
        "accent_dim": ramp_mix(core_token(ctx.palette, "accent"), bg, 0.35),
    }
    for name, t in LADDER.items():
        vals[f"ramp:{name}"] = ramp_mix(bg, fg, t)
    return vals


class KvantumTheme(Resource):
    family = "kvantum_themes"
    source_subpath = ""
    dark_pair: tuple[str, str] = ("", "")
    light_pair: tuple[str, str] = ("", "")
    svg_anchors: dict[str, tuple[str, str]] = {}

    def base_dir(self, ctx: Context) -> Path:
        return KVANTUM_CONFIG_DIR

    def naming_for(self, ctx: Context) -> str:
        return "theming"

    def install(self, ctx: Context, src: SourceResult) -> Path:
        from theme.palette import mode

        m = mode(ctx.palette)
        kv_name, svg_name = self.dark_pair if m == "dark" else self.light_pair
        src_dir = src.path / self.source_subpath
        kv_src = src_dir / kv_name
        svg_src = src_dir / svg_name
        for f in (kv_src, svg_src):
            if not f.exists():
                raise RuntimeError(f"{self.key}: upstream pair missing: {f}")

        vals = _palette_values(ctx)

        # 1. kvconfig key-targeted rewrite (NOT hex-sed: window/base share a hex upstream)
        out_lines = []
        for line in kv_src.read_text().splitlines():
            matched = False
            if "=" in line and not line.startswith("#"):
                key, _, value = line.partition("=")
                role = KVCONFIG_MAP.get(key.strip())
                if role is not None:
                    kind, arg = role
                    if kind == "ramp":
                        new = vals[f"ramp:{arg}"]
                    elif kind == "token":
                        new = vals[arg]
                    elif kind == "accent":
                        new = vals["accent"]
                    else:
                        new = vals["accent_dim"]
                    old = value.strip()
                    suffix = ""
                    if old.startswith("#") and len(old) == 9:
                        suffix = old[
                            7:
                        ]  # materia 8-digit alpha hex: replace color prefix, keep alpha suffix
                    if old.lower() == "white":
                        old, suffix = "#ffffff", ""
                    out_lines.append(f"{key}={new}{suffix}")
                    matched = True
            if not matched:
                out_lines.append(line)

        # 2. SVG anchor sed (zero-match on any anchor = hard error)
        svg = svg_src.read_text()
        from theme.palette import mode as _mode

        anchors = self.svg_anchors
        if _mode(ctx.palette) == "light" and self.light_svg_anchors:
            anchors = self.light_svg_anchors
        for anchor, (kind, arg) in anchors.items():
            new = vals[f"ramp:{arg}"] if kind == "ramp" else vals[arg]
            count = svg.lower().count(anchor.lower())
            if count == 0:
                raise RuntimeError(
                    f"{self.key}: SVG anchor {anchor} found 0 times - "
                    "upstream changed; anchor map stale"
                )
            svg = re.sub(re.escape(anchor), new, svg, flags=re.IGNORECASE)

        # 3. emit
        THEMING_THEME_DIR.mkdir(parents=True, exist_ok=True)
        (THEMING_THEME_DIR / "theming.kvconfig").write_text("\n".join(out_lines) + "\n")
        (THEMING_THEME_DIR / "theming.svg").write_text(svg)
        return THEMING_THEME_DIR


class ColloidKvantum(KvantumTheme):
    key = "colloid"
    source_url = "https://github.com/vinceliuice/Colloid-kde"
    source_subpath = "Kvantum/Colloid"
    dark_pair = ("ColloidDark.kvconfig", "ColloidDark.svg")
    light_pair = ("Colloid.kvconfig", "Colloid.svg")
    svg_anchors = {
        "#5b9bf8": ("token", "accent"),
        "#b74aff": ("token", "accent.alt"),
        "#2c2c2c": ("token", "background"),
        "#414141": ("ramp", "button"),
        "#242424": ("ramp", "dark"),
        "#dfdfdf": ("token", "foreground"),
        "#c1c1c1": ("token", "foreground.subtle"),
        "#1a1a1a": ("ramp", "mid"),
    }
    light_svg_anchors = {
        "#3c84f7": ("token", "accent"),
        "#b74aff": ("token", "accent.alt"),
        "#f2f2f2": ("ramp", "button"),
        "#e6e6e6": ("ramp", "mid"),
        "#c1c1c1": ("token", "foreground.subtle"),
    }


class OrchisKvantum(KvantumTheme):
    key = "orchis"
    source_url = "https://github.com/vinceliuice/Orchis-kde"
    source_subpath = "Kvantum/Orchis"
    dark_pair = ("OrchisDark.kvconfig", "OrchisDark.svg")
    light_pair = ("Orchis.kvconfig", "Orchis.svg")
    svg_anchors = {
        "#4285f4": ("token", "accent"),
        "#3daee6": ("token", "accent_dim"),
        "#dfdfdf": ("token", "foreground"),
        "#1e1e1e": ("ramp", "window"),
        "#262626": ("ramp", "button"),
        "#1a1a1a": ("ramp", "mid"),
        "#0f0f0f": ("ramp", "dark"),
    }
    light_svg_anchors = {
        "#3281ea": ("token", "accent"),
        "#2073f4": ("token", "accent_dim"),
        "#b74aff": ("token", "accent.alt"),
        "#646464": ("token", "foreground.subtle"),
        "#9b9b9b": ("ramp", "mid"),
        "#d2d2d2": ("ramp", "button"),
    }


class MateriaKvantum(KvantumTheme):
    key = "materia"
    source_url = "https://github.com/PapirusDevelopmentTeam/materia-kde"
    source_subpath = "Kvantum/MateriaDark"
    dark_pair = ("MateriaDark.kvconfig", "MateriaDark.svg")
    light_pair = (
        "../MateriaLight/MateriaLight.kvconfig",
        "../MateriaLight/MateriaLight.svg",
    )
    svg_anchors = {
        "#8ab4f8": ("token", "accent"),
        "#dfdfdf": ("token", "foreground"),
        "#2e2e2e": ("token", "background"),
        "#616161": ("ramp", "mid"),
        "#121212": ("ramp", "dark"),
    }
    light_svg_anchors = {
        "#1a73e8": ("token", "accent"),
        "#414c52": ("token", "foreground"),
        "#616161": ("ramp", "mid"),
        "#f9f9f9": ("token", "background"),
        "#f5f5f5": ("ramp", "window"),
        "#d8d8d8": ("ramp", "button"),
    }
