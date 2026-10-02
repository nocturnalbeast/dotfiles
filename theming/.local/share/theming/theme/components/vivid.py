"""TUI vivid member: LS_COLORS theme.yml derived from tinty's
current_scheme at apply time — stays in lockstep on partial failure."""

from __future__ import annotations

from pathlib import Path
from typing import Any

from ruamel.yaml import YAML

from theme.components.base import Component, Effects
from theme.helpers import writers
from theme.helpers.logio import action, atomic_write, detail_line, fail, ok
from theme.palette import slice_hash
from theme.resources.base import Context
from theme.state import make_record, read_member

VIVID_LINE_FILE = Path.home() / ".config/profile.d/60-cli-theming.sh"
VIVID_THEME_PATH = "~/.cache/theming/vivid/theme.yml"
VIVID_THEME_FILE = Path(VIVID_THEME_PATH).expanduser()

TINTY_DATA_DIR = Path.home() / ".local/share/tinted-theming/tinty"
TINTY_CURRENT = TINTY_DATA_DIR / "current_scheme"

# vivid anchor roles ← base16 slots: accents keep their slot sources;
# neutrals + bright accents join so every styles-tree anchor resolves.
ANCHOR_SLOTS = {
    "bg": "base00",
    "fg": "base07",
    "black": "base01",
    "white": "base06",
    "brightblack": "base03",
    "brightwhite": "base07",
    "red": "base08",
    "green": "base0B",
    "yellow": "base0A",
    "blue": "base0D",
    "magenta": "base0E",
    "cyan": "base0C",
}
# bright accents: 30% toward fg — a distinguishable companion tone in
# both modes (dark: lighter, light: deeper), no extra scheme slots needed
BRIGHT_ANCHORS = {
    "brightred": "base08",
    "brightgreen": "base0B",
    "brightyellow": "base0A",
    "brightblue": "base0D",
    "brightmagenta": "base0E",
    "brightcyan": "base0C",
}
VIVID_REQUIRED_SLOTS = sorted(set(ANCHOR_SLOTS.values()) | set(BRIGHT_ANCHORS.values()))

# styles tree: category hierarchy → anchors; vivid resolves unlisted
# categories through nearest-ancestor fallback
STYLES_YML = """core:
  normal_text: {}

  regular_file: {}

  reset_to_normal: {}

  directory:
    foreground: magenta

  symlink:
    foreground: blue

  multi_hard_link:
    foreground: brightred

  fifo:
    foreground: bg
    background: blue

  socket:
    foreground: bg
    background: magenta

  door:
    foreground: brightgreen
    background: black

  block_device:
    foreground: yellow
    background: black

  character_device:
    foreground: magenta
    background: black

  broken_symlink:
    foreground: bg
    background: red

  missing_symlink_target:
    foreground: bg
    background: red

  setuid:
    foreground: white
    background: red
    font-style: bold

  setgid:
    foreground: white
    background: red

  file_with_capability:
    foreground: white
    background: magenta

  sticky_other_writable: {}

  other_writable: {}

  sticky: {}

  executable_file:
    foreground: red
    font-style: bold

text:
  special:
    foreground: brightblack
    background: yellow

  todo:
    font-style: bold

  licenses:
    foreground: white

  configuration:
    foreground: yellow

  other:
    foreground: yellow

markup:
  foreground: yellow

programming:
  source:
    foreground: green

  tooling:
    foreground: brightgreen

    continuous-integration:
      foreground: green

media:
  image:
    foreground: brightyellow

  audio:
    foreground: brightgreen

  video:
    foreground: brightmagenta

  3d:
    foreground: brightred

  fonts:
    foreground: brightwhite

office:
  foreground: brightred

archives:
  foreground: cyan
  font-style: underline

executable:
  foreground: red
  font-style: bold

unimportant:
  foreground: brightblack
"""


def _scheme_yaml_path(scheme_id: str) -> Path | None:
    """tinty scheme ID → its YAML file."""
    if scheme_id.startswith("base24-wallpaper-"):
        return (
            TINTY_DATA_DIR
            / "custom-schemes/base24"
            / f"{scheme_id.removeprefix('base24-')}.yaml"
        )
    if scheme_id.startswith("base24-"):
        return (
            TINTY_DATA_DIR
            / "repos/schemes/base24"
            / f"{scheme_id.removeprefix('base24-')}.yaml"
        )
    if scheme_id.startswith("base16-"):
        return (
            TINTY_DATA_DIR
            / "repos/schemes/base16"
            / f"{scheme_id.removeprefix('base16-')}.yaml"
        )
    return None


def _read_scheme_slots(scheme_id: str) -> dict[str, str] | None:
    path = _scheme_yaml_path(scheme_id)
    if path is None or not path.exists():
        return None
    yaml = YAML()
    yaml.preserve_quotes = True
    try:
        data = yaml.load(path.read_text())
    except OSError:
        return None
    if not isinstance(data, dict):
        return None
    palette = data.get("palette")
    if not isinstance(palette, dict):
        return None
    return {str(k): str(v) for k, v in palette.items()}


def vivid_theme_yml(slots: dict[str, str]) -> str:
    """LS_COLORS vivid theme: full anchor set + styles tree."""
    from theme.engines.base import ramp_mix

    order = [
        "bg",
        "fg",
        "black",
        "white",
        "brightblack",
        "brightwhite",
        "red",
        "green",
        "yellow",
        "blue",
        "magenta",
        "cyan",
        "brightred",
        "brightgreen",
        "brightyellow",
        "brightblue",
        "brightmagenta",
        "brightcyan",
    ]
    colors: dict[str, str] = {}
    for name, slot in ANCHOR_SLOTS.items():
        colors[name] = slots[slot].lstrip("#")
    for name, slot in BRIGHT_ANCHORS.items():
        colors[name] = ramp_mix(slots[slot], slots["base07"], 0.30).lstrip("#")
    lines = ["colors:"]
    for name in order:
        lines.append(f"    {name}: '{colors[name]}'")
    return "\n".join(lines) + "\n\n" + STYLES_YML


def derive_vivid_theme() -> str | None:
    """Derive theme.yml content from current_scheme; None = unreadable."""
    if not TINTY_CURRENT.exists():
        return None
    scheme_id = TINTY_CURRENT.read_text().strip()
    if not scheme_id:
        return None
    slots = _read_scheme_slots(scheme_id)
    if slots is None or any(s not in slots for s in VIVID_REQUIRED_SLOTS):
        return None
    return vivid_theme_yml(slots)


class VividComponent(Component):
    key = "vivid"
    group = "tui"

    def _current_scheme(self) -> str:
        return TINTY_CURRENT.read_text().strip() if TINTY_CURRENT.exists() else ""

    def consumed_slice(self, ctx: Context) -> dict[str, Any]:
        return {
            "theme_path": VIVID_THEME_PATH,
            "scheme": self._current_scheme(),
        }

    def write_effects(self, ctx: Context) -> Effects:
        # managed line first (the per-shell hook; independent of derivation)
        text = writers.read_surface(VIVID_LINE_FILE)
        new_text, _ = writers.managed_line_set(text, "VIVID_THEME", VIVID_THEME_PATH)
        atomic_write(VIVID_LINE_FILE, new_text)

        if ctx.dry_run:
            action("would derive vivid theme.yml from current_scheme")
            return Effects()

        scheme_id = self._current_scheme()
        if not scheme_id:
            fail("vivid: no scheme applied (current_scheme empty)")
            return Effects(code=1)
        content = derive_vivid_theme()
        if content is None:
            fail(f"vivid: cannot read applied scheme {scheme_id!r} ")
            return Effects(code=1)

        VIVID_THEME_FILE.parent.mkdir(parents=True, exist_ok=True)
        atomic_write(VIVID_THEME_FILE, content)
        ok("vivid: theme.yml derived")
        slice = {"theme_path": VIVID_THEME_PATH, "scheme": scheme_id}
        return Effects(
            record=(
                "tui",
                "vivid",
                make_record(
                    slice_hash(slice),
                    slice_hash(slice),
                    {},
                    {
                        "managed_line": {"VIVID_THEME": VIVID_THEME_PATH},
                        "derived_from": scheme_id,
                    },
                ),
            )
        )

    def status(self, ctx: Context) -> int:
        from theme.helpers.logio import note_state

        old = read_member("tui", "vivid")
        code = 0
        detail = None
        if not old or old.get("config_hash") != slice_hash(self.consumed_slice(ctx)):
            code |= 1
            detail = "no stamp or config changed"
        if VIVID_LINE_FILE.exists():
            text = VIVID_LINE_FILE.read_text()
            if "theme:managed" not in text or VIVID_THEME_PATH not in text:
                detail_line("drift vivid: managed line missing or stale")
                code |= 2
                detail = "managed line missing or stale"
        expected = derive_vivid_theme()
        if expected is not None:
            actual = VIVID_THEME_FILE.read_text() if VIVID_THEME_FILE.exists() else None
            if actual != expected:
                detail_line("drift vivid: theme.yml stale vs applied scheme")
                code |= 2
                detail = "theme.yml stale vs applied scheme"
        note_state(self.group, self.key, code, detail)
        return code

    def build(self, ctx: Context) -> dict[str, Any]:
        return {}
