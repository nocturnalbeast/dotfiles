"""macOS + Track B member tests: goldens + platform gating."""

from __future__ import annotations

import sys
import unittest
from typing import Any
from unittest import mock

from theme.components.base import Component, Effects
from theme.resources.base import Context

MATERIAL = {
    "surface": "#0f1114",
    "surface_container_high": "#1c1f24",
    "outline": "#71757c",
    "primary": "#9ccbfb",
    "on_surface_variant": "#c3c6cc",
    "on_surface": "#dfe2e8",
    "error": "#ffb3b2",
    "tertiary": "#eeb4ea",
    "inverse_primary": "#35485c",
    "on_primary_fixed": "#0d1d2c",
    "tertiary_container": "#4c3f4b",
    "outline_variant": "#44474e",
    "red": "#ffb3b2",
    "orange": "#fbb974",
    "yellow": "#cbcb76",
    "lime": "#a9d49b",
    "green": "#a0d49b",
    "mint": "#8ebbb1",
    "teal": "#80d4d4",
    "azure": "#9ccbfb",
    "blue": "#afaccf",
    "violet": "#dbb9f9",
    "magenta": "#eeb4ea",
    "rose": "#ffb3b2",
}


def palette_with_material(material: dict[str, str]) -> dict[str, Any]:
    return {
        "effective_mode": "dark",
        "variants": {"dark": {"core": {}, "extensions": {"material": material}}},
    }


class TestSketchybar(unittest.TestCase):
    def test_colors_lua_argb_golden(self):
        from theme.components.sketchybar import colors_lua

        lua = colors_lua(MATERIAL)
        self.assertIn("surface = 0xff0F1114,", lua)
        self.assertIn("primary = 0xff9CCBFB,", lua)
        self.assertIn("outline_variant = 0xff44474E,", lua)
        for role in ("teal", "green", "tertiary_container"):
            self.assertIn(f"{role} = ", lua)
        self.assertNotIn("violet = ", lua)
        self.assertNotIn("lime = ", lua)

    def test_missing_role_fails_loud(self):
        from theme.palette import PaletteError, material_roles
        from theme.components.sketchybar import REQUIRED_ROLES

        broken = {k: v for k, v in MATERIAL.items() if k != "teal"}
        with self.assertRaises(PaletteError):
            material_roles(palette_with_material(broken), REQUIRED_ROLES)


class TestAerospace(unittest.TestCase):
    def test_borders_script_golden(self):
        from theme.components.aerospace import borders_script

        script = borders_script("#9ccbfb", "#44474e")
        self.assertIn("pkill -x borders", script)
        self.assertIn(
            "exec borders active_color=0xff9CCBFB inactive_color=0xff44474E width=2.0",
            script,
        )


class TestSuperfile(unittest.TestCase):
    CORE = {
        "background": "#0a0a0a",
        "background.subtle": "#131313",
        "background.selection": "#1c1c1c",
        "foreground.subtle": "#6f6f6f",
        "foreground": "#d0d0d0",
        "border.subtle": "#e0e0e0",
        "foreground.bright": "#f0f0f0",
        "status.error": "#e098ae",
        "accent.warm": "#b6b37f",
        "status.warning": "#b6b37f",
        "status.success": "#a9b694",
        "status.info": "#8ebbb1",
        "accent": "#afaccf",
        "accent.alt": "#baa8c9",
    }

    def palette(self) -> dict[str, Any]:
        return {
            "effective_mode": "dark",
            "variants": {
                "dark": {
                    "core": self.CORE,
                    "extensions": {
                        "terminal_gui": {
                            "base00": "#0a0a0a",
                            "base01": "#131313",
                            "base02": "#1c1c1c",
                            "base03": "#6f6f6f",
                            "base04": "#4a4a4a",
                            "base05": "#d0d0d0",
                            "base06": "#e0e0e0",
                            "base07": "#f0f0f0",
                            "base08": "#e098ae",
                            "base0B": "#a9b694",
                            "base0C": "#8ebbb1",
                            "base0D": "#afaccf",
                            "base0E": "#baa8c9",
                        }
                    },
                }
            },
        }

    def test_theme_toml_golden(self):
        from theme.components.superfile import spf_colors, theme_toml

        c = spf_colors(self.palette())
        toml = theme_toml(c)
        self.assertIn('full_screen_bg = "#0a0a0a"', toml)
        self.assertIn("[file_panel]", toml)
        self.assertIn('item_selected_bg = "#afaccf"', toml)
        self.assertIn('gradient_color = ["#afaccf", "#baa8c9"]', toml)
        self.assertNotIn("code_syntax_highlight", toml)

    def test_theme_ref_rewrite(self):
        from theme.components.superfile import update_theme_ref

        result = update_theme_ref('theme = "catppuccin-mocha"\n')
        self.assertIn('theme = "theming" # theme:managed', result)
        self.assertNotIn("catppuccin", result)
        appended = update_theme_ref("other = 1\n")
        self.assertIn('\ntheme = "theming" # theme:managed\n', appended)


class _Fake(Component):
    group = "test"

    def __init__(self, key: str, platform: str) -> None:
        self.key = key
        self.platform = platform

    def write_effects(self, ctx: Context) -> Effects:
        calls.append(self.key)
        return Effects()

    def status(self, ctx: Context) -> int:
        return 0

    def build(self, ctx: Context) -> dict[str, Any]:
        return {}


calls: list[str] = []


class TestPlatformGating(unittest.TestCase):
    def test_foreign_members_skipped(self):
        from theme.apply_phases import run_members

        calls.clear()
        members = [
            _Fake("native_a", ""),
            _Fake("foreign", "darwin" if sys.platform != "darwin" else "linux"),
            _Fake("native_b", sys.platform),
        ]
        with (
            mock.patch("theme.apply_phases._merge_surfaces"),
            mock.patch("theme.apply_phases._merge_managed"),
            mock.patch("theme.apply_phases._run_reloads"),
            mock.patch("theme.state.commit_members"),
        ):
            code = run_members(Context(config={}, palette={}), members)
        self.assertEqual(code, 0)
        self.assertEqual(calls, ["native_a", "native_b"])

    def test_macos_group_registry_shape(self):
        from theme.registry import REGISTRY

        self.assertIn("macos", REGISTRY)
        self.assertIn("sketchybar", REGISTRY)
        self.assertIn("aerospace", REGISTRY)
        self.assertEqual(REGISTRY["sketchybar"].platform, "darwin")


if __name__ == "__main__":
    unittest.main()


class TestRmpcTemplate(unittest.TestCase):
    def test_template_render_golden(self):
        from theme.components.rmpc import theme_ron

        palette = TestSuperfile().palette()
        ron = theme_ron(palette)
        self.assertIn('background_color: "black"', ron)
        self.assertIn('fg: "#afaccf"', ron)  # accent (current_item bg)
        self.assertIn('fg: "#baa8c9"', ron)  # accent_alt (brackets)
        self.assertIn('fg: "#8ebbb1"', ron)  # base0C header title
        self.assertIn('fg: "#6f6f6f"', ron)  # base03 borders
        self.assertNotIn("{", ron.replace("{{", ""), "unresolved tokens")


class TestCavaGradient(unittest.TestCase):
    def test_rewrite_idempotent_and_shaped(self):
        from theme.components.cava import update_gradient

        original = (
            "[color]\n"
            "gradient           = 1\n"
            "gradient_count     = 2\n"
            "gradient_color_1   = '#8f8f8f'\n"
            "gradient_color_2   = '#eaeaea'\n"
        )
        once = update_gradient(original, ["#808080", "#e0e0e0"])
        self.assertIn("gradient_color_1   = '#808080'", once)
        self.assertIn("gradient_color_2   = '#e0e0e0'", once)
        self.assertIn("gradient           = 1", once)
        twice = update_gradient(once, ["#808080", "#e0e0e0"])
        self.assertEqual(once, twice)

    def test_missing_stops_append(self):
        from theme.components.cava import update_gradient

        out = update_gradient("[color]\ngradient = 1\n", ["#111111", "#222222"])
        self.assertIn("gradient_color_1   = '#111111'", out)
        self.assertIn("gradient_color_2   = '#222222'", out)
