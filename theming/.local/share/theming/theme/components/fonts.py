"""Fonts member: fontconfig alias block (marker bootstrap + regen)."""

from __future__ import annotations

import re
from pathlib import Path
from typing import Any

from theme.components.base import Component, Effects
from theme.helpers.logio import atomic_write, warn
from theme.palette import slice_hash
from theme.resources.base import Context
from theme.state import make_record, read_member, update_member

FONTCONF = Path.home() / ".config/fontconfig/fonts.conf"
BEGIN = "<!-- theming:begin -->"
END = "<!-- theming:end -->"


def _alias_xml(family: str, prefer: list[str]) -> str:
    prefs = "\n".join(f"            <family>{p}</family>" for p in prefer)
    return (
        f"    <alias>\n"
        f"        <family>{family}</family>\n"
        f"        <prefer>\n{prefs}\n"
        f"        </prefer>\n"
        f"    </alias>"
    )


class FontsComponent(Component):
    key = "fonts"
    group = "gui"
    platform = "linux"

    def consumed_slice(self, ctx: Context) -> dict[str, Any]:
        return {k: ctx.config["fonts"][k] for k in ("sans", "serif", "monospace")}

    def block_body(self, ctx: Context) -> str:
        f = ctx.config["fonts"]
        return "\n".join(
            [
                _alias_xml("serif", f["serif"]),
                _alias_xml("sans-serif", f["sans"]),
                _alias_xml("sans", f["sans"]),
                _alias_xml("monospace", f["monospace"]),
            ]
        )

    def build(self, ctx: Context) -> dict[str, Any]:
        # fonts own no external resources — build is a no-op
        return {
            "config_hash": slice_hash(self.consumed_slice(ctx)),
            "built_config_hash": slice_hash(self.consumed_slice(ctx)),
            "repo_heads": {},
            "surfaces": {},
        }

    def _bootstrap_markers(self, text: str) -> str:
        """One-time insert around the existing alias blocks."""
        first = text.find("<alias>")
        last = text.rfind("</alias>")
        if first == -1:
            return text.rstrip("\n") + f"\n{BEGIN}\n{END}\n"
        head = text[:first].rstrip("\n")
        region = text[first : last + len("</alias>")]
        tail = text[last + len("</alias>") :].lstrip("\n")
        return f"{head}\n{BEGIN}\n{region}\n{END}\n{tail}"

    def write_effects(self, ctx: Context) -> Effects:
        record = self.build(ctx)
        if ctx.dry_run:
            return Effects()
        text = FONTCONF.read_text() if FONTCONF.exists() else ""
        if BEGIN not in text:
            text = self._bootstrap_markers(text)
        body = self.block_body(ctx)
        new = self._replace_block(text, body)
        atomic_write(FONTCONF, new)
        from theme.state import make_record

        return Effects(
            reloads=[("fcache", {})],
            record=(
                "gui",
                "fonts",
                make_record(
                    record["config_hash"],
                    record["built_config_hash"],
                    {},
                    {"fontconf": {"block": "regenerated"}},
                ),
            ),
        )

    def _replace_block(self, text: str, body: str) -> str:
        from theme.helpers.writers import update_marker_block

        return update_marker_block(text, BEGIN, END, body)

    def status(self, ctx: Context) -> int:
        old = read_member("gui", "fonts")
        code = 0
        if not old or old.get("config_hash") != slice_hash(self.consumed_slice(ctx)):
            code |= 1
        if FONTCONF.exists():
            text = FONTCONF.read_text()
            m = re.search(re.escape(BEGIN) + r"(.*?)" + re.escape(END), text, re.DOTALL)
            if not m:
                code |= 2
                warn("drift fonts: marker block absent")
            else:
                current = m.group(1).strip()
                expected = self.block_body(ctx).strip()
                if current != expected:
                    code |= 2
                    warn("drift fonts: fontconfig block diverged")
        from theme.helpers.logio import note_state

        note_state(self.group, self.key, code)
        return code
