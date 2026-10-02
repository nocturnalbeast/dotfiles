"""Engine contract tests: cross-walk goldens, registry, suffix table, terminal completion, migration v1→v2."""

import sys
import unittest
from pathlib import Path

sys.path.insert(0, str(Path(__file__).parent.parent))

from theme.engines import ENGINES, ENGINE_SUFFIX
from theme.engines.base import (
    CORE_BASE24,
    base24_to_core,
    complete_terminal,
    material_to_core,
    ramp_mix,
)


class TestCrossWalk(unittest.TestCase):
    FIXTURE = {f"base{i:02X}": f"#0{i:0=5X}" for i in range(24)}

    def test_core_covers_all_14(self):
        self.assertEqual(len(CORE_BASE24), 14)
        core = base24_to_core(self.FIXTURE)
        self.assertEqual(len(core), 14)
        for token, slot in CORE_BASE24.items():
            self.assertEqual(core[token], self.FIXTURE[slot])

    def test_identity_anchors(self):
        cases = {
            "background": "base00",
            "accent": "base0D",
            "status.error": "base08",
            "foreground": "base05",
        }
        for token, slot in cases.items():
            self.assertEqual(CORE_BASE24[token], slot)

    def test_material_anchors(self):
        roles = {"surface": "#101010", "primary": "#9ccbfb", "error": "#ff0000"}
        core = material_to_core(roles)
        self.assertEqual(core["background"], "#101010")
        self.assertEqual(core["accent"], "#9ccbfb")
        self.assertEqual(core["status.error"], "#ff0000")
        self.assertNotIn("status.warning", core)  # derived, not anchored

    def test_ramp_mix_midpoint(self):
        self.assertEqual(ramp_mix("#000000", "#ffffff", 0.5), "#808080")
        self.assertEqual(ramp_mix("#000000", "#ffffff", 0.0), "#000000")


class TestTerminalCompletion(unittest.TestCase):
    def test_brights_derivation_marks(self):
        slots = {f"base{i:02X}": "#123456" for i in range(16)}
        complete, derived = complete_terminal(slots, "dark")
        self.assertEqual(len(complete), 24)
        self.assertEqual(len(derived), 8)  # base10-17 brights
        for i in range(8, 16):
            self.assertIn(f"base{i + 8:02X}", complete)

    def test_ramp_fill_when_missing(self):
        slots = {f"base{i:02X}": "#123456" for i in range(16)}
        del slots["base04"]
        del slots["base06"]
        complete, derived = complete_terminal(slots, "dark")
        self.assertIn("base04", derived)
        self.assertIn("base06", derived)
        self.assertTrue(derived["base04"].startswith("ramp-mix:"))


class TestRegistry(unittest.TestCase):
    def test_registry_names(self):
        self.assertEqual(
            set(ENGINES),
            {"matugen-faithful", "matugen-vibrant", "thaim", "wallust"},
        )

    def test_provides(self):
        self.assertEqual(
            ENGINES["matugen-faithful"].provides, ["core", "terminal", "material"]
        )
        self.assertEqual(ENGINES["thaim"].provides, ["core", "terminal"])

    def test_criticality(self):
        self.assertTrue(ENGINES["matugen-faithful"].critical)
        self.assertFalse(ENGINES["thaim"].critical)

    def test_suffix_table(self):
        self.assertEqual(ENGINE_SUFFIX["matugen-faithful"], "")
        self.assertEqual(ENGINE_SUFFIX["matugen-vibrant"], "-vibrant")
        self.assertEqual(ENGINE_SUFFIX["thaim"], "-thaim")
        self.assertEqual(ENGINE_SUFFIX["wallust"], "-wallust")
        self.assertEqual(
            len(set(ENGINE_SUFFIX.values())), len(ENGINE_SUFFIX)
        )  # unique families


class TestMigration(unittest.TestCase):
    def test_v1_to_v2(self):
        import tempfile

        from theme.migrate import migrate, needs_migration
        from ruamel.yaml import YAML

        yaml = YAML()
        yaml.preserve_quotes = True
        with tempfile.NamedTemporaryFile("w", suffix=".yaml", delete=False) as fh:
            fh.write(
                "tui:\n"
                "  scheme: follow\n"
                "  flavor: thaim\n"
                "  mode: auto\n"
                "palette:\n"
                "  mode: auto\n"
                "  variants:\n"
                "    dark:\n"
                "      base16: {base00: '#111111', base05: '#eeeeee', base0D: '#9ccbfb'}\n"
                "      colors: {primary: '#9ccbfb'}\n"
            )
            path = Path(fh.name)

        self.assertTrue(needs_migration(path))
        self.assertTrue(migrate(path))

        with path.open() as fh:
            data = yaml.load(fh)

        self.assertNotIn("flavor", data["tui"])
        self.assertEqual(data["engines"]["tui"], "thaim")
        self.assertEqual(data["engines"]["gui"], "matugen-faithful")

        variant = data["palette"]["variants"]["dark"]
        self.assertNotIn("base16", variant)
        self.assertNotIn("colors", variant)
        self.assertEqual(variant["core"]["background"], "#111111")
        self.assertEqual(variant["core"]["foreground"], "#eeeeee")
        self.assertEqual(variant["core"]["accent"], "#9ccbfb")
        self.assertEqual(variant["extensions"]["terminal"]["base00"], "#111111")
        self.assertEqual(variant["extensions"]["terminal_gui"]["base00"], "#111111")
        self.assertEqual(variant["extensions"]["material"]["primary"], "#9ccbfb")
        self.assertEqual(
            data["palette"]["engines"],
            {"gui": "matugen-faithful", "tui": "matugen-faithful"},
        )

        # idempotent
        self.assertFalse(needs_migration(path))
        self.assertFalse(migrate(path))
        path.unlink()


if __name__ == "__main__":
    unittest.main()


class TestWallustMapping(unittest.TestCase):
    KEYS = {
        "background": "#1C1C1E",
        "foreground": "#E1E4F1",
        "cursor": "#E1E4F1",
        **{f"color{i}": f"#1{i:02d}2{i:02d}3" for i in range(16)},
    }

    def test_slot_map_covers_native(self):
        from theme.engines.wallust import WALLUST_SLOT_MAP

        self.assertEqual(len(WALLUST_SLOT_MAP), 16)
        covered = set(WALLUST_SLOT_MAP.values())
        self.assertIn("base00", covered)
        self.assertIn("base0F", covered)
        # all native slots distinct
        self.assertEqual(len(covered), 16)

    def test_wallust_slots_mapping_and_marks(self):
        from theme.engines.wallust import wallust_slots

        keys = {
            "background": "#121212",
            "foreground": "#EEEEEE",
            "cursor": "#EEEEEE",
            "color0": "#1A1A1A",
            "color1": "#FF5F5F",
            "color2": "#5FFF5F",
            "color3": "#FFFF5F",
            "color4": "#5F7FFF",
            "color5": "#FF5FFF",
            "color6": "#5FFFFF",
            "color7": "#E0E0E0",
            "color8": "#424245",
            "color9": "#FF7F7F",
            "color10": "#7FFF7F",
            "color11": "#FFFF7F",
            "color12": "#7F9FFF",
            "color13": "#FF7FFF",
            "color14": "#7FFFFF",
            "color15": "#FFFFFF",
        }
        slots, marks = wallust_slots(keys, "dark")
        self.assertEqual(slots["base00"], "#121212")
        self.assertEqual(slots["base01"], "#424245")
        self.assertEqual(slots["base05"], "#EEEEEE")
        self.assertEqual(slots["base08"], keys["color1"].upper())
        self.assertEqual(slots["base0F"], keys["color9"].upper())
        self.assertEqual(marks["base09"], "hue-shift:+30")

    def test_wallust_aa_shift_marks_low_contrast(self):
        from theme.engines.wallust import wallust_slots

        gray_keys = {
            "background": "#D9D9D9",
            "foreground": "#212121",
            "cursor": "#212121",
            **{f"color{i}": "#ADADAD" for i in range(16)},
        }
        slots, marks = wallust_slots(gray_keys, "light")
        shifted = [s for s, rule in marks.items() if rule == "aa-shift"]
        self.assertTrue(shifted, "gray-on-gray accents must be aa-shift marked")
        for slot in shifted:
            from tests.analyze_contrast import contrast_ratio

            self.assertGreaterEqual(contrast_ratio(slots[slot], slots["base00"]), 4.5)

    def test_hue_shift_moves_red_to_orange(self):
        from theme.engines.wallust import _hue_shift

        shifted = _hue_shift("#FF0000", 30)
        r = int(shifted[1:3], 16)
        g = int(shifted[3:5], 16)
        self.assertGreater(g, 0)  # green channel appears → orange
        self.assertGreater(r, g)  # still red-dominant

    def test_hex_validation_rejects_empty(self):
        from theme.engines.wallust import _HEX_RE

        self.assertIsNone(_HEX_RE.match(""))
        self.assertIsNone(_HEX_RE.match("#GGHHII"))
        self.assertIsNotNone(_HEX_RE.match("#1C1C1E"))


@unittest.skipUnless(__import__("shutil").which("wallust"), "wallust not installed")
class TestWallustLive(unittest.TestCase):
    # pinned fixture: current_wallpaper symlink is mutable machine state
    # (some wallpapers legitimately yield "Not enough colors" from wallust)
    WALLPAPER = next(
        iter(
            sorted(
                (Path.home() / ".dotfiles/wallpapers/.local/share/wallpapers").rglob(
                    "w_two.*"
                )
            )
        ),
        None,
    )

    def test_extract_both_modes(self):
        from theme.engines.wallust import WallustEngine

        if not self.WALLPAPER or not self.WALLPAPER.exists():
            self.skipTest("wallpaper fixture not found")
        image = str(self.WALLPAPER.resolve())
        out = WallustEngine().extract(image)
        for m in ("dark", "light"):
            terminal = out["variants"][m]["extensions"]["terminal"]
            core = out["variants"][m]["core"]
            self.assertEqual(len(terminal), 24)
            self.assertEqual(len(core), 14)
            bg = terminal["base00"]
            fg = terminal["base05"]
            dark_bg = int(bg[1:3], 16) + int(bg[3:5], 16) + int(bg[5:7], 16)
            if m == "dark":
                self.assertLess(dark_bg, 384)
            else:
                self.assertGreater(dark_bg, 384)
        self.assertIn("ramp-mix", str(out["variants"]["dark"]["derived"]))
