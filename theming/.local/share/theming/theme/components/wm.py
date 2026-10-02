"""WM members: xresources, chrome, notify, lock, menu, bar."""

from __future__ import annotations

import re
import shutil
import subprocess
from pathlib import Path
from typing import Any

from theme.components.base import Component, Effects
from theme.helpers import writers
from theme.helpers.logio import atomic_write, fail, ok, warn
from theme.engines.base import ramp_mix
from theme.palette import core_token, mode, ramp16, slice_hash, slot16
from theme.resources.base import Context
from theme.state import make_record, read_member

HOME = Path.home()
XRESOURCES = HOME / ".config/X11/xresources"
DMENU_XRES = HOME / ".config/X11/xresources.d/dmenu"
AWESOME_THEME = HOME / ".config/awesome/theme.lua"
BSPWM_SET_COLORS = HOME / ".config/bspwm/set-colors"
HYPRland_CONF = HOME / ".config/hypr/hyprland.conf"
HYPRLOCK_CONF = HOME / ".config/hypr/hyprlock.conf"
DUNSTRC = HOME / ".config/dunst/dunstrc"


def _ini_value(key: str, value: str) -> str:
    """INI line: numerics bare, strings quoted (dunst parses both; bare is conventional)."""
    if value.isdigit():
        return f"{key} = {value}"
    return f'{key} = "{value}"'


MAKO_CONFIG = HOME / ".config/mako/config"
SCREENLOCK_ENV = HOME / ".config/profile.d/gui/20-screenlock.sh"
MENU_ENV = HOME / ".config/profile.d/gui/10-menu.sh.nosource"
QS_DEFAULTS = HOME / ".config/quickshell/config/Defaults.qml"


def _ramp16(ctx: Context) -> dict[str, str]:
    return ramp16(ctx.palette)


def _slot(ctx: Context, name: str) -> str:
    return slot16(ctx.palette, name)


def _rgb_colon(hex_color: str) -> str:
    """#0d0d0d → rgb:0d/0d/0d (xsecurelock format, W8)."""
    h = hex_color.lstrip("#").lower()
    if len(h) != 6 or not re.fullmatch(r"[0-9a-f]{6}", h):
        raise RuntimeError(f"malformed hex for rgb: conversion: {hex_color!r}")
    return f"rgb:{h[0:2]}/{h[2:4]}/{h[4:6]}"


class WMMember(Component):
    group = "wm"

    def _eff(self, ctx: Context, surfaces: dict[str, Any], **kw: Any) -> Effects:
        h = slice_hash(self.consumed_slice(ctx))
        shaped = {k: {"value": v} for k, v in surfaces.items()}
        return Effects(record=("wm", self.key, make_record(h, h, {}, shaped)), **kw)

    def consumed_slice(self, ctx: Context) -> dict[str, Any]:
        return {"palette_mode": mode(ctx.palette)}

    def build(self, ctx: Context) -> dict[str, Any]:
        return {}


# -- xresources (W1) ---------------------------------------------------------


class XresourcesMember(WMMember):
    key = "xresources"

    def write_effects(self, ctx: Context) -> Effects:
        if ctx.dry_run:
            ok("xresources: would write colors + dmenu palette (dry-run)")
            return Effects()
        ramp = _ramp16(ctx)
        if len(ramp) < 16:
            fail("xresources: ramp incomplete (terminal_gui missing slots)")
            return Effects(code=1)
        updates = {}
        # ANSI → base16 slot uses the terminal-standard mapping, NOT
        # sequential base16 — color8 is bright-black, not base08/error-red
        ansi_to_base16 = {
            0: "base00",
            1: "base08",
            2: "base0B",
            3: "base0A",
            4: "base0D",
            5: "base0E",
            6: "base0C",
            7: "base05",
            8: "base03",
            9: "base12",
            10: "base13",
            11: "base14",
            12: "base15",
            13: "base16",
            14: "base17",
            15: "base07",
        }
        for ansi, slot_name in ansi_to_base16.items():
            updates[f"*.color{ansi}"] = ramp.get(slot_name, "#000000")
        updates["*.foreground"] = _slot(ctx, "base05")
        updates["*.background"] = _slot(ctx, "base00")
        updates["*.cursorColor"] = _slot(ctx, "base06")
        text = writers.read_surface(XRESOURCES) if XRESOURCES.exists() else ""
        new_text = writers.update_colon_kv(text, updates)
        atomic_write(XRESOURCES, new_text)

        dmenu_updates = {
            "dmenu.background": _slot(ctx, "base00"),
            "dmenu.foreground": _slot(ctx, "base06"),
            "dmenu.selbackground": core_token(ctx.palette, "accent"),
            "dmenu.selforeground": _slot(ctx, "base00"),
            "dmenu.hlbackground": core_token(ctx.palette, "accent"),
            "dmenu.hlforeground": _slot(ctx, "base00"),
            "dmenu.selhlbackground": _slot(ctx, "base01"),
            "dmenu.selhlforeground": _slot(ctx, "base06"),
        }
        dtext = writers.read_surface(DMENU_XRES) if DMENU_XRES.exists() else ""
        atomic_write(DMENU_XRES, writers.update_colon_kv(dtext, dmenu_updates))
        return self._eff(
            ctx,
            {"xresources": "written", "dmenu": "written"},
            reloads=[("xrdb", {})],
        )

    def status(self, ctx: Context) -> int:
        from theme.helpers.logio import note_state

        old = read_member("wm", self.key)
        code = 0
        if not old or old.get("config_hash") != slice_hash(self.consumed_slice(ctx)):
            code |= 1
        if XRESOURCES.exists():
            text = XRESOURCES.read_text()
            fg = re.search(r"\*\.foreground:\s+(\S+)", text)
            if fg and fg.group(1).lower() != _slot(ctx, "base05").lower():
                code |= 2
        note_state(self.group, self.key, code)
        return code


# -- chrome (W2 + W3 + W4) ---------------------------------------------------


class ChromeMember(WMMember):
    key = "chrome"

    def write_effects(self, ctx: Context) -> Effects:
        if ctx.dry_run:
            ok("chrome: would normalize awesome + write bspwm/hypr borders")
            return Effects()

        # W2: awesome prism block removal + fallback normalization
        if AWESOME_THEME.exists():
            lua = AWESOME_THEME.read_text()
            original = lua
            lua = re.sub(
                r"local ok, prism = pcall\(require, \"prismtheme\"\)\n", "", lua
            )
            lua = lua.replace(
                """local function color(key, fallback)
    if ok and prism[key] then
        return prism[key]
    end
    return xrdb[key] or fallback
end""",
                """local function color(key, fallback)
    return xrdb[key] or fallback
end""",
            )
            if lua != original:
                atomic_write(AWESOME_THEME, lua)
                ok("awesome theme.lua: prism block removed (W2)")
            if "prismtheme" in lua:
                fail("awesome theme.lua still references prismtheme (W2 drift)")
                return Effects(code=1)

        # W3: bspwm set-colors rewrite (execution is the bspwm reload)
        if BSPWM_SET_COLORS.exists():
            script = BSPWM_SET_COLORS.read_text()
            script = re.sub(
                r'(focused_border_color\s+")[0-9a-fA-F]{6}(")',
                rf"\g<1>{_slot(ctx, 'base03')}\g<2>",
                script,
            )
            script = re.sub(
                r'(active_border_color\s+")[0-9a-fA-F]{6}(")',
                rf"\g<1>{_slot(ctx, 'base03')}\g<2>",
                script,
            )
            script = re.sub(
                r'(normal_border_color\s+")[0-9a-fA-F]{6}(")',
                rf"\g<1>{_slot(ctx, 'base04')}\g<2>",
                script,
            )
            script = re.sub(
                r'(urgent_border_color\s+")[0-9a-fA-F]{6}(")',
                rf"\g<1>{_slot(ctx, 'base08')}\g<2>",
                script,
            )
            script = re.sub(
                r'(presel_feedback_color\s+")[0-9a-fA-F]{6}(")',
                rf"\g<1>{core_token(ctx.palette, 'accent')}\g<2>",
                script,
            )
            atomic_write(BSPWM_SET_COLORS, script)

        # W4: hypr borders
        if HYPRland_CONF.exists():
            conf = HYPRland_CONF.read_text()
            accent = core_token(ctx.palette, "accent").lstrip("#")
            inactive = _slot(ctx, "base03").lstrip("#")
            conf = re.sub(
                r"col\.active_border\s*=\s*rgba\([0-9a-fA-F]+(?:[0-9a-fA-F]{2})?\)",
                f"col.active_border = rgba({accent}bb)",
                conf,
            )
            conf = re.sub(
                r"col\.inactive_border\s*=\s*rgba\([0-9a-fA-F]+(?:[0-9a-fA-F]{2})?\)",
                f"col.inactive_border = rgba({inactive}22)",
                conf,
            )
            atomic_write(HYPRland_CONF, conf)
            ok("hypr borders written (W4 — next session)")

        return self._eff(
            ctx,
            {"awesome": "prism-absent", "bspwm": "written", "hypr": "written"},
            reloads=[("bspwm", {}), ("awesome", {})],
        )

    def status(self, ctx: Context) -> int:
        from theme.helpers.logio import note_state

        old = read_member("wm", self.key)
        code = 0
        if not old or old.get("config_hash") != slice_hash(self.consumed_slice(ctx)):
            code |= 1
        if AWESOME_THEME.exists() and "prismtheme" in AWESOME_THEME.read_text():
            code |= 2
        note_state(self.group, self.key, code)
        return code


# -- notify (W6 + W7) ----------------------------------------------------------


class NotifyMember(WMMember):
    key = "notify"

    def _notify_icon_settings(self, ctx: Context) -> tuple[str, int]:
        """(icon_theme, min_icon_size): XDG icon dirs are Type=Fixed —
        a size not shipped as a dir misses even when the file exists;
        use the largest fixed dir containing dialog icons."""
        from theme.resources.base import ICON_PACKS

        pack_key = ctx.config["gui"]["icon_pack"]
        theme_name = ICON_PACKS[pack_key]().naming_for(ctx) if pack_key else "hicolor"
        theme_root = Path.home() / ".local/share/icons" / theme_name
        sizes = []
        if theme_root.is_dir():
            for child in theme_root.iterdir():
                if child.is_dir() and child.name.isdigit():
                    probe = child / "actions" / "dialog-warning.svg"
                    if probe.exists():
                        sizes.append(int(child.name))
        return theme_name, max(sizes, default=24)

    def _notify_colors(self, ctx: Context) -> dict[str, str]:
        accent = core_token(ctx.palette, "accent")
        error = core_token(ctx.palette, "status.error")
        bg = _slot(ctx, "base00")
        bg_subtle = _slot(ctx, "base01")
        fg = _slot(ctx, "base06")
        fg_subtle = _slot(ctx, "base03")
        deep_red = ramp_mix(error, bg, 0.65)
        return {
            "accent": accent,
            "error": error,
            "deep_red": deep_red,
            "bg": bg,
            "bg_subtle": bg_subtle,
            "fg": fg,
            "fg_subtle": fg_subtle,
        }

    def write_effects(self, ctx: Context) -> Effects:
        if ctx.dry_run:
            ok("notify: would write dunst + mako palettes")
            return Effects()

        n = self._notify_colors(ctx)
        icon_theme, min_icon_size = self._notify_icon_settings(ctx)

        # W6 dunst — key-scoped INI rewrite
        if DUNSTRC.exists():
            text = DUNSTRC.read_text()
            section = ""
            out = []
            wanted = {
                "[global]": {
                    "frame_color": n["accent"],
                    "icon_theme": icon_theme,
                    "min_icon_size": str(min_icon_size),
                },
                "[urgency_low]": {
                    "background": n["bg_subtle"],
                    "foreground": n["fg_subtle"],
                    "frame_color": n["accent"],
                    "icon": "dialog-information",
                },
                "[urgency_normal]": {
                    "background": n["bg_subtle"],
                    "foreground": n["fg"],
                    "frame_color": n["accent"],
                    "icon": "dialog-warning",
                },
                "[urgency_critical]": {
                    "background": n["deep_red"],
                    "foreground": n["bg"],
                    "frame_color": n["error"],
                    "icon": "dialog-error",
                },
            }
            seen: set[str] = set()
            for line in text.splitlines():
                stripped = line.strip()
                if stripped.startswith("[") and stripped.endswith("]"):
                    section = stripped
                    out.append(line)
                    continue
                if "=" in line and not stripped.startswith("#"):
                    key = line.split("=", 1)[0].strip()
                    if section in wanted and key in wanted[section]:
                        out.append(_ini_value(key, wanted[section][key]))
                        seen.add(f"{section} {key}")
                        continue
                out.append(line)
            # append missing urgency keys into their sections
            for sec, sec_updates in wanted.items():
                if not sec.startswith("["):
                    continue
                try:
                    idx = out.index(sec)
                except ValueError:
                    out.append(sec)
                    idx = len(out) - 1
                insert_at = idx + 1
                while (
                    insert_at < len(out)
                    and out[insert_at].strip()
                    and not out[insert_at].startswith("[")
                ):
                    insert_at += 1
                for key, value in sec_updates.items():
                    if f"{sec} {key}" not in seen:
                        out.insert(insert_at, _ini_value(key, value))
                        insert_at += 1
            atomic_write(DUNSTRC, "\n".join(out) + "\n")
            ok("dunst config written (W6)")

        # W7 mako — key-scoped rewrite, same mapping
        if MAKO_CONFIG.exists():
            updates = {
                "default": {
                    "background-color": n["bg_subtle"],
                    "text-color": n["fg"],
                    "border-color": n["accent"],
                    "progress-color": n["fg_subtle"],
                    "icon-path": f"$HOME/.local/share/icons/{icon_theme}:/usr/share/icons/breeze",
                },
                "[urgency=low]": {
                    "background-color": n["bg_subtle"],
                    "text-color": n["fg_subtle"],
                    "border-color": n["accent"],
                },
                "[urgency=normal]": {
                    "background-color": n["bg_subtle"],
                    "text-color": n["fg"],
                    "border-color": n["accent"],
                },
                "[urgency=critical]": {
                    "background-color": n["deep_red"],
                    "text-color": n["bg"],
                    "border-color": n["error"],
                    "progress-color": n["error"],
                },
            }
            text = MAKO_CONFIG.read_text()
            section = "default"
            out = []
            written: set[tuple[str, str]] = set()
            skip_legacy = False
            for line in text.splitlines():
                stripped = line.strip()
                if stripped.startswith("[") and stripped.endswith("]"):
                    skip_legacy = stripped == "[urgency=high]"
                    section = stripped
                    if not skip_legacy:
                        out.append(line)
                    continue
                if skip_legacy:
                    continue
                if "=" in line and not stripped.startswith("#"):
                    key = line.split("=", 1)[0].strip()
                    sec_updates = updates.get(section, {})
                    if key in sec_updates:
                        out.append(f"{key}={sec_updates[key]}")
                        written.add((section, key))
                        continue
                out.append(line)
            for sec, sec_updates in updates.items():
                if sec == "default":
                    continue
                try:
                    idx = out.index(sec)
                except ValueError:
                    out.append(sec)
                    idx = len(out) - 1
                insert_at = idx + 1
                while (
                    insert_at < len(out)
                    and out[insert_at].strip()
                    and not out[insert_at].startswith("[")
                ):
                    insert_at += 1
                for key, value in sec_updates.items():
                    if (sec, key) not in written:
                        out.insert(insert_at, f"{key}={value}")
                        insert_at += 1
            atomic_write(MAKO_CONFIG, "\n".join(out) + "\n")
            ok("mako config written (W7)")

        return self._eff(
            ctx,
            {"dunst": "written", "mako": "written"},
            reloads=[("dunst", {}), ("mako", {})],
        )

    def status(self, ctx: Context) -> int:
        from theme.helpers.logio import note_state

        old = read_member("wm", self.key)
        code = 0
        if not old or old.get("config_hash") != slice_hash(self.consumed_slice(ctx)):
            code |= 1
        note_state(self.group, self.key, code)
        return code


# -- lock (W8 + W5) -------------------------------------------------------------


class LockMember(WMMember):
    key = "lock"

    def write_effects(self, ctx: Context) -> Effects:
        if ctx.dry_run:
            ok("lock: would write xsecurelock env + hyprlock colors")
            return Effects()

        # W8: xsecurelock managed env lines (rgb: conversion)
        conversions = {
            "XSECURELOCK_AUTH_BACKGROUND_COLOR": _rgb_colon(_slot(ctx, "base00")),
            "XSECURELOCK_AUTH_FOREGROUND_COLOR": _rgb_colon(_slot(ctx, "base06")),
            "XSECURELOCK_AUTH_WARNING_COLOR": _rgb_colon(_slot(ctx, "base08")),
            "XSECURELOCK_DIM_COLOR": _rgb_colon(_slot(ctx, "base00")),
            "XSECURELOCK_FONT": "sans:style=Bold:antialias=true",
        }
        text = writers.read_surface(SCREENLOCK_ENV) if SCREENLOCK_ENV.exists() else ""
        for var, value in conversions.items():
            text, _ = writers.managed_line_set(text, var, f'"{value}"')
        atomic_write(SCREENLOCK_ENV, text)
        ok("xsecurelock env written (W8 — next lock)")

        # W5: hyprlock — key-scoped color writes in widget blocks
        if HYPRLOCK_CONF.exists():
            conf = HYPRLOCK_CONF.read_text()
            accent = core_token(ctx.palette, "accent")
            conf = re.sub(r"\$font\s*=\s*\S+", "$font = Monospace", conf)
            conf = re.sub(
                r"outer_color\s*=\s*rgba\([^)]*\)",
                f"outer_color = rgb({accent.lstrip('#')})",
                conf,
            )
            conf = re.sub(
                r"check_color\s*=\s*rgba\([^)]*\)",
                f"check_color = rgb({accent.lstrip('#')})",
                conf,
            )
            conf = re.sub(
                r"fail_color\s*=\s*rgba\([^)]*\)",
                f"fail_color = rgb({_slot(ctx, 'base08').lstrip('#')})",
                conf,
            )
            conf = re.sub(
                r"font_color\s*=\s*rgb\([^)]*\)",
                f"font_color = rgb({_slot(ctx, 'base06').lstrip('#')})",
                conf,
            )
            atomic_write(HYPRLOCK_CONF, conf)
            ok("hyprlock colors written (W5 — next lock)")

        return self._eff(ctx, {"xsecurelock": "written", "hyprlock": "written"})

    def status(self, ctx: Context) -> int:
        from theme.helpers.logio import note_state

        old = read_member("wm", self.key)
        code = 0
        if not old or old.get("config_hash") != slice_hash(self.consumed_slice(ctx)):
            code |= 1
        note_state(self.group, self.key, code)
        return code


# -- menu (W9) -------------------------------------------------------------------


class MenuMember(WMMember):
    key = "menu"

    def write_effects(self, ctx: Context) -> Effects:
        if ctx.dry_run:
            ok("menu: would write MENU_COLOR_* palette")
            return Effects()
        updates = {
            "MENU_COLOR_BG": _slot(ctx, "base00"),
            "MENU_COLOR_FG": _slot(ctx, "base06"),
            "MENU_COLOR_HEADER_BG": _slot(ctx, "base01"),
            "MENU_COLOR_HEADER_FG": _slot(ctx, "base06"),
            "MENU_COLOR_SELECTED_BG": core_token(ctx.palette, "accent"),
            "MENU_COLOR_SELECTED_FG": _slot(ctx, "base00"),
            "MENU_COLOR_SELECTED_FG_ACTIVE": _slot(ctx, "base03"),
            "MENU_COLOR_SELECTED_FG_URGENT": _slot(ctx, "base08"),
            "MENU_COLOR_BORDER": _slot(ctx, "base04"),
            "MENU_COLOR_SEPARATOR": _slot(ctx, "base04"),
        }
        text = writers.read_surface(MENU_ENV) if MENU_ENV.exists() else ""
        lines = text.splitlines()
        out = []
        seen: set[str] = set()
        for line in lines:
            matched = False
            if line.startswith("MENU_COLOR_") and "=" in line:
                var = line.split("=", 1)[0].strip()
                if var in updates:
                    out.append(f'{var}="{updates[var]}" # theme:managed')
                    seen.add(var)
                    matched = True
            if not matched:
                out.append(line)
        for var, value in updates.items():
            if var not in seen:
                out.append(f'{var}="{value}" # theme:managed')
        atomic_write(MENU_ENV, "\n".join(out) + "\n")
        ok("menu palette written (W9 — next invocation)")
        return self._eff(ctx, {"menu": "written"})

    def status(self, ctx: Context) -> int:
        from theme.helpers.logio import note_state

        old = read_member("wm", self.key)
        code = 0
        if not old or old.get("config_hash") != slice_hash(self.consumed_slice(ctx)):
            code |= 1
        note_state(self.group, self.key, code)
        return code


# -- bar (W10) ---------------------------------------------------------------------


class BarMember(WMMember):
    key = "bar"

    def consumed_slice(self, ctx: Context) -> dict[str, Any]:
        slice_ = super().consumed_slice(ctx)
        slice_["sans"] = ctx.config["fonts"]["sans"][0]
        return slice_

    def write_effects(self, ctx: Context) -> Effects:
        if ctx.dry_run:
            ok("bar: would write barFontFamily")
            return Effects()
        if not QS_DEFAULTS.exists():
            warn("quickshell Defaults.qml absent — bar member no-op")
            return self._eff(ctx, {})
        sans = ctx.config["fonts"]["sans"][0]
        conf = QS_DEFAULTS.read_text()
        conf, n = re.subn(r'barFontFamily:\s*"[^"]*"', f'barFontFamily: "{sans}"', conf)
        if n == 0:
            fail("barFontFamily line not found in Defaults.qml (W10 anchor drift)")
            return Effects(code=1)
        atomic_write(QS_DEFAULTS, conf)
        ok("bar font written (W10 — restart qs)")
        return self._eff(ctx, {"defaults_qml": "written"})

    def status(self, ctx: Context) -> int:
        from theme.helpers.logio import note_state

        old = read_member("wm", self.key)
        code = 0
        if not old or old.get("config_hash") != slice_hash(self.consumed_slice(ctx)):
            code |= 1
        note_state(self.group, self.key, code)
        return code
