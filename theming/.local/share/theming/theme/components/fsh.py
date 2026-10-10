"""fsh member: palette-driven zsh theme.ini (upstream base16.ini
crosswalk, hex truecolor); activation is the zsh plughook's job,
never apply - a subshell cannot reach running shells."""

from __future__ import annotations

import re
from pathlib import Path
from typing import Any

from theme.components.base import Component, Effects
from theme.helpers.logio import atomic_write, detail_line, note_state, ok
from theme.palette import slice_hash, slot16
from theme.resources.base import Context
from theme.state import make_record, read_member

THEME_INI = Path.home() / ".cache/theming/fsh/theme.ini"

# value tokens the fsh parser accepts that this generator may emit;
# anything else fails validation (no spaces after commas, bg: not bg=)
_ATTRS = {
    "none",
    "bold",
    "no-bold",
    "underline",
    "no-underline",
    "blink",
    "no-blink",
    "reverse",
    "no-reverse",
    "standout",
    "no-standout",
    "conceal",
    "no-conceal",
}
_HEX = re.compile(r"#[0-9a-f]{6}")

# style-key ← palette slot spec. "" = follow `path` (pathseparator only).
SECTION_STYLES: dict[str, dict[str, str]] = {
    "base": {
        "default": "none",
        "unknown-token": "base08,bold",
        "commandseparator": "none",
        "redirection": "none",
        "here-string-tri": "base04",
        "here-string-text": "bg:base01",
        "here-string-var": "base08,bg:base01",
        "exec-descriptor": "base09,bold",
        "comment": "base03",
        "correct-subtle": "base07",
        "incorrect-subtle": "base08",
        "subtle-separator": "base07",
        "subtle-bg": "bg:base0F",
        "recursive-base": "none",
    },
    "command-point": {
        "reserved-word": "base0E",
        "subcommand": "base0A",
        "alias": "base0D",
        "suffix-alias": "base0D",
        "global-alias": "base0D,bg:base01",
        "builtin": "base0D",
        "function": "base0D",
        "command": "base0D",
        "precommand": "base0A",
        "hashed-command": "base0D",
        "single-sq-bracket": "base0D",
        "double-sq-bracket": "base0D",
        "double-paren": "base0E",
    },
    "paths": {
        "path": "base09",
        "pathseparator": "",
        "path-to-dir": "base09,underline",
        "globbing": "base0A",
        "globbing-ext": "base0A,bold",
    },
    "brackets": {
        "paired-bracket": "bg:base03",
        "bracket-level-1": "base0C,bold",
        "bracket-level-2": "base0A,bold",
        "bracket-level-3": "base0B,bold",
    },
    "arguments": {
        "single-hyphen-option": "base0C",
        "double-hyphen-option": "base0C",
        "back-quoted-argument": "none",
        "single-quoted-argument": "base0B",
        "double-quoted-argument": "base0B",
        "dollar-quoted-argument": "base0B",
        "optarg-string": "base0B",
        "optarg-number": "base09",
    },
    "in-string": {
        "back-dollar-quoted-argument": "base0A",
        "back-or-dollar-double-quoted-argument": "base08",
    },
    "other": {
        "variable": "base08",
        "assign": "none",
        "assign-array-bracket": "base0E",
        "history-expansion": "base0A,bold",
    },
    "math": {
        "mathvar": "base08",
        "mathnum": "base09",
        "matherr": "base08,bold",
    },
    "for-loop": {
        "forvar": "base08",
        "fornum": "base09",
        "foroper": "none",
        "forsep": "none",
    },
    "case": {
        "case-input": "base08",
        "case-parentheses": "base0E",
        "case-condition": "bg:base0F",
    },
}


def _render_spec(spec: str, palette: dict[str, Any]) -> str:
    tokens: list[str] = []
    for token in spec.split(","):
        if not token or token in _ATTRS:
            tokens.append(token)
        elif token.startswith("bg:"):
            tokens.append("bg:" + slot16(palette, token[3:]).lower())
        elif token.startswith("base"):
            tokens.append(slot16(palette, token).lower())
        else:
            raise RuntimeError(f"fsh: unknown style token {token!r}")
    rendered = ",".join(tokens)
    if rendered and not all(
        not t or t in _ATTRS or _HEX.fullmatch(t) or t.startswith("bg:#")
        for t in rendered.split(",")
    ):
        raise RuntimeError(f"fsh: malformed style {rendered!r}")
    return rendered


def fsh_styles(palette: dict[str, Any]) -> dict[str, str]:
    return {
        key: _render_spec(spec, palette)
        for section in SECTION_STYLES.values()
        for key, spec in section.items()
    }


def fsh_theme_ini(styles: dict[str, str], secondary_path: str) -> str:
    lines: list[str] = []
    for section, keys in SECTION_STYLES.items():
        lines.append(f"[{section}]")
        width = max(len(k) for k in keys)
        for key in keys:
            lines.append(f"{key.ljust(width)} = {styles[key]}")
        lines.append("")
    lines.append(f"secondary = {secondary_path}")
    return "\n".join(lines) + "\n"


class FshComponent(Component):
    key = "fsh"
    group = "tui"

    def consumed_slice(self, ctx: Context) -> dict[str, Any]:
        return {"styles": fsh_styles(ctx.palette)}

    def write_effects(self, ctx: Context) -> Effects:
        if ctx.dry_run:
            ok("fsh: would write theme.ini")
            return Effects()
        styles = fsh_styles(ctx.palette)
        content = fsh_theme_ini(styles, str(THEME_INI))
        THEME_INI.parent.mkdir(parents=True, exist_ok=True)
        atomic_write(THEME_INI, content)
        ok(f"fsh: theme.ini written ({len(styles)} styles,)")
        detail_line("fsh: activation on next shell (plughook -nt check)")
        slice = {"styles": styles}
        return Effects(
            record=(
                "tui",
                "fsh",
                make_record(
                    slice_hash(self.consumed_slice(ctx)),
                    slice_hash(slice),
                    {},
                    {
                        "theme_ini": {
                            "state": "active",
                            "styles": str(len(styles)),
                            "secondary": "self",
                        }
                    },
                ),
            )
        )

    def status(self, ctx: Context) -> int:
        old = read_member("tui", "fsh")
        code = 0
        detail = None
        if not old or old.get("config_hash") != slice_hash(self.consumed_slice(ctx)):
            code |= 1
            detail = "no stamp or config changed"
        if THEME_INI.exists():
            expected = fsh_theme_ini(fsh_styles(ctx.palette), str(THEME_INI))
            if THEME_INI.read_text() != expected:
                detail_line("drift fsh: theme.ini stale vs palette")
                code |= 2
                detail = "theme.ini stale vs palette"
        else:
            detail_line("drift fsh: theme.ini missing")
            code |= 2
            detail = "theme.ini missing"
        note_state(self.group, self.key, code, detail)
        return code

    def build(self, ctx: Context) -> dict[str, Any]:
        return {}
