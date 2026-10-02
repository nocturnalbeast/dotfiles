"""Qt member: Q1–Q6 — qt6ct platformtheme, Kvantum/Fusion dual-mode, kdeglobals, managed env line."""

from __future__ import annotations

import shutil
from pathlib import Path
from typing import Any

from theme.components.base import Component, Effects
from theme.engines.base import ramp_mix
from theme.helpers import writers
from theme.helpers.logio import atomic_write, fail, ok, warn
from theme.palette import core_token, mode, resolve_accent, slice_hash
from theme.resources.base import Context
from theme.state import make_record, read_member

HOME = Path.home()
QT6CT_CONF = HOME / ".config/qt6ct/qt6ct.conf"
QT6CT_COLORS = HOME / ".config/qt6ct/colors/theming.colors"
KVANTUM_KVCONFIG = HOME / ".config/Kvantum/kvantum.kvconfig"
KDEGLOBALS = HOME / ".config/kdeglobals"
ENV_FILE = HOME / ".config/profile.d/gui/00-theming.sh"

KVANTUM_ENGINE = Path("/usr/lib64/qt6/plugins/styles/libkvantum.so")

# fusion 21-slot serialization order: (core token, qt color role)
_FUSION_SLOTS = [
    ("foreground", "WindowText"),
    ("background.subtle", "Button"),
    ("background.selection", "Light"),
    ("background.subtle", "Midlight"),
    ("foreground.subtle", "Dark"),
    ("background.subtle", "Mid"),
    ("foreground", "Text"),
    ("bright", "BrightText"),
    ("foreground", "ButtonText"),
    ("background", "Base"),
    ("background.subtle", "Window"),
    ("background.subtle", "AlternateBase"),
    ("accent", "Highlight"),
    ("background", "HighlightedText"),
    ("accent", "Link"),
    ("accent.alt", "LinkVisited"),
    ("background", "ToolTipBase"),
    ("foreground.subtle", "Shadow"),
    ("foreground.subtle", "PlaceholderText"),
    ("foreground", "ToolTipText"),
    ("foreground.subtle", "trailing"),
]


def _shift(hex_color: str, t: float) -> str:
    from theme.helpers.convert import shift_lightness

    return shift_lightness(hex_color, t, 0.95 if t > 0 else 0.05)


class QtComponent(Component):
    key = "qt"
    group = "qt"
    platform = "linux"

    def consumed_slice(self, ctx: Context) -> dict[str, Any]:
        return {
            "style": ctx.config["qt"]["style"],
            "gtk_theme": ctx.config["gui"]["theme"],
            "palette_mode": mode(ctx.palette),
            "accent": resolve_accent(ctx.palette),
            "icon_theme": self._icon_theme_name(ctx),
            "sans": ctx.config["fonts"]["sans"][0],
            "font_size": ctx.config["gui"]["font_size"],
        }

    def _icon_theme_name(self, ctx: Context) -> str:
        from theme.resources.base import ICON_PACKS

        pack_key = ctx.config["gui"]["icon_pack"]
        if pack_key:
            return ICON_PACKS[pack_key]().naming_for(ctx)
        return ctx.config["gui"]["icon_theme"]

    # -- surfaces ---------------------------------------------------------

    def _write_q1(self, ctx: Context, style: str, scheme_path: str | None) -> None:
        """Partial qt6ct.conf rewrite: owned keys only; other
        sections preserved byte-for-byte."""
        font = f"{ctx.config['fonts']['sans'][0]},{ctx.config['gui']['font_size']},-1,5,400,0,0,0,0,0,0,0,0,0,0,1"
        updates_appearance = {
            "style": style,
            "icon_theme": self._icon_theme_name(ctx),
        }
        updates_appearance["color_scheme_path"] = scheme_path
        updates_appearance["custom_palette"] = "true" if style == "Fusion" else "false"

        text = (
            writers.read_surface(QT6CT_CONF)
            if QT6CT_CONF.exists()
            else ("[Appearance]\n[Fonts]\n[Interface]\n")
        )
        lines = text.splitlines()
        section = ""
        seen: set[str] = set()
        out: list[str] = []
        for line in lines:
            stripped = line.strip()
            if stripped.startswith("[") and stripped.endswith("]"):
                section = stripped
                out.append(line)
                continue
            if "=" in line and not stripped.startswith("#"):
                key = line.split("=", 1)[0].strip()
                if section == "[Appearance]" and key in updates_appearance:
                    out.append(f"{key}={updates_appearance[key]}")
                    seen.add(key)
                    continue
                if section == "[Fonts]" and key in ("fixed", "general"):
                    out.append(f'{key}="{font}"')
                    seen.add(key)
                    continue
            out.append(line)
        # append missing owned keys into their sections
        for key, value in updates_appearance.items():
            if key not in seen:
                self._append_to_section(out, "[Appearance]", f"{key}={value}")
        for key in ("fixed", "general"):
            if key not in seen:
                self._append_to_section(out, "[Fonts]", f'{key}="{font}"')
        atomic_write(
            QT6CT_CONF, "\n".join(out) + ("\n" if out and out[-1] != "" else "\n")
        )

    @staticmethod
    def _append_to_section(lines: list[str], section: str, entry: str) -> None:
        try:
            idx = lines.index(section)
        except ValueError:
            lines.append(section)
            lines.append(entry)
            return
        insert_at = idx + 1
        while (
            insert_at < len(lines)
            and lines[insert_at].strip()
            and not lines[insert_at].startswith("[")
        ):
            insert_at += 1
        lines.insert(insert_at, entry)

    def _write_q2_fusion(self, ctx: Context) -> str:
        """Generate the qt6ct 21-slot scheme; returns the path for Q1."""
        vals = {
            "foreground": core_token(ctx.palette, "foreground"),
            "foreground.subtle": core_token(ctx.palette, "foreground.subtle"),
            "background": core_token(ctx.palette, "background"),
            "background.subtle": core_token(ctx.palette, "background.subtle"),
            "background.selection": core_token(ctx.palette, "background.selection"),
            "accent": core_token(ctx.palette, "accent"),
            "accent.alt": core_token(ctx.palette, "accent.alt"),
            "bright": _shift(core_token(ctx.palette, "foreground"), 0.15),
        }
        active = [vals[slot] for slot, _ in _FUSION_SLOTS]
        disabled = [
            _shift(c, -0.15 if mode(ctx.palette) == "dark" else 0.15) for c in active
        ]
        content = (
            "[ColorScheme]\n"
            f"active_colors={','.join(active)}\n"
            f"disabled_colors={','.join(disabled)}\n"
            f"inactive_colors={','.join(active)}\n"
        )
        QT6CT_COLORS.parent.mkdir(parents=True, exist_ok=True)
        atomic_write(QT6CT_COLORS, content)
        return str(QT6CT_COLORS)

    def _write_q3(self) -> None:
        text = (
            writers.read_surface(KVANTUM_KVCONFIG) if KVANTUM_KVCONFIG.exists() else ""
        )
        if "theme=theming" not in text:
            text = writers.update_eq_kv(text, {"theme": "theming"})
        atomic_write(KVANTUM_KVCONFIG, text)

    def _write_q5(self, ctx: Context) -> None:
        """kdeglobals palette groups for KF6 apps (foreign keys preserved)."""
        fg = core_token(ctx.palette, "foreground")
        bg = core_token(ctx.palette, "background")
        bg_sub = core_token(ctx.palette, "background.subtle")
        accent = core_token(ctx.palette, "accent")
        fg_sub = core_token(ctx.palette, "foreground.subtle")

        def block(pairs: list[tuple[str, str]]) -> str:
            return "\n".join(f"{k}={v}" for k, v in pairs)

        sections = {
            "[General]": block([("ColorScheme", "theming")]),
            "[Colors:View]": block(
                [
                    ("BackgroundNormal", bg),
                    ("ForegroundNormal", fg),
                    ("BackgroundAlternate", bg_sub),
                ]
            ),
            "[Colors:Window]": block(
                [
                    ("BackgroundNormal", bg_sub),
                    ("ForegroundNormal", fg),
                    ("BackgroundAlternate", bg_sub),
                ]
            ),
            "[Colors:Button]": block(
                [("BackgroundNormal", bg_sub), ("ForegroundNormal", fg)]
            ),
            "[Colors:Selection]": block(
                [("BackgroundNormal", accent), ("ForegroundNormal", bg)]
            ),
            "[Colors:Tooltip]": block(
                [("BackgroundNormal", bg), ("ForegroundNormal", fg)]
            ),
            "[Colors:Complementary]": block(
                [("BackgroundNormal", bg), ("ForegroundNormal", fg)]
            ),
            "[Colors:Text]": block(
                [("BackgroundNormal", bg), ("ForegroundNormal", fg)]
            ),
            "[Colors:Link]": block(
                [("Visited", core_token(ctx.palette, "accent.alt"))]
            ),
        }
        text = KDEGLOBALS.read_text() if KDEGLOBALS.exists() else ""
        for header, body in sections.items():
            text = writers.update_marker_block(
                text,
                f"# qt:managed:{header}",
                f"# /qt:managed:{header}",
                f"{header}\n{body}\n",
            )
        atomic_write(KDEGLOBALS, text)

    def _write_q6(self) -> None:
        text = writers.read_surface(ENV_FILE)
        new_text, _ = writers.managed_line_set(text, "QT_QPA_PLATFORMTHEME", "qt6ct")
        atomic_write(ENV_FILE, new_text)

    # -- component contract --------------------------------------------------

    def write_effects(self, ctx: Context) -> Effects:
        if not shutil.which("qt6ct"):
            fail("qt6ct not found — the platformtheme for both modes")
            return Effects(code=1)

        style_cfg = ctx.config["qt"]["style"]
        style = style_cfg
        if style_cfg == "kvantum" and not KVANTUM_ENGINE.exists():
            warn(
                "kvantum engine absent — falling back to fusion for this apply "
                "(install: zypper in kvantum-qt6,)"
            )
            style = "fusion"

        scheme_path = self._write_q2_fusion(ctx)
        ok("generated color scheme", detail=str(QT6CT_COLORS.relative_to(HOME)))
        if style != "fusion":
            from theme.resources.base import KVANTUM_THEMES

            gtk_theme = ctx.config["gui"]["theme"]
            resource_cls = KVANTUM_THEMES.get(gtk_theme)
            if resource_cls is None:
                fail(f"no Kvantum counterpart for gui.theme {gtk_theme!r}")
                return Effects(code=1)
            resource = resource_cls()
            src = resource.ensure_source(ctx)
            if not ctx.dry_run:
                resource.install(ctx, src)
                ok(f"built Kvantum theme ({resource.key}/{mode(ctx.palette)})")
            self._write_q3()

        if not ctx.dry_run:
            self._write_q1(
                ctx,
                style=("kvantum" if style == "kvantum" else "Fusion"),
                scheme_path=scheme_path,
            )
            self._write_q5(ctx)
            ok("qt surfaces written", detail="qt6ct.conf · kdeglobals · env line")

        return Effects(
            managed=[("S6", "QT_QPA_PLATFORMTHEME", "qt6ct")],
            restart_hints=[
                "Qt applications (palette read at startup; no reload signal)"
            ],
            record=(
                "qt",
                "qt",
                make_record(
                    slice_hash(self.consumed_slice(ctx)),
                    slice_hash(self.consumed_slice(ctx)),
                    {},
                    {"surfaces": {"style": style}},
                ),
            ),
        )

    def status(self, ctx: Context) -> int:
        from theme.helpers.logio import note_state

        old = read_member("qt", "qt")
        code = 0
        if not old or old.get("config_hash") != slice_hash(self.consumed_slice(ctx)):
            code |= 1
        if ENV_FILE.exists():
            text = ENV_FILE.read_text()
            managed = "export QT_QPA_PLATFORMTHEME=qt6ct # theme:managed"
            if managed not in text:
                code |= 2
        note_state(self.group, self.key, code)
        return code

    def build(self, ctx: Context) -> dict[str, Any]:
        return {}
