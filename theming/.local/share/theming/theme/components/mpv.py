"""mpv member: modernx OSC theme keys rewritten from palette slots."""

from __future__ import annotations

from pathlib import Path
from typing import Any

from theme.components.base import Component, Effects
from theme.helpers import writers
from theme.helpers.logio import atomic_write, note_state, ok
from theme.palette import core_token, slice_hash, slot16
from theme.resources.base import Context
from theme.state import make_record, read_member

MODERNX_CONF = Path.home() / ".config/mpv/script-opts/modernx.conf"

FG_KEYS = (
    "title_color",
    "time_color",
    "chapter_title_color",
    "side_buttons_color",
    "middle_buttons_color",
    "playpause_color",
    "window_title_color",
    "window_controls_color",
)
ACCENT_KEYS = (
    "hover_effect_color",
    "seekbarfg_color",
    "seekbar_cache_color",
    "chapter_marker_color",
    "chapter_marker_current_color",
)


def theme_values(palette: dict[str, Any]) -> dict[str, str]:
    values = {"osc_color": slot16(palette, "base00")}
    values.update({key: slot16(palette, "base06") for key in FG_KEYS})
    values.update({key: core_token(palette, "accent") for key in ACCENT_KEYS})
    values["held_element_color"] = slot16(palette, "base03")
    values["seekbarbg_color"] = slot16(palette, "base06")
    return values


class MpvComponent(Component):
    key = "mpv"
    group = "tui"

    def consumed_slice(self, ctx: Context) -> dict[str, Any]:
        return {"theme": theme_values(ctx.palette)}

    def write_effects(self, ctx: Context) -> Effects:
        if ctx.dry_run:
            ok("mpv: would rewrite modernx theme keys")
            return Effects()
        if not MODERNX_CONF.exists():
            ok("mpv: modernx.conf absent - nothing to theme")
            return Effects()
        new_text = writers.update_eq_kv(
            MODERNX_CONF.read_text(), theme_values(ctx.palette)
        )
        atomic_write(MODERNX_CONF, new_text)
        ok("mpv: modernx theme written")
        slice = {"theme": theme_values(ctx.palette)}
        return Effects(
            record=(
                "tui",
                "mpv",
                make_record(
                    slice_hash(slice),
                    slice_hash(slice),
                    {},
                    {"modernx": {"keys": str(len(slice["theme"]))}},
                ),
            )
        )

    def status(self, ctx: Context) -> int:
        old = read_member("tui", "mpv")
        code = 0
        detail = None
        if not old or old.get("config_hash") != slice_hash(self.consumed_slice(ctx)):
            code |= 1
            detail = "no stamp or config changed"
        if MODERNX_CONF.exists():
            expected = writers.update_eq_kv(
                MODERNX_CONF.read_text(), theme_values(ctx.palette)
            )
            if expected != MODERNX_CONF.read_text():
                code |= 2
                detail = "modernx theme stale vs palette"
        note_state(self.group, self.key, code, detail)
        return code

    def build(self, ctx: Context) -> dict[str, Any]:
        return {}
