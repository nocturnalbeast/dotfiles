"""rmpc member: default.ron generated from the palette template."""

from __future__ import annotations

import re
from pathlib import Path
from typing import Any

from theme.components.base import Component, Effects
from theme.helpers.logio import atomic_write, note_state, ok
from theme.palette import core_token, slice_hash, slot16
from theme.resources.base import Context
from theme.state import make_record, read_member

THEME_FILE = Path.home() / ".config/rmpc/themes/default.ron"
TEMPLATE = Path(__file__).resolve().parent.parent / "resources" / "rmpc_default.ron.tpl"
SLOTS = ("base00", "base03", "base04", "base05", "base06", "base07", "base0C")


def theme_ron(palette: dict[str, Any]) -> str:
    values = {slot: slot16(palette, slot).lower() for slot in SLOTS}
    values["accent"] = core_token(palette, "accent").lower()
    values["accent_alt"] = core_token(palette, "accent.alt").lower()
    text = TEMPLATE.read_text()
    for key, hex_v in values.items():
        text = text.replace('"{%s}"' % key, '"%s"' % hex_v)
    if re.search(r"\{[a-zA-Z_0-9]+\}", text):
        raise RuntimeError("rmpc: unresolved slot token in template")
    return text


class RmpcComponent(Component):
    key = "rmpc"
    group = "tui"

    def consumed_slice(self, ctx: Context) -> dict[str, Any]:
        return {"theme": theme_ron(ctx.palette)}

    def write_effects(self, ctx: Context) -> Effects:
        if ctx.dry_run:
            ok("rmpc: would write default.ron")
            return Effects()
        content = theme_ron(ctx.palette)
        THEME_FILE.parent.mkdir(parents=True, exist_ok=True)
        atomic_write(THEME_FILE, content)
        ok("rmpc: default.ron written")
        slice = {"theme": content}
        return Effects(
            record=(
                "tui",
                "rmpc",
                make_record(
                    slice_hash(slice),
                    slice_hash(slice),
                    {},
                    {"default_ron": {"state": "active"}},
                ),
            )
        )

    def status(self, ctx: Context) -> int:
        old = read_member("tui", "rmpc")
        code = 0
        detail = None
        if not old or old.get("config_hash") != slice_hash(self.consumed_slice(ctx)):
            code |= 1
            detail = "no stamp or config changed"
        if THEME_FILE.exists():
            if THEME_FILE.read_text() != theme_ron(ctx.palette):
                code |= 2
                detail = "default.ron stale vs palette"
        else:
            code |= 2
            detail = "default.ron missing"
        note_state(self.group, self.key, code, detail)
        return code

    def build(self, ctx: Context) -> dict[str, Any]:
        return {}
