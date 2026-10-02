"""Zathura member: palette-driven zathurarc key-scoped rewrite."""

from __future__ import annotations

from pathlib import Path
from typing import Any

from theme.components.base import Component, Effects
from theme.helpers import writers
from theme.helpers.logio import atomic_write, detail_line, note_state, ok, warn
from theme.palette import mode, slice_hash, slot16
from theme.resources.base import Context
from theme.state import make_record, read_member

ZATHURARC = Path.home() / ".config/zathura/zathurarc"

# zathura set-key ← palette slot. highlight-color is base0C, NOT base0D:
# base0D is the core accent and feeds highlight-active-color — the two
# search-hit colors must stay distinct.
COLOR_KEYS = {
    "default-fg": "base06",
    "default-bg": "base00",
    "statusbar-fg": "base03",
    "statusbar-bg": "base01",
    "inputbar-fg": "base06",
    "inputbar-bg": "base01",
    "notification-bg": "base00",
    "notification-fg": "base06",
    "notification-error-bg": "base00",
    "notification-error-fg": "base08",
    "notification-warning-bg": "base00",
    "notification-warning-fg": "base0A",
    "completion-bg": "base01",
    "completion-fg": "base06",
    "completion-group-bg": "base02",
    "completion-group-fg": "base00",
    "completion-highlight-bg": "base0D",
    "completion-highlight-fg": "base00",
    "highlight-color": "base0C",
    "highlight-active-color": "base0D",
    "index-bg": "base00",
    "index-fg": "base06",
    "index-active-bg": "base01",
    "index-active-fg": "base0D",
    "recolor-lightcolor": "base00",
    "recolor-darkcolor": "base06",
}


def zathura_values(palette: dict[str, Any], config: dict[str, Any]) -> dict[str, str]:
    """Rendered set-values: quoted hex, bare booleans, quoted pango font; recolor is dark-mode-gated."""
    values = {key: f'"{slot16(palette, slot)}"' for key, slot in COLOR_KEYS.items()}
    values["recolor"] = "true" if mode(palette) == "dark" else "false"
    font = f"{config['fonts']['sans'][0]} {config['gui']['font_size']}"
    values["font"] = f'"{font}"'
    return values


class ZathuraComponent(Component):
    key = "zathura"
    group = "gui"
    platform = "linux"

    def consumed_slice(self, ctx: Context) -> dict[str, Any]:
        return {"values": zathura_values(ctx.palette, ctx.config)}

    def write_effects(self, ctx: Context) -> Effects:
        if ctx.dry_run:
            ok("zathura: would rewrite zathurarc color/font keys")
            return Effects()
        if not ZATHURARC.exists():
            warn("zathura: zathurarc absent — nothing to theme")
            return Effects()
        values = zathura_values(ctx.palette, ctx.config)
        text = writers.read_surface(ZATHURARC)
        new_text, appended = writers.update_set_kv(text, values)
        atomic_write(ZATHURARC, new_text)
        if appended:
            detail_line(f"zathura: appended missing keys {appended}")
        ok("zathura: zathurarc themed")
        slice = {"values": values}
        return Effects(
            record=(
                "gui",
                "zathura",
                make_record(
                    slice_hash(self.consumed_slice(ctx)),
                    slice_hash(slice),
                    {},
                    {
                        "zathurarc": {
                            "state": "active",
                            "mode": mode(ctx.palette),
                            "managed_keys": str(len(values)),
                        }
                    },
                ),
            )
        )

    def status(self, ctx: Context) -> int:
        old = read_member("gui", "zathura")
        code = 0
        detail = None
        if not old or old.get("config_hash") != slice_hash(self.consumed_slice(ctx)):
            code |= 1
            detail = "no stamp or config changed"
        if ZATHURARC.exists():
            values = zathura_values(ctx.palette, ctx.config)
            text = writers.read_surface(ZATHURARC)
            expected, _ = writers.update_set_kv(text, values)
            if text != expected:
                detail_line("drift zathura: zathurarc stale vs palette")
                code |= 2
                detail = "zathurarc stale vs palette"
        note_state(self.group, self.key, code, detail)
        return code

    def build(self, ctx: Context) -> dict[str, Any]:
        return {}
