"""Golden tests for the writer contract: fixture → writer → byte-compare; hostile cases (missing/foreign keys, shared hex, unmanaged GTK_THEME) included."""

import unittest

from theme.helpers.writers import (
    managed_line_set,
    update_set_kv,
    update_eq_kv,
    update_marker_block,
    update_prefixed_lines,
    update_space_kv,
    write_report,
)

MARKER = "# theme:managed"


class TestUpdateSpaceKV(unittest.TestCase):
    def test_replaces_owned_preserves_foreign(self):
        text = 'Net/ThemeName "Old"\nXft/DPI 98304\nNet/IconThemeName "Icons"\n'
        result = update_space_kv(text, {"Net/ThemeName": "Colloid-Dark"})
        self.assertIn('Net/ThemeName "Colloid-Dark"', result)
        self.assertIn("Xft/DPI 98304", result)
        self.assertIn('Net/IconThemeName "Icons"', result)

    def test_appends_missing(self):
        text = "Xft/DPI 98304\n"
        result = update_space_kv(text, {"Net/ThemeName": "Colloid-Dark"})
        self.assertIn('Net/ThemeName "Colloid-Dark"', result)
        self.assertTrue(result.endswith("\n"))

    def test_int_bare(self):
        text = "Gdk/WindowScalingFactor 1\n"
        result = update_space_kv(text, {"Gdk/WindowScalingFactor": 2})
        self.assertIn("Gdk/WindowScalingFactor 2", result)

    def test_empty_file(self):
        result = update_space_kv("", {"Net/ThemeName": "X"})
        self.assertEqual(result, 'Net/ThemeName "X"\n')

    def test_no_trailing_newline(self):
        text = 'Net/ThemeName "Old"'
        result = update_space_kv(text, {"Net/ThemeName": "New"})
        self.assertIn('Net/ThemeName "New"', result)
        self.assertTrue(result.endswith("\n"))


class TestUpdateEqKV(unittest.TestCase):
    def test_replaces_in_section(self):
        text = "[Settings]\ngtk-theme-name=Old\ngtk-xft-antialias=1\n"
        result = update_eq_kv(text, {"gtk-theme-name": "New"}, section="Settings")
        self.assertIn("gtk-theme-name=New", result)
        self.assertIn("gtk-xft-antialias=1", result)

    def test_appends_into_section(self):
        text = "[Settings]\ngtk-theme-name=X\n\n[Other]\nfoo=bar\n"
        result = update_eq_kv(
            text, {"gtk-icon-theme-name": "Icons"}, section="Settings"
        )
        lines = result.splitlines()
        idx_settings = lines.index("[Settings]")
        idx_other = lines.index("[Other]")
        appended = [l for l in lines[idx_settings:idx_other] if "icon-theme" in l]
        self.assertEqual(len(appended), 1)

    def test_creates_missing_section(self):
        text = "[Other]\nfoo=bar\n"
        result = update_eq_kv(text, {"gtk-theme-name": "X"}, section="Settings")
        self.assertIn("[Settings]", result)
        self.assertIn("gtk-theme-name=X", result)

    def test_quoted_gtkrc(self):
        text = 'gtk-theme-name="Old"\ngtk-icon-theme-name="Icons"\n'
        result = update_eq_kv(text, {"gtk-theme-name": "New"}, quote=True)
        self.assertIn('gtk-theme-name="New"', result)
        self.assertIn('gtk-icon-theme-name="Icons"', result)

    def test_preserves_separator_spacing(self):
        text = "gtk-theme-name = Old\n"
        result = update_eq_kv(text, {"gtk-theme-name": "New"}, section=None)
        self.assertIn("gtk-theme-name = New", result)

    def test_foreign_keys_untouched(self):
        text = "[Settings]\ngtk-theme-name=X\ngtk-xft-hinting=1\ngtk-xft-rgba=rgb\n"
        result = update_eq_kv(text, {"gtk-theme-name": "Y"}, section="Settings")
        self.assertIn("gtk-xft-hinting=1", result)
        self.assertIn("gtk-xft-rgba=rgb", result)

    def test_shared_hex_trap_no_double_prefix(self):
        """Two keys sharing one value must not yield key=key=value."""
        text = "window.color=#2c2c2c\nbase.color=#2c2c2c\n"
        result = update_eq_kv(
            text, {"window.color": "#0f0f0f", "base.color": "#000000"}
        )
        self.assertIn("window.color=#0f0f0f", result)
        self.assertIn("base.color=#000000", result)
        self.assertNotIn("window.color=window.color", result)
        self.assertNotIn("base.color=base.color", result)


class TestManagedLineSet(unittest.TestCase):
    def test_active_write(self):
        text = "export OTHER=1\n"
        result, neutralized = managed_line_set(text, "GTK_THEME", "Colloid-Dark")
        self.assertIn(f"export GTK_THEME=Colloid-Dark {MARKER}", result)
        self.assertFalse(neutralized)

    def test_disabled_write(self):
        text = "export OTHER=1\n"
        result, _ = managed_line_set(text, "GTK_THEME", None)
        self.assertIn(f"# export GTK_THEME= {MARKER}", result)

    def test_neutralizes_unmanaged(self):
        text = "export GTK_THEME=bnw\n"
        result, neutralized = managed_line_set(text, "GTK_THEME", None)
        self.assertTrue(neutralized)
        self.assertIn("# export GTK_THEME=bnw", result)
        self.assertIn(f"# export GTK_THEME= {MARKER}", result)

    def test_managed_line_keeps_position(self):
        # regression: re-apply must not migrate the export to EOF
        text = "export A=1\n"
        text += f"export VIVID_THEME=~/.cache/theming/vivid/theme.yml {MARKER}\n"
        text += "export B=2\n"
        result, _ = managed_line_set(text, "VIVID_THEME", "~/.new/theme.yml")
        lines = [l for l in result.splitlines() if l.strip()]
        self.assertEqual(lines[1], f"export VIVID_THEME=~/.new/theme.yml {MARKER}")
        self.assertEqual(lines[0], "export A=1")
        self.assertEqual(lines[2], "export B=2")

    def test_replaces_existing_managed(self):
        text = f"export GTK_THEME=Old {MARKER}\n"
        result, neutralized = managed_line_set(text, "GTK_THEME", "New")
        self.assertIn(f"export GTK_THEME=New {MARKER}", result)
        self.assertNotIn("Old", result)
        self.assertFalse(neutralized)


class TestUpdatePrefixedLines(unittest.TestCase):
    def test_xresources(self):
        text = "*.color0: #000000\n*.color1: #ff0000\n"
        result = update_prefixed_lines(text, {"*.color0": "*.color0: #0f0f0f"})
        self.assertIn("*.color0: #0f0f0f", result)
        self.assertIn("*.color1: #ff0000", result)

    def test_hypr_border(self):
        text = "col.active_border = rgba(ffffffbb)\n"
        result = update_prefixed_lines(
            text, {"col.active_border": "col.active_border = rgba(ff9999ff)"}
        )
        self.assertIn("rgba(ff9999ff)", result)


class TestMarkerBlock(unittest.TestCase):
    BEGIN = "<!-- theming:begin -->"
    END = "<!-- theming:end -->"

    def test_replaces_existing(self):
        text = f"before\n{self.BEGIN}\nold\n{self.END}\nafter\n"
        result = update_marker_block(text, self.BEGIN, self.END, "new")
        self.assertIn("new", result)
        self.assertNotIn("old", result)
        self.assertIn("before", result)
        self.assertIn("after", result)

    def test_appends_when_absent(self):
        text = "existing content\n"
        result = update_marker_block(text, self.BEGIN, self.END, "new")
        self.assertIn(self.BEGIN, result)
        self.assertIn("new", result)
        self.assertIn(self.END, result)
        self.assertIn("existing content", result)


class TestWriteReport(unittest.TestCase):
    def test_eq_format(self):
        import tempfile
        from pathlib import Path

        with tempfile.NamedTemporaryFile(mode="w", suffix=".ini", delete=False) as f:
            f.write("gtk-theme-name=Colloid-Dark\ngtk-font-name=Inter 12\n")
            path = Path(f.name)
        result = write_report(path, {"gtk-theme-name": "X"})
        self.assertEqual(result["gtk-theme-name"], "Colloid-Dark")
        path.unlink()

    def test_space_format(self):
        import tempfile
        from pathlib import Path

        with tempfile.NamedTemporaryFile(mode="w", suffix=".conf", delete=False) as f:
            f.write('Net/ThemeName "Colloid-Dark"\nXft/DPI 98304\n')
            path = Path(f.name)
        result = write_report(path, {"Net/ThemeName": "X"})
        self.assertEqual(result["Net/ThemeName"], "Colloid-Dark")
        path.unlink()

    def test_missing_file(self):
        from pathlib import Path

        result = write_report(Path("/nonexistent"), {"key": "val"})
        self.assertEqual(result, {})


if __name__ == "__main__":
    unittest.main()


class TestUpdateSetKV(unittest.TestCase):
    def test_preserves_alignment(self):
        text = 'set default-fg                  "#f0f0f0"\nset pages-per-row 1\n'
        result, appended = update_set_kv(text, {"default-fg": '"#aabbcc"'})
        self.assertIn('set default-fg                  "#aabbcc"', result)
        self.assertIn("set pages-per-row 1", result)
        self.assertEqual(appended, [])

    def test_bare_boolean(self):
        text = "set recolor true\n"
        result, _ = update_set_kv(text, {"recolor": "false"})
        self.assertIn("set recolor false", result)

    def test_appends_missing_after_last_set(self):
        text = 'set font "Inter 10"\n\n# comment\n'
        result, appended = update_set_kv(text, {"default-bg": '"#000000"'})
        lines = [l for l in result.splitlines() if l.startswith("set")]
        self.assertEqual(lines[-1], 'set default-bg "#000000"')
        self.assertEqual(appended, ["default-bg"])

    def test_skips_commented_lines(self):
        text = 'set default-fg "#111111"\n# set default-fg "#333333"\n'
        result, appended = update_set_kv(text, {"default-fg": '"#222222"'})
        self.assertEqual(appended, [])
        self.assertIn('set default-fg "#222222"', result)
        self.assertIn('# set default-fg "#333333"', result)
        self.assertNotIn('"#111111"', result)


class TestAtuinTheme(unittest.TestCase):
    def test_renders_all_meanings(self):
        from theme.components.atuin import atuin_theme_toml, MEANING_SLOTS

        colors = {m: "#A1B2C3" for m in MEANING_SLOTS}
        result = atuin_theme_toml(colors)
        self.assertIn("[theme]", result)
        self.assertIn('name = "custom"', result)
        self.assertEqual(result.count(" = "), len(MEANING_SLOTS) + 1)
        self.assertIn('Base = "#a1b2c3"', result)

    def test_rejects_malformed_hex(self):
        from theme.components.atuin import atuin_theme_toml

        with self.assertRaises(RuntimeError):
            atuin_theme_toml({"Base": "a1b2c3"})

    def test_theme_ref_appends_section(self):
        from theme.components.atuin import update_theme_ref

        result = update_theme_ref('style = "full"\n')
        self.assertIn("[theme]", result)
        self.assertIn('name = "custom" # theme:managed', result)
        self.assertIn('style = "full"', result)

    def test_theme_ref_rewrites_existing(self):
        from theme.components.atuin import update_theme_ref

        text = '[theme]\nname = "old"\n'
        result = update_theme_ref(text)
        self.assertIn('name = "custom" # theme:managed', result)
        self.assertNotIn('"old"', result)

    def test_theme_ref_inserts_into_section_without_name(self):
        from theme.components.atuin import update_theme_ref

        text = "[theme]\ndebug = true\n"
        result = update_theme_ref(text)
        lines = result.splitlines()
        self.assertEqual(lines[1], 'name = "custom" # theme:managed')
        self.assertIn("debug = true", result)


class TestZathuraValues(unittest.TestCase):
    PALETTE = {
        "effective_mode": "dark",
        "variants": {
            "dark": {
                "core": {
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
                },
                "extensions": {
                    "terminal_gui": {"base04": "#2a2a2a", "base0F": "#b5aacc"}
                },
            }
        },
    }

    def test_dark_values(self):
        from theme.components.zathura import zathura_values

        values = zathura_values(
            self.PALETTE,
            {"fonts": {"sans": ["Inter Display"]}, "gui": {"font_size": 10}},
        )
        self.assertEqual(values["default-fg"], '"#e0e0e0"')
        self.assertEqual(values["default-bg"], '"#0a0a0a"')
        self.assertEqual(values["recolor"], "true")
        self.assertEqual(values["font"], '"Inter Display 10"')
        self.assertEqual(values["highlight-color"], '"#8ebbb1"')
        self.assertEqual(values["highlight-active-color"], '"#afaccf"')

    def test_light_recolor_off(self):
        from theme.components.zathura import zathura_values

        palette = dict(self.PALETTE, effective_mode="light")
        palette["variants"] = dict(palette["variants"])
        palette["variants"]["light"] = palette["variants"]["dark"]
        values = zathura_values(
            palette, {"fonts": {"sans": ["Inter Display"]}, "gui": {"font_size": 10}}
        )
        self.assertEqual(values["recolor"], "false")


class TestAtuinConformance(unittest.TestCase):
    def test_syntax_meanings_follow_upstream_base16(self):
        from theme.components.atuin import MEANING_SLOTS

        self.assertEqual(MEANING_SLOTS["SyntaxCommand"], "base0D")
        self.assertEqual(MEANING_SLOTS["SyntaxFlag"], "base0C")
        self.assertEqual(MEANING_SLOTS["SyntaxString"], "base0B")
        self.assertEqual(MEANING_SLOTS["SyntaxVariable"], "base08")
        self.assertEqual(MEANING_SLOTS["SyntaxComment"], "base03")


class TestFshTheme(unittest.TestCase):
    def test_render_grammar_and_sections(self):
        from theme.components.fsh import (
            SECTION_STYLES,
            _render_spec,
            fsh_styles,
            fsh_theme_ini,
        )

        palette = {
            "effective_mode": "dark",
            "variants": {
                "dark": {
                    "core": {
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
                    },
                    "extensions": {
                        "terminal_gui": {
                            "base04": "#2a2a2a",
                            "base0F": "#b5aacc",
                        }
                    },
                }
            },
        }
        styles = fsh_styles(palette)
        self.assertEqual(styles["command"], "#afaccf")
        self.assertEqual(styles["variable"], "#e098ae")
        self.assertEqual(styles["unknown-token"], "#e098ae,bold")
        self.assertEqual(styles["here-string-text"], "bg:#131313")
        self.assertEqual(styles["here-string-var"], "#e098ae,bg:#131313")
        self.assertEqual(styles["pathseparator"], "")
        self.assertEqual(styles["paired-bracket"], "bg:#6f6f6f")
        content = fsh_theme_ini(styles, "/home/x/.cache/theming/fsh/theme.ini")
        self.assertIn("[command-point]", content)
        self.assertIn("secondary = /home/x/.cache/theming/fsh/theme.ini", content)
        # every emitted value honors the no-space/bg: grammar
        for line in content.splitlines():
            if " = " in line and not line.lstrip().startswith((";", "[")):
                value = line.split(" = ", 1)[1]
                for token in value.split(","):
                    self.assertFalse(token.startswith(" "))
        self.assertEqual(sum(len(s) for s in SECTION_STYLES.values()), len(styles))

    def test_render_rejects_unknown_token(self):
        from theme.components.fsh import _render_spec

        with self.assertRaises(RuntimeError):
            _render_spec("sparkle", {"variants": {}})
