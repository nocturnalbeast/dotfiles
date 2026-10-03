"""Palette generation: engines → v2 assembly → write-back → emission → stamp; pure + idempotent."""

from __future__ import annotations

import datetime
import hashlib
import json
from pathlib import Path
from typing import Any

from ruamel.yaml import YAML
from theme.engines import ENGINES, ENGINE_SUFFIX, GenerationError
from theme.engines.base import base24_to_core
from theme.helpers.logio import (
    StatusLog,
    action,
    atomic_write,
    console,
    detail_line,
    ok,
    phase,
    summary,
    warn,
)
from theme.state import STATE_DIR

REPO_ROOT = Path(__file__).resolve().parent.parent
from theme.config import DEFAULT_CONFIG

CONFIG_YAML = DEFAULT_CONFIG
EMISSION_STAMP = STATE_DIR / "palette.json"

CACHE_DIR = Path(__import__("os").environ.get("XDG_CACHE_HOME", Path.home() / ".cache"))
MATUGEN_COLORS_JSON = CACHE_DIR / "matugen" / "colors.json"
NVIM_PALETTES_DIR = Path.home() / ".local/share/nvim/site/lua/tinted-nvim/palettes"

TINTY_DATA_DIR = Path.home() / ".local/share/tinted-theming/tinty"
TINTY_SCHEME_DIR = TINTY_DATA_DIR / "custom-schemes/base24"

DEFAULT_ENGINES = {"gui": "matugen-faithful", "tui": "matugen-faithful"}

# back-compat re-exports (primitives live in theme/engines/)
from theme.engines.matugen import (  # noqa: E402,F401
    WHEEL_TO_BASE16,
    build_variant,
    derive_brights,
    post_process_contrast,
    resolve_mode,
    run_matugen,
)
from theme.engines.thaim import (  # noqa: E402,F401
    THAIM_SLOT_MAP,
    extract_thaimeleon as extract_thaim,
    thaim_slots,
)


def _read_engines_config() -> dict[str, str]:
    yaml = YAML()
    yaml.preserve_quotes = True
    with CONFIG_YAML.open(encoding="utf-8") as fh:
        data = yaml.load(fh) or {}
    engines = data.get("engines") or {}
    return {k: engines.get(k, DEFAULT_ENGINES[k]) for k in ("gui", "tui")}


def _assemble(
    gui_out: dict[str, Any],
    tui_out: dict[str, Any] | None,
    mode_preference: str,
    source_image: str,
    engine_cfg: dict[str, str],
    accent: str | None,
) -> dict[str, Any]:
    """Assemble v2: gui engine owns core + terminal_gui; tui engine owns extensions.terminal; accent override lands in core.accent."""
    if mode_preference in ("dark", "light"):
        effective = mode_preference
    else:
        effective = gui_out.get("detected_mode") or "dark"

    variants: dict[str, dict[str, Any]] = {}
    for m in ("dark", "light"):
        g = gui_out["variants"][m]
        core = dict(g["core"])
        derived = {k: v for k, v in g.get("derived", {}).items()}
        if accent:
            core["accent"] = accent
            derived["core.accent"] = "override"
        extensions: dict[str, Any] = {
            "terminal_gui": g["extensions"]["terminal"],
            "material": g["extensions"].get("material", {}),
        }
        if tui_out is not None:
            tui_variant = tui_out["variants"][m]
            extensions["terminal"] = tui_variant["extensions"]["terminal"]
            derived.update(tui_variant.get("derived", {}))
        variants[m] = {"core": core, "extensions": extensions, "derived": derived}

    return {
        "mode": mode_preference,
        "effective_mode": effective,
        "source": "wallpaper",
        "source_image": source_image,
        "generated_at": datetime.datetime.now().isoformat(timespec="seconds"),
        "engines": dict(engine_cfg),
        "variants": variants,
    }


def write_back(palette: dict[str, Any]) -> None:
    """Ruamel round-trip write-back into config.yaml; mtime-guarded, non-palette sections preserved byte-for-byte."""
    yaml = YAML()
    yaml.preserve_quotes = True
    mtime = CONFIG_YAML.stat().st_mtime if CONFIG_YAML.exists() else 0

    with CONFIG_YAML.open(encoding="utf-8") as fh:
        data = yaml.load(fh) or {}

    if CONFIG_YAML.exists() and CONFIG_YAML.stat().st_mtime != mtime:
        raise GenerationError(
            "config.yaml changed during generation — write-back aborted"
        )

    if "palette" not in data:
        data["palette"] = {}

    p = data["palette"]
    for key in (
        "source",
        "source_image",
        "generated_at",
        "effective_mode",
        "mode",
        "engines",
        "variants",
    ):
        p[key] = palette[key]

    from io import StringIO

    buf = StringIO()
    yaml.dump(data, buf)
    atomic_write(CONFIG_YAML, buf.getvalue())


def _tinty_scheme_yaml(
    name: str, display: str, mode: str, slots: dict[str, str]
) -> str:
    lines = [
        f'system: "base24"',
        f'name: "{display}"',
        'author: "theme"',
        f'variant: "{mode}"',
        "palette:",
    ]
    for i in range(24):
        slot = f"base{i:02X}"
        lines.append(f'  {slot}: "{slots.get(slot, "#000000")}"')
    return "\n".join(lines) + "\n"


def _nvim_palette_lua(mode: str, slots: dict[str, str]) -> str:
    lines = [
        f"return {{",
        f'    variant = "{mode}",',
        "",
    ]
    for i in range(24):
        slot = f"base{i:02X}"
        lines.append(f'    {slot} = "{slots.get(slot, "#000000")}",')
    lines.append("}")
    return "\n".join(lines) + "\n"


_DISPLAY_SUFFIX = {
    "": "",
    "-vibrant": " Vibrant",
    "-thaim": " Thaim",
    "-wallust": " Wallust",
}


def emit_artifacts(palette: dict[str, Any]) -> tuple[list[Path], dict[str, Any]]:
    """Emit tui scheme family + nvim palettes + colors.json; missing terminal group ⇒ tui family skipped, stamp tui=null."""
    written: list[Path] = []
    tui_name = palette["engines"]["tui"]
    gui_name = palette["engines"]["gui"]
    suffix = ENGINE_SUFFIX.get(tui_name, "")

    tui_ok = all(
        "terminal" in palette["variants"][m].get("extensions", {})
        for m in ("dark", "light")
    )
    if tui_ok:
        display_suffix = _DISPLAY_SUFFIX.get(suffix, suffix.title())
        TINTY_SCHEME_DIR.mkdir(parents=True, exist_ok=True)
        NVIM_PALETTES_DIR.mkdir(parents=True, exist_ok=True)
        for m in ("dark", "light"):
            terminal = palette["variants"][m]["extensions"]["terminal"]
            name = f"wallpaper-{m}{suffix}"
            display = f"Wallpaper {m.capitalize()}{display_suffix}"

            path = TINTY_SCHEME_DIR / f"{name}.yaml"
            atomic_write(path, _tinty_scheme_yaml(name, display, m, terminal))
            written.append(path)

            nvim_path = NVIM_PALETTES_DIR / f"base24-{name}.lua"
            atomic_write(nvim_path, _nvim_palette_lua(m, terminal))
            written.append(nvim_path)
    else:
        warn("tui engine output absent — tui scheme family not emitted")

    MATUGEN_COLORS_JSON.parent.mkdir(parents=True, exist_ok=True)
    effective = palette.get("effective_mode") or palette.get("mode") or "dark"
    colors_data: dict[str, Any] = {
        "colors": {},
        "base16": {},
        "image": palette.get("source_image", ""),
        "mode": effective,
        "is_dark_mode": effective == "dark",
        "palettes": {},
    }

    # Material extension stored per-mode as {camelCase_role: hex}; emitted
    # snake_case with dark/light/default entries (the bar's mc() reads entry[variant].color).
    import re as _re

    def _snake(name: str) -> str:
        return _re.sub(r"(?<!^)(?=[A-Z])", "_", name).lower()

    material_dark = (
        palette["variants"].get("dark", {}).get("extensions", {}).get("material", {})
    )
    material_light = (
        palette["variants"].get("light", {}).get("extensions", {}).get("material", {})
    )
    for role in set(material_dark) | set(material_light):
        key = _snake(role)
        d_hex = material_dark.get(role, material_light.get(role, "#000000"))
        l_hex = material_light.get(role, material_dark.get(role, "#ffffff"))
        colors_data["colors"][key] = {
            "dark": {"color": d_hex},
            "light": {"color": l_hex},
            "default": {"color": d_hex if effective == "dark" else l_hex},
        }
    for m in ("dark", "light"):
        terminal_gui = palette["variants"][m]["extensions"].get("terminal_gui") or {}
        for slot, hex_val in terminal_gui.items():
            if slot not in colors_data["base16"]:
                colors_data["base16"][slot] = {}
            colors_data["base16"][slot][m] = {"color": hex_val}
            colors_data["base16"][slot]["default"] = {"color": hex_val}
    atomic_write(MATUGEN_COLORS_JSON, json.dumps(colors_data, indent=2) + "\n")
    written.append(MATUGEN_COLORS_JSON)

    engines_emitted = {"gui": gui_name, "tui": tui_name if tui_ok else None}
    return written, engines_emitted


def write_emission_stamp(
    palette: dict[str, Any], engines_emitted: dict[str, Any]
) -> None:
    """palette.json stamp: image hash, section + artifact-set hashes, engines_emitted (tui null on degraded runs)."""
    palette_section = json.dumps(palette, sort_keys=True, default=str)
    stamp = {
        "image_hash": hashlib.sha256(
            Path(palette["source_image"]).read_bytes()
            if Path(palette["source_image"]).exists()
            else b""
        ).hexdigest()
        if palette.get("source_image")
        else None,
        "generated_at": palette.get("generated_at"),
        "engines_emitted": engines_emitted,
        "palette_section_hash": hashlib.sha256(palette_section.encode()).hexdigest(),
        "artifact_set_hash": hashlib.sha256(
            "".join(sorted(str(p) for p in emit_artifacts.__code__.co_consts)).encode()
        ).hexdigest(),
    }
    STATE_DIR.mkdir(parents=True, exist_ok=True)
    atomic_write(EMISSION_STAMP, json.dumps(stamp, indent=2) + "\n")


def _read_accent() -> str | None:
    yaml = YAML()
    yaml.preserve_quotes = True
    with CONFIG_YAML.open(encoding="utf-8") as fh:
        data = yaml.load(fh) or {}
    return (data.get("palette") or {}).get("accent")


def generate(
    image: str,
    mode: str = "auto",
    soft_tui: bool = False,
    dry_run: bool = False,
    engines: dict[str, str] | None = None,
) -> dict[str, Any]:
    """Full pipeline: gui engine → tui engine → assemble v2 → write-back → emission → stamp.

    soft_tui downgrades only non-critical tui engine failures;
    dry_run computes and reports without writes.
    """
    image_path = Path(image).resolve()
    if not image_path.exists():
        raise GenerationError(f"image not found: {image_path}")

    engine_cfg = engines or _read_engines_config()
    gui_engine = ENGINES[engine_cfg["gui"]]
    tui_engine = ENGINES[engine_cfg["tui"]]
    forced = mode if mode in ("dark", "light") else None

    with StatusLog(f"{gui_engine.name} · {image_path.name} ({mode})"):
        gui_out = gui_engine.extract(str(image_path), forced)
    if mode == "auto":
        detected = gui_out.get("detected_mode") or "dark"
        action(f"detected: {detected} wallpaper → {detected} theme")

    tui_out: dict[str, Any] | None = None
    try:
        with StatusLog(f"{tui_engine.name} extraction"):
            tui_out = tui_engine.extract(str(image_path), forced)
    except GenerationError as e:
        if soft_tui and not tui_engine.critical:
            warn(f"tui engine ({tui_engine.name}) skipped: {e}")
        else:
            raise

    if dry_run:
        phase("palette · dry run")
        from theme.helpers.logio import swatch_row

        for m in ("dark", "light"):
            core = gui_out["variants"][m]["core"]
            row = swatch_row(
                [
                    (core["background"], "bg"),
                    (core["foreground"], "fg"),
                    (core["accent"], "accent"),
                    (core["status.error"], "error"),
                    (core["status.success"], "ok"),
                    (core["status.info"], "info"),
                ]
            )
            row.append(f"  {m}", style="dim")
            console.print(row)
        detail_line(
            f"tui engine: {tui_engine.name} ({'ok' if tui_out else 'failed/skipped'})"
        )
        detail_line("would write: config.yaml palette section (v2)")
        detail_line(f"would emit: {tui_engine.name} scheme family + colors.json")
        summary("Dry run: palette computed. No files written.")
        return _assemble(gui_out, tui_out, mode, str(image_path), engine_cfg, None)

    palette = _assemble(
        gui_out, tui_out, mode, str(image_path), engine_cfg, _read_accent()
    )
    write_back(palette)
    summary("palette written back to config.yaml")

    artifacts, engines_emitted = emit_artifacts(palette)
    for a in artifacts:
        action(f"emitted {a}")

    write_emission_stamp(palette, engines_emitted)
    summary("emission stamp written")

    return palette


def emit_only() -> list[Path]:
    """Re-emit artifacts from the stored v2 palette alone; missing terminal group skips the tui family (stamp tui=null)."""
    yaml = YAML()
    yaml.preserve_quotes = True
    with CONFIG_YAML.open(encoding="utf-8") as fh:
        data = yaml.load(fh) or {}

    palette = data.get("palette")
    if not palette or not isinstance(palette, dict):
        raise GenerationError("no palette section in config.yaml")

    variants = palette.get("variants")
    if not variants or not isinstance(variants, dict):
        raise GenerationError("palette.variants missing or incomplete")
    if "core" not in next(iter(variants.values()), {}):
        raise GenerationError(
            "palette section is v1 (no core) — run `theme palette generate`"
        )

    artifacts, engines_emitted = emit_artifacts(dict(palette))
    for a in artifacts:
        ok(f"emitted {a}")

    write_emission_stamp(dict(palette), engines_emitted)
    return artifacts
