"""Cursors member: S1-S5 cursor keys + S7 root cursor."""

from __future__ import annotations

from pathlib import Path
from typing import Any

from theme.components.base import Component, Effects
from theme.components.gtk import GS_SCHEMA, S1, S2, S3, S4
from theme.helpers import writers
from theme.helpers.logio import ok, warn
from theme.helpers.reload import gsettings_get, gsettings_set
from theme.palette import slice_hash
from theme.resources.base import CURSOR_PACKS, Context
from theme.state import make_record, read_member, update_member

HOME = Path.home()


class CursorsComponent(Component):
    key = "cursors"
    group = "gui"
    platform = "linux"

    def consumed_slice(self, ctx: Context) -> dict[str, Any]:
        """gui.cursor_pack/theme/size + palette mode/accent + base00/base01."""
        from theme.palette import core_token, resolve_accent

        return {
            "cursor_pack": ctx.config["gui"]["cursor_pack"],
            "cursor_size": ctx.config["gui"]["cursor_size"],
            "accent": resolve_accent(ctx.palette),
            "base00": core_token(ctx.palette, "background"),
            "base01": core_token(ctx.palette, "background.subtle"),
        }

    def build(self, ctx: Context) -> dict[str, Any]:
        pack_key = ctx.config["gui"]["cursor_pack"]
        resource = CURSOR_PACKS[pack_key]()
        src = resource.ensure_source(ctx)
        slice_h = slice_hash(self.consumed_slice(ctx))
        old = read_member("gui", "cursors")
        head_moved = old.get("repo_heads", {}).get(resource.key) != src.head
        needs_build = (
            ctx.force
            or not old
            or old.get("built_config_hash") != slice_h
            or head_moved
        )
        built_hash = slice_h
        if needs_build and not ctx.no_build and not ctx.dry_run:
            resource.install(ctx, src)
            ok(f"built {resource.naming_for(ctx)} cursors")
        elif needs_build and ctx.no_build:
            warn("cursors: rebuild pending skipped (--no-build)")
            built_hash = old.get("built_config_hash", slice_h)
        return {
            "config_hash": slice_h,
            "built_config_hash": built_hash,
            "repo_heads": {resource.key: src.head},
            "surfaces": {},
        }

    def effective_name(self, ctx: Context) -> str:
        pack_key = ctx.config["gui"]["cursor_pack"]
        if pack_key:
            return CURSOR_PACKS[pack_key]().naming_for(ctx)
        return ctx.config["gui"]["cursor_theme"]

    def surface_values(self, ctx: Context) -> dict[str, dict[str, Any]]:
        name = self.effective_name(ctx)
        size = ctx.config["gui"]["cursor_size"]
        return {
            "S1": {"Gtk/CursorThemeName": name},
            "S2": {"gtk-cursor-theme-name": name, "gtk-cursor-theme-size": size},
            "S3": {"gtk-cursor-theme-name": name, "gtk-cursor-theme-size": size},
            "S4": {"gtk-cursor-theme-name": name, "gtk-cursor-theme-size": size},
            "S5": {"cursor-theme": name, "cursor-size": size},
        }

    def write_effects(self, ctx: Context) -> Effects:
        record = self.build(ctx)
        values = self.surface_values(ctx)
        if ctx.dry_run:
            return Effects()
        gsettings_set(GS_SCHEMA, "cursor-theme", values["S5"]["cursor-theme"])
        gsettings_set(GS_SCHEMA, "cursor-size", str(values["S5"]["cursor-size"]))
        from theme.state import make_record

        surfaces = {k: {ik: str(iv) for ik, iv in v.items()} for k, v in values.items()}
        surfaces["S7"] = {"refresh": "p3-deferred"}
        return Effects(
            surfaces={sid: values[sid] for sid in ("S1", "S2", "S3", "S4")},
            reloads=[
                ("sighup", {}),
                ("xsetroot", {"theme": values["S1"]["Gtk/CursorThemeName"]}),
            ],
            record=(
                "gui",
                "cursors",
                make_record(
                    record["config_hash"],
                    record["built_config_hash"],
                    record["repo_heads"],
                    surfaces,
                ),
            ),
        )

    def status(self, ctx: Context) -> int:
        old = read_member("gui", "cursors")
        code = 0
        if not old or old.get("config_hash") != slice_hash(self.consumed_slice(ctx)):
            code |= 1
        values = self.surface_values(ctx)
        drift = []
        if (
            writers.write_report(S1, values["S1"])
            .get("Gtk/CursorThemeName", "")
            .strip('"')
            != values["S1"]["Gtk/CursorThemeName"]
        ):
            drift.append("S1")
        if gsettings_get(GS_SCHEMA, "cursor-theme") != values["S5"]["cursor-theme"]:
            drift.append("S5")
        if drift:
            warn(f"drift cursors: {', '.join(drift)}")
            code |= 2
        from theme.helpers.logio import note_state

        note_state(self.group, self.key, code)
        return code
