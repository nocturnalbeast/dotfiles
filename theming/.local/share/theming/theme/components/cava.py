"""cava member: gradient stops rewritten from palette slots."""

from __future__ import annotations

import re
from pathlib import Path
from typing import Any

from theme.components.base import Component, Effects
from theme.helpers.logio import atomic_write, note_state, ok
from theme.palette import slice_hash, slot16
from theme.resources.base import Context
from theme.state import make_record, read_member

CAVA_CONFIG = Path.home() / ".config/cava/config"


def _gradient_line(idx: int, hex_v: str, width: int) -> str:
    key = "gradient_color_%d" % idx
    return "%s%s= '%s'" % (key, " " * (width - len(key)), hex_v)


def update_gradient(text: str, colors: list[str]) -> str:
    """Rewrite gradient_color_N lines in place; extra stops drop,
    missing ones append into the [color] section."""
    out = []
    seen = 0
    for line in text.splitlines():
        m = re.match(r"^(\s*)gradient_color_\d+\s*=.*$", line)
        if m:
            if seen < len(colors):
                fresh = _gradient_line(seen + 1, colors[seen], 19)
                out.append(m.group(1) + fresh if m.group(1) else fresh)
                seen += 1
            continue
        out.append(line)
    if seen < len(colors):
        joined = "\n".join(out).rstrip("\n")
        for i, hex_v in enumerate(colors[seen:], start=seen + 1):
            joined += "\n" + _gradient_line(i, hex_v, 19)
        return joined + "\n"
    return "\n".join(out) + "\n"


def gradient_colors(palette: dict[str, Any]) -> list[str]:
    return [slot16(palette, "base03").lower(), slot16(palette, "base06").lower()]


class CavaComponent(Component):
    key = "cava"
    group = "tui"

    def consumed_slice(self, ctx: Context) -> dict[str, Any]:
        return {"gradient": gradient_colors(ctx.palette)}

    def write_effects(self, ctx: Context) -> Effects:
        if ctx.dry_run:
            ok("cava: would rewrite gradient stops")
            return Effects()
        if not CAVA_CONFIG.exists():
            ok("cava: config absent - nothing to theme")
            return Effects()
        colors = gradient_colors(ctx.palette)
        new_text = update_gradient(CAVA_CONFIG.read_text(), colors)
        atomic_write(CAVA_CONFIG, new_text)
        ok("cava: gradient %s → %s" % (colors[0], colors[1]))
        slice = {"gradient": colors}
        return Effects(
            record=(
                "tui",
                "cava",
                make_record(
                    slice_hash(slice),
                    slice_hash(slice),
                    {},
                    {"gradient": {"stops": str(len(colors))}},
                ),
            )
        )

    def status(self, ctx: Context) -> int:
        old = read_member("tui", "cava")
        code = 0
        detail = None
        if not old or old.get("config_hash") != slice_hash(self.consumed_slice(ctx)):
            code |= 1
            detail = "no stamp or config changed"
        if CAVA_CONFIG.exists():
            expected = update_gradient(
                CAVA_CONFIG.read_text(), gradient_colors(ctx.palette)
            )
            if expected != CAVA_CONFIG.read_text():
                code |= 2
                detail = "gradient stops stale vs palette"
        note_state(self.group, self.key, code, detail)
        return code

    def build(self, ctx: Context) -> dict[str, Any]:
        return {}
