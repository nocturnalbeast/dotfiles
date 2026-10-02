"""Icons member: S1–S5 icon keys, icon-pack resources."""

from __future__ import annotations

from typing import Any

from pathlib import Path

from theme.components.base import Component, Effects
from theme.components.gtk import GS_SCHEMA, S1, S2, S3, S4
from theme.helpers import writers
from theme.helpers.logio import ok, warn
from theme.helpers.reload import gsettings_get, gsettings_set
from theme.palette import mode, resolve_accent, slice_hash
from theme.resources.base import ICON_PACKS, Context
from theme.state import make_record, read_member, update_member


class IconsComponent(Component):
    key = "icons"
    group = "gui"
    platform = "linux"

    def consumed_slice(self, ctx: Context) -> dict[str, Any]:
        """gui.icon_pack/icon_theme + palette mode/accent."""
        return {
            "icon_pack": ctx.config["gui"]["icon_pack"],
            "palette_mode": mode(ctx.palette),
            "accent": resolve_accent(ctx.palette),
        }

    def build(self, ctx: Context) -> dict[str, Any]:
        pack_key = ctx.config["gui"]["icon_pack"]
        resource = ICON_PACKS[pack_key]()
        src = resource.ensure_source(ctx)
        slice_h = slice_hash(self.consumed_slice(ctx))
        old = read_member("gui", "icons")
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
            ok(f"built {resource.naming_for(ctx)} icons")
        elif needs_build and (ctx.no_build or ctx.dry_run):
            if ctx.no_build:
                warn("icons: rebuild pending skipped (--no-build)")
            built_hash = old.get("built_config_hash", slice_h)
        return {
            "config_hash": slice_h,
            "built_config_hash": built_hash,
            "repo_heads": {resource.key: src.head},
            "surfaces": {},
        }

    def effective_name(self, ctx: Context) -> str:
        pack_key = ctx.config["gui"]["icon_pack"]
        if pack_key:
            return ICON_PACKS[pack_key]().naming_for(ctx)
        return ctx.config["gui"]["icon_theme"]

    def surface_values(self, ctx: Context) -> dict[str, dict[str, str]]:
        name = self.effective_name(ctx)
        return {
            "S1": {"Net/IconThemeName": name},
            "S2": {"gtk-icon-theme-name": name},
            "S3": {"gtk-icon-theme-name": name},
            "S4": {"gtk-icon-theme-name": name},
            "S5": {"icon-theme": name},
        }

    def write_effects(self, ctx: Context) -> Effects:
        record = self.build(ctx)
        values = self.surface_values(ctx)
        if ctx.dry_run:
            return Effects()
        gsettings_set(GS_SCHEMA, "icon-theme", values["S5"]["icon-theme"])
        from theme.state import make_record

        pack_dir = Path.home() / ".local/share/icons" / values["S5"]["icon-theme"]
        return Effects(
            surfaces={sid: values[sid] for sid in ("S1", "S2", "S3", "S4")},
            reloads=[("sighup", {}), ("iconcache", {"dir": str(pack_dir)})],
            record=(
                "gui",
                "icons",
                make_record(
                    record["config_hash"],
                    record["built_config_hash"],
                    record["repo_heads"],
                    values,
                ),
            ),
        )

    def status(self, ctx: Context) -> int:
        old = read_member("gui", "icons")
        code = 0
        if not old or old.get("config_hash") != slice_hash(self.consumed_slice(ctx)):
            code |= 1
        values = self.surface_values(ctx)
        drift = []
        if (
            writers.write_report(S1, values["S1"])
            .get("Net/IconThemeName", "")
            .strip('"')
            != values["S1"]["Net/IconThemeName"]
        ):
            drift.append("S1")
        if (
            writers.write_report(S2, values["S2"]).get("gtk-icon-theme-name", "")
            != values["S2"]["gtk-icon-theme-name"]
        ):
            drift.append("S2")
        if gsettings_get(GS_SCHEMA, "icon-theme") != values["S5"]["icon-theme"]:
            drift.append("S5")
        if drift:
            warn(f"drift icons: {', '.join(drift)}")
            code |= 2
        from theme.helpers.logio import note_state

        note_state(self.group, self.key, code)
        return code
