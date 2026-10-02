"""Config load/merge/validate + the --override grammar (defaults < config.yaml < CLI)."""

from __future__ import annotations

import copy
import re
import os
from pathlib import Path
from typing import Any

from ruamel.yaml import YAML

from theme.helpers.logio import err_console

REPO_ROOT = Path(__file__).resolve().parent.parent


def _default_config() -> Path:
    xdg = (
        Path(os.environ.get("XDG_CONFIG_HOME", str(Path.home() / ".config")))
        / "theming"
        / "config.yaml"
    )
    if xdg.exists():
        return xdg
    if (REPO_ROOT / "config.yaml").exists():
        return REPO_ROOT / "config.yaml"
    return xdg


DEFAULT_CONFIG = _default_config()

DEFAULTS: dict[str, dict[str, Any]] = {
    "gui": {
        "theme": "colloid",
        "tweaks": ["black", "rimless"],
        "size": "standard",
        "icon_pack": "tela",
        "icon_theme": "hicolor",
        "cursor_pack": "bibata_original",
        "cursor_theme": "volantes_light_cursors",
        "cursor_size": 24,
        "env_override": False,
        "font_size": 12,
    },
    "qt": {"style": "kvantum"},
    "fonts": {
        "sans": [
            "Inter Display",
            "Inter Tight",
            "Inter",
            "Noto Sans",
            "JoyPixels",
            "Symbola",
        ],
        "serif": ["Libre Baskerville", "Noto Serif", "JoyPixels", "Symbola"],
        "monospace": ["VictorMono Nerd Font", "Noto Sans Mono", "JoyPixels", "Symbola"],
    },
    "tui": {"scheme": "follow", "mode": "auto", "approx_threshold": 5.0},
    "engines": {"gui": "matugen-faithful", "tui": "matugen-faithful"},
    "wallpaper": {
        "sync": False,
        "tracker": "~/.config/wm/current_wallpaper",
        "on_change": ["all"],
    },
}

ENUMS: dict[tuple[str, str], set[str]] = {
    ("gui", "theme"): {"colloid", "materia", "orchis"},
    ("gui", "size"): {"standard", "compact"},
    ("qt", "style"): {"kvantum", "fusion"},
    ("tui", "scheme"): {"follow", "approx"}
    | {""},  # follow | approx | fixed name (free string)
    ("tui", "mode"): {"auto", "dark", "light"},
    ("engines", "gui"): {"matugen-faithful", "matugen-vibrant", "thaim", "wallust"},
    ("engines", "tui"): {"matugen-faithful", "matugen-vibrant", "thaim", "wallust"},
}

INT_KEYS: set[tuple[str, str]] = {("gui", "cursor_size"), ("gui", "font_size")}
FLOAT_KEYS: set[tuple[str, str]] = {("tui", "approx_threshold")}
BOOL_KEYS: set[tuple[str, str]] = {("gui", "env_override"), ("wallpaper", "sync")}
LIST_KEYS: set[tuple[str, str]] = {
    ("gui", "tweaks"),
    ("wallpaper", "on_change"),
    ("fonts", "sans"),
    ("fonts", "serif"),
    ("fonts", "monospace"),
}

TUI_SCHEME_ENUM = {
    "follow",
    "approx",
}  # anything else = fixed scheme name (validated at tui apply)

HEXISH = re.compile(r"^#[0-9A-Fa-f]{6}$")


class ConfigError(Exception):
    pass


def load_yaml(path: Path) -> dict[str, Any]:
    yaml = YAML()
    yaml.preserve_quotes = True
    if not path.exists():
        return {}
    with path.open(encoding="utf-8") as fh:
        data = yaml.load(fh)
    if data is None:
        return {}
    if not isinstance(data, dict):
        raise ConfigError(f"{path}: top level must be a mapping")
    return data


def _coerce_scalar(raw: str, section: str, key: str) -> Any:
    target_int = (section, key) in INT_KEYS
    target_bool = (section, key) in BOOL_KEYS
    target_float = (section, key) in FLOAT_KEYS
    if target_int:
        try:
            return int(raw)
        except ValueError:
            raise ConfigError(f"override {section}.{key}: expected int, got {raw!r}")
    if target_float:
        try:
            return float(raw)
        except ValueError:
            raise ConfigError(f"override {section}.{key}: expected float, got {raw!r}")
    if target_bool:
        low = raw.lower()
        if low in ("true", "false"):
            return low == "true"
        raise ConfigError(f"override {section}.{key}: expected bool, got {raw!r}")
    return raw


def parse_override(token: str) -> tuple[tuple[str, ...], Any]:
    """Parse 'dot.path:value' → (path parts, typed value); first : or = splits, lists comma-split."""
    m = re.match(r"^([A-Za-z0-9_.\-]+?)[:=](.+)$", token)
    if not m:
        raise ConfigError(f"malformed override {token!r} (expected dot.path:value)")
    path_raw, value = m.group(1), m.group(2)
    if not value.strip():
        raise ConfigError(f"override {token!r}: empty value")
    parts = tuple(path_raw.split("."))
    if len(parts) < 2:
        raise ConfigError(f"override {token!r}: dot-path must include a section")
    section, key = parts[0], parts[1]
    if (section, key) in LIST_KEYS and len(parts) == 2:
        items = [x for x in value.split(",")]
        if any(not x.strip() for x in items):
            raise ConfigError(f"override {token!r}: empty list element")
        return parts, items
    if "," in value and (section, key) not in LIST_KEYS:
        raise ConfigError(f"override {token!r}: comma in scalar value")
    return parts, _coerce_scalar(value, section, key)


def apply_overrides(resolved: dict[str, Any], overrides: list[str]) -> dict[str, Any]:
    seen: set[tuple[str, ...]] = set()
    for token in overrides:
        parts, value = parse_override(token)
        if parts in seen:
            raise ConfigError(f"duplicate override for {'.'.join(parts)}")
        seen.add(parts)
        node: Any = resolved
        for p in parts[:-1]:
            if not isinstance(node, dict) or p not in node:
                raise ConfigError(f"override {token!r}: unknown dot-path")
            node = node[p]
        last = parts[-1]
        if not isinstance(node, dict) or last not in node:
            raise ConfigError(f"override {token!r}: unknown key")
        node[last] = value
    return resolved


def validate(resolved: dict[str, Any]) -> None:
    for section, keys in DEFAULTS.items():
        if section not in resolved:
            continue
        for key in resolved[section]:
            if key not in keys:
                raise ConfigError(f"unknown key {section}.{key}")
        for (s, k), allowed in ENUMS.items():
            if s == section and k in resolved[section]:
                val = resolved[section][k]
                if s == "tui" and k == "scheme" and val not in TUI_SCHEME_ENUM:
                    continue  # fixed scheme name: free string
                if val not in allowed:
                    raise ConfigError(f"{s}.{k}: {val!r} not in {sorted(allowed)}")
    palette = resolved.get("palette")
    if palette is not None:
        if not isinstance(palette, dict):
            raise ConfigError("palette: must be a mapping")
        mode = palette.get("mode")
        if mode not in ("auto", "dark", "light"):
            raise ConfigError(f"palette.mode: {mode!r} must be auto|dark|light")
        for top in ("accent",):
            v = palette.get(top)
            if v is not None and not HEXISH.match(str(v)):
                raise ConfigError(f"palette.{top}: malformed hex {v!r}")
    tau = resolved.get("tui", {}).get("approx_threshold")
    if (
        not isinstance(tau, (int, float))
        or isinstance(tau, bool)
        or not 0.0 < float(tau) < 100.0
    ):
        raise ConfigError(f"tui.approx_threshold: {tau!r} must be a float in (0, 100)")


def resolve(
    config_path: Path | None = None,
    overrides: list[str] | None = None,
) -> dict[str, Any]:
    """defaults < yaml < overrides → validated plain-dict view."""
    path = config_path or DEFAULT_CONFIG
    from theme.migrate import migrate, needs_migration

    if path.exists() and needs_migration(path):
        migrate(path)
    resolved = copy.deepcopy(DEFAULTS)
    file_data = load_yaml(path)
    for section, values in file_data.items():
        if section == "palette":
            resolved["palette"] = dict(values)
            continue
        if section not in resolved:
            raise ConfigError(f"unknown section {section!r}")
        if not isinstance(values, dict):
            raise ConfigError(f"section {section}: must be a mapping")
        resolved[section].update(values)
    if overrides:
        apply_overrides(resolved, overrides)
    validate(resolved)
    return resolved


def load_roundtrip(config_path: Path | None = None) -> Any:
    """ruamel round-trip view for write-back."""
    return load_yaml(config_path or DEFAULT_CONFIG)
