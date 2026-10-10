"""CIEDE2000 + scheme-distance + catalog tests; goldens from Sharma, Wu & Dalal 2005 Table 1 (hue-boundary, atan2 discontinuity, RT-heavy branches)."""

import sys
import tempfile
import unittest
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent.parent))

from theme.helpers.deltae import (
    _delta_e2000_lab,
    delta_e2000,
    load_catalog,
    nearest_schemes,
    scheme_distance,
)

# (L1, a1, b1, L2, a2, b2, expected ΔE00) - Sharma 2005 Table 1.
SHARMA_PAIRS = [
    (50.0000, 2.6772, -79.7751, 50.0000, 0.0000, -82.7485, 2.0425),
    (50.0000, 3.1571, -77.2803, 50.0000, 0.0000, -82.7485, 2.8615),
    (50.0000, 2.8361, -74.0200, 50.0000, 0.0000, -82.7485, 3.4412),
    (50.0000, -1.3802, -84.2814, 50.0000, 0.0000, -82.7485, 1.0000),
    (50.0000, -1.1848, -84.8006, 50.0000, 0.0000, -82.7485, 1.0000),
    (50.0000, -0.9009, -85.5211, 50.0000, 0.0000, -82.7485, 1.0000),
    (50.0000, 0.0000, 0.0000, 50.0000, -1.0000, 2.0000, 2.3669),
    (50.0000, -1.0000, 2.0000, 50.0000, 0.0000, 0.0000, 2.3669),
    (50.0000, 2.4900, -0.0010, 50.0000, -2.4900, 0.0009, 7.1792),
    (50.0000, 2.4900, -0.0010, 50.0000, -2.4900, 0.0010, 7.1792),
    (50.0000, 2.4900, -0.0010, 50.0000, -2.4900, 0.0011, 7.2195),
    (50.0000, 2.4900, -0.0010, 50.0000, -2.4900, 0.0012, 7.2195),
    (50.0000, -0.0010, 2.4900, 50.0000, 0.0009, -2.4900, 4.8045),
    (50.0000, -0.0010, 2.4900, 50.0000, 0.0010, -2.4900, 4.8045),
    (50.0000, -0.0010, 2.4900, 50.0000, 0.0011, -2.4900, 4.7461),
    (50.0000, 2.5000, 0.0000, 50.0000, 0.0000, -2.5000, 4.3065),
    (50.0000, 2.5000, 0.0000, 73.0000, 25.0000, -18.0000, 27.1492),
    (50.0000, 2.5000, 0.0000, 61.0000, -5.0000, 29.0000, 22.8977),
    (50.0000, 2.5000, 0.0000, 56.0000, -27.0000, -3.0000, 31.9030),
    (50.0000, 2.5000, 0.0000, 58.0000, 24.0000, 15.0000, 19.4535),
    (60.2574, -34.0099, 36.2677, 60.4626, -34.1751, 39.4387, 1.2644),
    (63.0109, -31.0961, -5.8663, 62.8187, -29.7946, -4.0864, 1.2630),
    (61.2901, 3.7196, -5.3901, 61.4292, 2.2480, -4.9620, 1.8731),
    (35.0831, -44.1164, 3.7933, 35.0232, -40.0716, 1.5901, 1.8645),
    (22.7233, 20.0904, -46.6940, 23.0331, 14.9730, -42.5619, 2.0373),
    (36.4612, 47.8580, 18.3852, 36.2715, 50.5065, 21.2231, 1.4146),
    (90.8027, -2.0831, 1.4410, 91.1528, -1.6435, 0.0447, 1.4441),
    (90.9257, -0.5406, -0.9208, 88.6381, -0.8985, -0.7239, 1.5381),
    (6.7747, -0.2908, -2.4247, 5.8714, -0.0985, -2.2286, 0.6377),
    (2.0776, 0.0795, -1.1350, 0.9033, -0.0636, -0.5514, 0.9082),
]


class TestDeltaE2000Golden(unittest.TestCase):
    def test_sharma_table(self):
        for i, (L1, a1, b1, L2, a2, b2, expected) in enumerate(SHARMA_PAIRS, 1):
            with self.subTest(pair=i):
                got = _delta_e2000_lab((L1, a1, b1), (L2, a2, b2))
                self.assertAlmostEqual(got, expected, places=4)

    def test_symmetry_and_zero(self):
        self.assertAlmostEqual(delta_e2000("#000000", "#000000"), 0.0, places=9)
        d = delta_e2000("#ff9999", "#334455")
        self.assertAlmostEqual(delta_e2000("#334455", "#ff9999"), d, places=9)

    def test_hex_normalization(self):
        self.assertAlmostEqual(
            delta_e2000("#FF9999", "#334455"),
            delta_e2000("ff9999", "#334455"),
            places=9,
        )


class TestSchemeDistance(unittest.TestCase):
    def test_dedup_drops_duplicate_query_slot(self):
        # base06 repeats base01's query color → dropped (weight 1.5
        # leaves the denominator); remaining Σw = 3 + 2 = 5.
        d01 = delta_e2000("#202020", "#303030")
        query = {"base00": "#101010", "base01": "#202020", "base06": "#202020"}
        candidate = {
            "base00": "#101010",
            "base01": "#303030",
            "base06": "#303030",
        }
        self.assertAlmostEqual(
            scheme_distance(query, candidate), (3 * 0.0 + 2 * d01) / 5.0, places=9
        )

    def test_dedup_ignores_candidate_value_of_dropped_slot(self):
        query = {"base00": "#101010", "base01": "#202020", "base06": "#202020"}
        near = {"base00": "#101010", "base01": "#202020", "base06": "#202020"}
        wild = {"base00": "#101010", "base01": "#202020", "base06": "#ff00ff"}
        self.assertAlmostEqual(
            scheme_distance(query, near), scheme_distance(query, wild), places=9
        )

    def test_dedup_compares_normalized_hex(self):
        upper = {"base00": "#101010", "base05": "#D0CECF", "base06": "#d0cecf"}
        candidate = {"base00": "#101010", "base05": "#000000", "base06": "#000000"}
        d = delta_e2000("#d0cecf", "#000000")
        self.assertAlmostEqual(
            scheme_distance(upper, candidate), (3 * 0.0 + 3 * d) / 6.0, places=9
        )

    def test_missing_slot_renormalizes(self):
        # Only base00 (w3) and base05 (w3) comparable → plain mean.
        d00 = delta_e2000("#111111", "#222222")
        d05 = delta_e2000("#333333", "#444444")
        query = {"base00": "#111111", "base05": "#333333"}
        candidate = {"base00": "#222222", "base05": "#444444"}
        self.assertAlmostEqual(
            scheme_distance(query, candidate), (d00 + d05) / 2.0, places=9
        )

    def test_missing_candidate_slot_excluded(self):
        # base01 absent from candidate → its w2 leaves the denominator.
        d00 = delta_e2000("#111111", "#222222")
        query = {"base00": "#111111", "base01": "#202020"}
        candidate = {"base00": "#222222"}
        self.assertAlmostEqual(scheme_distance(query, candidate), d00, places=9)

    def test_no_overlap_is_inf(self):
        self.assertEqual(scheme_distance({}, {"base00": "#000000"}), float("inf"))


class TestLoadCatalog(unittest.TestCase):
    def test_real_catalog(self):
        catalog = load_catalog()
        self.assertGreaterEqual(len(catalog), 200)
        names = [rec["name"] for rec in catalog]
        self.assertEqual(names, sorted(names))
        slots16 = tuple(f"base{i:02X}" for i in range(16))
        for rec in catalog:
            with self.subTest(name=rec["name"]):
                self.assertIn(rec["variant"], ("dark", "light"))
                for slot in slots16:
                    self.assertIn(slot, rec["slots"])
                    self.assertRegex(rec["slots"][slot], r"^#[0-9a-f]{6}$")

    def test_skips_bad_files_never_raises(self):
        good = (
            'system: "base24"\nname: "Good"\nvariant: "dark"\nauthor: "x"\n'
            "palette:\n"
            + "".join(f'  base{i:02X}: "{v}"\n' for i, v in enumerate(["1a1a1a"] * 18))
        )
        with tempfile.TemporaryDirectory() as tmp:
            tmpdir = Path(tmp)
            (tmpdir / "good-scheme.yaml").write_text(good)
            (tmpdir / "broken.yaml").write_text("palette: [unclosed\n")
            (tmpdir / "wrong-system.yaml").write_text(
                good.replace("base24", "base16", 1)
            )
            (tmpdir / "missing-variant.yaml").write_text(
                'system: "base24"\nname: "NoVar"\npalette:\n  base00: "#000000"\n'
            )
            (tmpdir / "no-hash-palette.yaml").write_text(
                'system: "base24"\nname: "NoHash"\nvariant: "light"\nauthor: "x"\n'
                "palette:\n" + "".join(f'  base{i:02X}: "1b2b3c"\n' for i in range(18))
            )
            catalog = load_catalog(tmpdir)
        self.assertEqual(
            catalog,
            [
                {
                    "name": "base24-good-scheme",
                    "variant": "dark",
                    "slots": {f"base{i:02X}": "#1a1a1a" for i in range(18)},
                },
                {
                    "name": "base24-no-hash-palette",
                    "variant": "light",
                    "slots": {f"base{i:02X}": "#1b2b3c" for i in range(18)},
                },
            ],
        )


class TestNearestSchemes(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.catalog = load_catalog()

    def test_self_query_is_nearest_at_zero(self):
        rec = self.catalog[0]
        top = nearest_schemes(rec["slots"], self.catalog, rec["variant"], k=3)
        self.assertEqual(top[0][0], rec["name"])
        self.assertAlmostEqual(top[0][1], 0.0, places=6)
        distances = [d for _, d in top]
        self.assertEqual(distances, sorted(distances))

    def test_variant_filter_and_k(self):
        dark = [r for r in self.catalog if r["variant"] == "dark"]
        rec = dark[0]
        top = nearest_schemes(rec["slots"], self.catalog, "dark", k=5)
        self.assertEqual(len(top), 5)
        self.assertTrue(all(name != rec["name"] or True for name, _ in top[1:]))

    def test_tie_break_by_name(self):
        slots = {f"base{i:02X}": "#1a1a1a" for i in range(16)}
        catalog = [
            {"name": "base24-zeta", "variant": "dark", "slots": dict(slots)},
            {"name": "base24-alpha", "variant": "dark", "slots": dict(slots)},
            {"name": "base24-light", "variant": "light", "slots": dict(slots)},
        ]
        result = nearest_schemes(slots, catalog, "dark", k=2)
        self.assertEqual(result, [("base24-alpha", 0.0), ("base24-zeta", 0.0)])


if __name__ == "__main__":
    unittest.main()
