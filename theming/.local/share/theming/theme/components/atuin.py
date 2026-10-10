"""Atuin member: theme file + config reference; name 'custom' must
not collide with atuin builtins - a builtin shadows any same-name file."""

from __future__ import annotations

import re
from pathlib import Path
from typing import Any

from theme.components.base import Component, Effects
from theme.helpers import writers
from theme.helpers.logio import atomic_write, detail_line, note_state, ok
from theme.palette import slice_hash, slot16
from theme.resources.base import Context
from theme.state import make_record, read_member

ATUIN_CONFIG = Path.home() / ".config/atuin/config.toml"
THEME_DIR = Path.home() / ".config/atuin/themes"
THEME_FILE = THEME_DIR / "custom.toml"
THEME_NAME = "custom"
MANAGED_MARKER = "# theme:managed"

# atuin Meaning ← palette slot; syntax meanings follow upstream zsh base16
# conventions. Foreground-only - atuin theme files cannot carry modifiers.
MEANING_SLOTS = {
    "Base": "base06",
    "Muted": "base03",
    "Annotation": "base0F",
    "Guidance": "base0D",
    "Title": "base0D",
    "Important": "base07",
    "AlertInfo": "base0B",
    "AlertWarn": "base0A",
    "AlertError": "base08",
    "SyntaxCommand": "base0D",
    "SyntaxFlag": "base0C",
    "SyntaxString": "base0B",
    "SyntaxVariable": "base08",
    "SyntaxOperator": "base05",
    "SyntaxComment": "base03",
}


def atuin_theme_toml(colors: dict[str, str]) -> str:
    lines = ["[theme]", f'name = "{THEME_NAME}"', "", "[colors]"]
    for meaning in MEANING_SLOTS:
        value = colors[meaning]
        if not re.fullmatch(r"#[0-9a-fA-F]{6}", value):
            raise RuntimeError(f"atuin color for {meaning} malformed: {value!r}")
        lines.append(f'{meaning} = "{value.lower()}"')
    return "\n".join(lines) + "\n"


def atuin_colors(palette: dict[str, Any]) -> dict[str, str]:
    return {meaning: slot16(palette, slot) for meaning, slot in MEANING_SLOTS.items()}


def update_theme_ref(text: str) -> str:
    """Point config.toml at the custom theme: rewrite name in [theme],
    else append; untouched lines preserved."""
    lines = text.splitlines()
    section = None
    name_idx = None
    header_idx = None
    for i, line in enumerate(lines):
        s = line.strip()
        if s.startswith("[") and s.endswith("]"):
            section = s
            if section == "[theme]":
                header_idx = i
            continue
        if section == "[theme]" and re.match(r"^\s*name\s*=", line):
            name_idx = i
            break
    if name_idx is not None:
        lines[name_idx] = f'name = "{THEME_NAME}" {MANAGED_MARKER}'
    elif header_idx is not None:
        lines.insert(header_idx + 1, f'name = "{THEME_NAME}" {MANAGED_MARKER}')
    else:
        if lines and lines[-1].strip():
            lines.append("")
        lines += ["[theme]", f'name = "{THEME_NAME}" {MANAGED_MARKER}']
    return "\n".join(lines) + "\n"


class AtuinComponent(Component):
    key = "atuin"
    group = "tui"

    def consumed_slice(self, ctx: Context) -> dict[str, Any]:
        return {"colors": atuin_colors(ctx.palette)}

    def write_effects(self, ctx: Context) -> Effects:
        if ctx.dry_run:
            ok("atuin: would write custom theme + config reference")
            return Effects()

        colors = atuin_colors(ctx.palette)
        THEME_DIR.mkdir(parents=True, exist_ok=True)
        atomic_write(THEME_FILE, atuin_theme_toml(colors))
        ok("atuin: theme custom.toml written")

        if ATUIN_CONFIG.exists():
            text = writers.read_surface(ATUIN_CONFIG)
            new_text = update_theme_ref(text)
            if new_text != text:
                atomic_write(ATUIN_CONFIG, new_text)
                detail_line("atuin: config.toml [theme] reference set")
        else:
            atomic_write(ATUIN_CONFIG, update_theme_ref(""))

        slice = {"colors": colors}
        return Effects(
            record=(
                "tui",
                "atuin",
                make_record(
                    slice_hash(self.consumed_slice(ctx)),
                    slice_hash(slice),
                    {},
                    {
                        "theme_file": {
                            "state": "active",
                            "name": THEME_NAME,
                            "meanings": str(len(colors)),
                        }
                    },
                ),
            )
        )

    def status(self, ctx: Context) -> int:
        old = read_member("tui", "atuin")
        code = 0
        detail = None
        if not old or old.get("config_hash") != slice_hash(self.consumed_slice(ctx)):
            code |= 1
            detail = "no stamp or config changed"
        if THEME_FILE.exists():
            expected = atuin_theme_toml(atuin_colors(ctx.palette))
            if THEME_FILE.read_text() != expected:
                detail_line("drift atuin: custom.toml stale vs palette")
                code |= 2
                detail = "custom.toml stale vs palette"
        if ATUIN_CONFIG.exists():
            text = writers.read_surface(ATUIN_CONFIG)
            if update_theme_ref(text) != text:
                detail_line("drift atuin: config.toml theme reference missing")
                code |= 2
                detail = "config.toml theme reference missing"
        note_state(self.group, self.key, code, detail)
        return code

    def build(self, ctx: Context) -> dict[str, Any]:
        return {}
