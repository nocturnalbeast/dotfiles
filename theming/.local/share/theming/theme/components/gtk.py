"""GTK member: S1–S6 gtk-owned keys, colloid-class resources."""

from __future__ import annotations

from pathlib import Path
from typing import Any

from theme.components.base import Component, Effects
from theme.helpers import writers
from theme.helpers.logio import action, atomic_write, ok, warn
from theme.helpers.reload import gsettings_get, gsettings_set
from theme.palette import mode, resolve_accent, slice_hash
from theme.resources.base import GTK_THEMES, Context
from theme.state import read_member, update_member

XDG = Path.home() / ".config"
S1 = XDG / "xsettingsd" / "xsettingsd.conf"
S2 = XDG / "gtk-3.0" / "settings.ini"
S3 = XDG / "gtk-4.0" / "settings.ini"
S4 = XDG / "gtk-2.0" / "gtkrc"
S6 = XDG / "profile.d" / "gui" / "00-theming.sh"
GS_SCHEMA = "org.gnome.desktop.interface"


class GTKComponent(Component):
    key = "gtk"
    group = "gui"

    def consumed_slice(self, ctx: Context) -> dict[str, Any]:
        """gui theme/tweaks/size/env_override/font_size + fonts.sans + palette mode/accent."""
        return {
            "theme": ctx.config["gui"]["theme"],
            "tweaks": sorted(ctx.config["gui"]["tweaks"]),
            "size": ctx.config["gui"]["size"],
            "env_override": ctx.config["gui"]["env_override"],
            "font_size": ctx.config["gui"]["font_size"],
            "fonts_sans": ctx.config["fonts"]["sans"],
            "palette_mode": mode(ctx.palette),
            "accent": resolve_accent(ctx.palette),
        }

    def build(self, ctx: Context) -> dict[str, Any]:
        resource = GTK_THEMES[ctx.config["gui"]["theme"]]()
        src = resource.ensure_source(ctx)
        if src.pull_warning:
            warn(src.pull_warning)
        slice_h = slice_hash(self.consumed_slice(ctx))
        old = read_member("gui", "gtk")
        head_moved = old.get("repo_heads", {}).get(resource.key) != src.head
        needs_build = (
            ctx.force
            or not old
            or old.get("built_config_hash") != slice_h
            or head_moved
        )
        built_hash = slice_h
        if needs_build and not ctx.no_build and not ctx.dry_run:
            theme_dir = resource.install(ctx, src)
            if not theme_dir.exists():
                raise RuntimeError(f"gtk: build produced no {theme_dir}")
            ok(f"built {resource.naming_for(ctx)}")
        elif needs_build and ctx.no_build:
            warn("gtk: rebuild pending skipped (--no-build)")
            built_hash = old.get("built_config_hash", slice_h)
        elif needs_build and ctx.dry_run:
            action(
                f"would build {resource.naming_for(ctx)}"
                f"{'' if src.head != 'unknown' else ' (unknown — clone absent)'}"
            )
            built_hash = old.get("built_config_hash", slice_h)
        return {
            "config_hash": slice_h,
            "built_config_hash": built_hash,
            "repo_heads": {resource.key: src.head},
            "surfaces": {},
        }

    def surface_values(self, ctx: Context) -> dict[str, dict[str, str]]:
        theme_name = GTK_THEMES[ctx.config["gui"]["theme"]]().naming_for(ctx)
        font = f"{ctx.config['fonts']['sans'][0]} {ctx.config['gui']['font_size']}"
        prefer_dark = "1" if mode(ctx.palette) == "dark" else "0"
        color_scheme = "prefer-dark" if mode(ctx.palette) == "dark" else "default"
        env_val = theme_name if ctx.config["gui"]["env_override"] else None
        return {
            "S1": {"Net/ThemeName": theme_name, "Gtk/FontName": font},
            "S2": {
                "gtk-theme-name": theme_name,
                "gtk-font-name": font,
                "gtk-application-prefer-dark-theme": prefer_dark,
            },
            "S3": {
                "gtk-theme-name": theme_name,
                "gtk-font-name": font,
                "gtk-application-prefer-dark-theme": prefer_dark,
            },
            "S4": {"gtk-theme-name": theme_name},
            "S5": {
                "gtk-theme": theme_name,
                "font-name": font,
                "color-scheme": color_scheme,
            },
            "S6": {"GTK_THEME": env_val if env_val else ""},
        }

    def write_effects(self, ctx: Context) -> Effects:
        record = self.build(ctx)
        values = self.surface_values(ctx)
        if ctx.dry_run:
            return Effects()
        # S5 gsettings: key-disjoint from shared surfaces; dconf is the observed store
        if not gsettings_set(GS_SCHEMA, "gtk-theme", values["S5"]["gtk-theme"]):
            warn("gsettings backend missing — S5 skipped")
        else:
            gsettings_set(GS_SCHEMA, "font-name", values["S5"]["font-name"])
            gsettings_set(GS_SCHEMA, "color-scheme", values["S5"]["color-scheme"])
        surfaces = {
            k: {ik: iv for ik, iv in v.items() if iv != ""}
            for k, v in values.items()
            if k in ("S1", "S2", "S3", "S4")
        }
        surfaces["S6"] = {
            "state": "active" if values["S6"]["GTK_THEME"] else "commented"
        }
        from theme.state import make_record

        return Effects(
            surfaces={sid: values[sid] for sid in ("S1", "S2", "S3", "S4")},
            managed=[("S6", "GTK_THEME", values["S6"]["GTK_THEME"] or None)],
            reloads=[("sighup", {})],
            record=(
                "gui",
                "gtk",
                make_record(
                    record["config_hash"],
                    record["built_config_hash"],
                    record["repo_heads"],
                    surfaces,
                ),
            ),
        )

    def status(self, ctx: Context) -> int:
        old = read_member("gui", "gtk")
        slice_h = slice_hash(self.consumed_slice(ctx))
        code = 0
        if not old or old.get("config_hash") != slice_h:
            code |= 1
        values = self.surface_values(ctx)
        drift: list[str] = []
        live = writers.write_report(S1, values["S1"])
        if live.get("Net/ThemeName", "").strip('"') != values["S1"]["Net/ThemeName"]:
            drift.append("S1")
        for path, sid in ((S2, "S2"), (S3, "S3"), (S4, "S4")):
            live = writers.write_report(path, values[sid])
            if (
                live.get("gtk-theme-name", "").strip('"')
                != values[sid]["gtk-theme-name"]
            ):
                drift.append(sid)
        if gsettings_get(GS_SCHEMA, "gtk-theme") != values["S5"]["gtk-theme"]:
            drift.append("S5")
        if drift:
            warn(f"drift gtk: {', '.join(drift)}")
            code |= 2
        from theme.helpers.logio import note_state

        note_state(self.group, self.key, code)
        return code
