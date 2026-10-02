"""Override grammar + config validation tests."""

import unittest
from pathlib import Path

from theme.config import ConfigError, parse_override, resolve


class TestParseOverride(unittest.TestCase):
    def test_colon_separator(self):
        path, value = parse_override("gui.theme:materia")
        self.assertEqual(path, ("gui", "theme"))
        self.assertEqual(value, "materia")

    def test_equals_separator(self):
        path, value = parse_override("gui.theme=materia")
        self.assertEqual(path, ("gui", "theme"))
        self.assertEqual(value, "materia")

    def test_first_separator_wins(self):
        path, value = parse_override("gui.tweaks:black,rimless")
        self.assertEqual(path, ("gui", "tweaks"))
        self.assertEqual(value, ["black", "rimless"])

    def test_value_containing_colon(self):
        path, value = parse_override("tui.scheme:base24-one-black:extra")
        self.assertEqual(path, ("tui", "scheme"))
        self.assertEqual(value, "base24-one-black:extra")

    def test_int_coercion(self):
        path, value = parse_override("gui.font_size:14")
        self.assertEqual(value, 14)

    def test_bool_coercion(self):
        _, value = parse_override("gui.env_override:true")
        self.assertIs(value, True)
        _, value = parse_override("gui.env_override:false")
        self.assertIs(value, False)

    def test_empty_value_error(self):
        with self.assertRaises(ConfigError):
            parse_override("gui.theme:")

    def test_malformed_error(self):
        with self.assertRaises(ConfigError):
            parse_override("no-separator")

    def test_missing_section_error(self):
        with self.assertRaises(ConfigError):
            parse_override("justakey:value")

    def test_comma_in_scalar_error(self):
        with self.assertRaises(ConfigError):
            parse_override("gui.theme:col,lloid")


class TestResolveWithOverrides(unittest.TestCase):
    CONFIG = None  # resolved per-environment in setUpClass

    @classmethod
    def setUpClass(cls):
        from theme.config import DEFAULT_CONFIG

        cls.CONFIG = DEFAULT_CONFIG

    def test_defaults_load(self):
        config = resolve(self.CONFIG)
        self.assertEqual(config["gui"]["theme"], "colloid")
        self.assertEqual(config["gui"]["tweaks"], ["black", "rimless"])

    def test_override_applies(self):
        config = resolve(self.CONFIG, ["gui.theme:materia"])
        self.assertEqual(config["gui"]["theme"], "materia")

    def test_override_list_replaces(self):
        config = resolve(self.CONFIG, ["gui.tweaks:primary"])
        self.assertEqual(config["gui"]["tweaks"], ["primary"])

    def test_duplicate_override_errors(self):
        with self.assertRaises(ConfigError):
            resolve(self.CONFIG, ["gui.theme:materia", "gui.theme:orchis"])

    def test_unknown_path_errors(self):
        with self.assertRaises(ConfigError):
            resolve(self.CONFIG, ["gui.nonexistent:x"])

    def test_unknown_enum_errors(self):
        with self.assertRaises(ConfigError):
            resolve(self.CONFIG, ["gui.theme:nonexistent_theme"])

    def test_palette_mode_validated(self):
        with self.assertRaises(ConfigError):
            resolve(self.CONFIG, ["palette.mode:purple"])

    def test_palette_accent_resolves(self):
        config = resolve(self.CONFIG)
        from theme.palette import active_variant, resolve_accent

        variant = active_variant(config["palette"])
        expected = (variant.get("core") or {}).get("accent") or (
            (variant.get("extensions") or {}).get("material") or {}
        ).get("primary")
        self.assertEqual(resolve_accent(config["palette"]), expected)
        self.assertIn("background", variant["core"])
        self.assertIn("base00", variant["extensions"]["terminal_gui"])


class TestConfigEdgeCases(unittest.TestCase):
    def test_nonexistent_file_uses_defaults(self):
        config = resolve(Path("/nonexistent/config.yaml"))
        self.assertEqual(config["gui"]["theme"], "colloid")

    def test_override_on_nonexistent_file(self):
        config = resolve(Path("/nonexistent/config.yaml"), ["gui.theme:orchis"])
        self.assertEqual(config["gui"]["theme"], "orchis")


if __name__ == "__main__":
    unittest.main()
