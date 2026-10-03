"""Superfile member: generated TOML theme + config reference."""

from __future__ import annotations

import re
from pathlib import Path
from typing import Any

from theme.components.base import Component, Effects
from theme.helpers import writers
from theme.helpers.logio import atomic_write, detail_line, note_state, ok
from theme.palette import core_token, slice_hash, slot16
from theme.resources.base import Context
from theme.state import make_record, read_member

SUPERFILE_DIR = Path.home() / ".config/superfile"
CONFIG_TOML = SUPERFILE_DIR / "config.toml"
THEME_FILE = SUPERFILE_DIR / "theme" / "theming.toml"
THEME_NAME = "theming"
MANAGED_MARKER = "# theme:managed"


def theme_toml(c: dict[str, str]) -> str:
    lines = [
        f'cursor = "{c["cursor"]}"',
        f'correct = "{c["correct"]}"',
        f'error = "{c["error"]}"',
        f'hint = "{c["hint"]}"',
        f'cancel = "{c["cancel"]}"',
        f'full_screen_bg = "{c["base00"]}"',
        f'full_screen_fg = "{c["base06"]}"',
        f'directory_icon_color = "{c["accent"]}"',
        f'gradient_color = ["{c["accent"]}", "{c["accent_alt"]}"]',
        "",
        "[file_panel]",
        f'fg = "{c["base06"]}"',
        f'bg = "{c["base01"]}"',
        f'border = "{c["base03"]}"',
        f'border_active = "{c["accent"]}"',
        f'top_directory_icon = "{c["accent"]}"',
        f'top_path = "{c["base03"]}"',
        f'item_selected_fg = "{c["base00"]}"',
        f'item_selected_bg = "{c["accent"]}"',
        "",
        "[sidebar]",
        f'fg = "{c["base03"]}"',
        f'bg = "{c["base00"]}"',
        f'title = "{c["base06"]}"',
        f'border = "{c["base03"]}"',
        f'border_active = "{c["accent"]}"',
        f'item_selected_fg = "{c["base00"]}"',
        f'item_selected_bg = "{c["base01"]}"',
        f'divider = "{c["base02"]}"',
        "",
        "[footer]",
        f'fg = "{c["base03"]}"',
        f'bg = "{c["base00"]}"',
        f'border = "{c["base03"]}"',
        f'border_active = "{c["accent"]}"',
        "",
        "[modal]",
        f'fg = "{c["base06"]}"',
        f'bg = "{c["base01"]}"',
        f'border_active = "{c["accent"]}"',
        f'cancel_fg = "{c["base03"]}"',
        f'cancel_bg = "{c["base00"]}"',
        f'confirm_fg = "{c["base00"]}"',
        f'confirm_bg = "{c["accent"]}"',
        "",
        "[help_menu]",
        f'hotkey = "{c["base0C"]}"',
        f'title = "{c["base06"]}"',
    ]
    return "\n".join(lines) + "\n"


def spf_colors(palette: dict[str, Any]) -> dict[str, str]:
    c = {
        slot: slot16(palette, slot)
        for slot in (
            "base00",
            "base01",
            "base02",
            "base03",
            "base06",
            "base08",
            "base0B",
            "base0C",
            "base0D",
            "base0E",
        )
    }
    c["accent"] = core_token(palette, "accent")
    c["accent_alt"] = core_token(palette, "accent.alt")
    c["cursor"] = c["base0D"]
    c["correct"] = c["base0B"]
    c["error"] = c["base08"]
    c["hint"] = c["base0D"]
    c["cancel"] = c["base03"]
    return c


def update_theme_ref(text: str) -> str:
    """Set the managed theme line; one active `theme =` key wins."""
    lines = text.splitlines()
    out = []
    seen = False
    for line in lines:
        if re.match(r"^\s*theme\s*=", line):
            if seen:
                continue
            out.append(f'theme = "{THEME_NAME}" {MANAGED_MARKER}')
            seen = True
            continue
        out.append(line)
    if not seen:
        if lines and not lines[-1].strip():
            lines.pop()
        lines_append = lines + ["", f'theme = "{THEME_NAME}" {MANAGED_MARKER}']
        return "\n".join(lines_append) + "\n"
    return "\n".join(out) + "\n"


class SuperfileComponent(Component):
    key = "superfile"
    group = "tui"

    def consumed_slice(self, ctx: Context) -> dict[str, Any]:
        return {"colors": spf_colors(ctx.palette)}

    def write_effects(self, ctx: Context) -> Effects:
        if ctx.dry_run:
            ok("superfile: would write theming.toml + config reference")
            return Effects()
        colors = spf_colors(ctx.palette)
        THEME_FILE.parent.mkdir(parents=True, exist_ok=True)
        atomic_write(THEME_FILE, theme_toml(colors))
        ok("superfile: theming.toml written")
        if CONFIG_TOML.exists():
            text = writers.read_surface(CONFIG_TOML)
            new_text = update_theme_ref(text)
            if new_text != text:
                atomic_write(CONFIG_TOML, new_text)
                detail_line("superfile: config.toml theme reference set")
        else:
            atomic_write(CONFIG_TOML, update_theme_ref(""))
        slice = {"colors": colors}
        return Effects(
            record=(
                "tui",
                "superfile",
                make_record(
                    slice_hash(self.consumed_slice(ctx)),
                    slice_hash(slice),
                    {},
                    {"theme_file": {"state": "active", "name": THEME_NAME}},
                ),
            )
        )

    def status(self, ctx: Context) -> int:
        old = read_member("tui", "superfile")
        code = 0
        detail = None
        if not old or old.get("config_hash") != slice_hash(self.consumed_slice(ctx)):
            code |= 1
            detail = "no stamp or config changed"
        if THEME_FILE.exists():
            if THEME_FILE.read_text() != theme_toml(spf_colors(ctx.palette)):
                code |= 2
                detail = "theming.toml stale vs palette"
        else:
            code |= 2
            detail = "theming.toml missing"
        if CONFIG_TOML.exists():
            text = writers.read_surface(CONFIG_TOML)
            if update_theme_ref(text) != text:
                code |= 2
                detail = "config.toml theme reference missing"
        note_state(self.group, self.key, code, detail)
        return code

    def build(self, ctx: Context) -> dict[str, Any]:
        return {}
