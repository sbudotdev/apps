"""Tests for Tools/make_icons.py, the cell icons (ADR-0027). Run: python3 -m unittest Tools/test_make_icons.py"""
import json
import sys
import tempfile
import unittest
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
import make_icons as m  # noqa: E402

BLANK = ["." * 12] * 12


def drawing(*cells: tuple[int, int]) -> list[str]:
    rows = [list(row) for row in BLANK]
    for x, y in cells:
        rows[y][x] = "#"
    return ["".join(row) for row in rows]


def centre(x: int, y: int, side: int = m.CANVAS) -> tuple[int, int]:
    cell = side / m.GRID
    return int((x + 0.5) * cell), int((y + 0.5) * cell)


class ParseTests(unittest.TestCase):
    def test_reads_ink_cells_as_column_row(self):
        self.assertEqual(m.parse(drawing((1, 1), (9, 8), (8, 10))), {(1, 1), (9, 8), (8, 10)})

    def test_rejects_ink_touching_the_full_stop(self):
        for cell in [(9, 9), (9, 10)]:
            with self.subTest(cell=cell), self.assertRaises(ValueError):
                m.parse(drawing(cell))

    def test_rejects_ink_outside_columns_1_to_9_and_rows_1_to_10(self):
        for cell in [(0, 5), (10, 5), (11, 5), (5, 0), (5, 11), (10, 10)]:
            with self.subTest(cell=cell), self.assertRaises(ValueError):
                m.parse(drawing(cell))

    def test_rejects_more_than_40_cells(self):
        many = [(x, y) for y in range(1, 6) for x in range(1, 10)]  # 45
        with self.assertRaises(ValueError):
            m.parse(drawing(*many))

    def test_rejects_a_grid_that_is_not_12_by_12_or_uses_other_marks(self):
        for rows in [BLANK[:11], [r[:11] for r in BLANK], drawing((2, 2))[:1] + ["..x........."] + BLANK[2:], BLANK]:
            with self.subTest(rows=rows), self.assertRaises(ValueError):
                m.parse(rows)


class DrawingsTests(unittest.TestCase):
    """The 32 drawings in Design/icons/cells.json."""

    @classmethod
    def setUpClass(cls):
        cls.cells = json.loads(m.CELLS.read_text())
        cls.specs = json.loads(m.SPECS.read_text())

    def test_every_app_has_a_drawing_and_every_drawing_an_app(self):
        self.assertEqual(set(self.cells), set(self.specs))

    def test_every_drawing_follows_the_rules_and_has_a_name(self):
        for name, entry in self.cells.items():
            with self.subTest(name=name):
                m.parse(entry["cells"])
                self.assertTrue(entry["name"]["it"] and entry["name"]["en"])

    def test_no_two_apps_share_a_drawing(self):
        seen = {}
        for name, entry in self.cells.items():
            key = frozenset(m.parse(entry["cells"]))
            self.assertNotIn(key, seen, f"{name} draws the same cells as {seen.get(key)}")
            seen[key] = name

    def test_clean_and_tidy_have_different_subjects(self):
        self.assertNotEqual(self.cells["clean"]["name"]["en"], self.cells["tidy"]["name"]["en"])


class RenderTests(unittest.TestCase):
    def setUp(self):
        self.palette = m.colors()
        self.cells = m.parse(drawing((1, 1), (5, 5)))
        self.icons = m.variants(self.cells, self.palette, "accent-habits")

    def pixel(self, variant: str, x: int, y: int) -> tuple[int, int, int]:
        return self.icons[variant].getpixel(centre(x, y))

    def test_light_is_ink_cells_on_paper_with_the_stop_in_the_accent(self):
        icon = self.icons["light"]
        self.assertEqual((icon.size, icon.mode), ((1024, 1024), "RGB"))
        self.assertEqual(self.pixel("light", 5, 5), m.rgb(self.palette["ink"]["light"]))
        self.assertEqual(self.pixel("light", 3, 3), m.rgb(self.palette["paper"]["light"]))
        self.assertEqual(self.pixel("light", 10, 10), m.rgb(self.palette["accent-habits"]["light"]))

    def test_light_draws_the_grid_between_cells(self):
        between_columns_3_and_4 = round(4 * m.CANVAS / m.GRID)
        self.assertEqual(self.icons["light"].getpixel((between_columns_3_and_4, centre(3, 3)[1])), m.rgb(self.palette["grid"]["light"]))

    def test_dark_is_light_cells_on_warm_black_with_the_dark_accent(self):
        self.assertEqual(self.pixel("dark", 5, 5), m.rgb(self.palette["ink"]["dark"]))
        self.assertEqual(self.pixel("dark", 3, 3), m.rgb(self.palette["ink"]["light"]))
        self.assertEqual(self.pixel("dark", 10, 10), m.rgb(self.palette["accent-habits"]["dark"]))

    def test_tinted_is_greys_with_the_stop_apart_from_the_drawing(self):
        r, g, b = self.pixel("tinted", 10, 10)
        self.assertEqual(r, g)
        self.assertEqual(g, b)
        self.assertNotEqual(self.pixel("tinted", 10, 10), self.pixel("tinted", 5, 5))
        self.assertEqual(self.pixel("tinted", 3, 3)[0], 0)

    def test_inversa_is_paper_cells_on_ink_with_the_accent_on_ink(self):
        self.assertEqual(self.pixel("inversa", 5, 5), m.rgb(self.palette["paper"]["light"]))
        self.assertEqual(self.pixel("inversa", 3, 3), m.rgb(self.palette["ink"]["light"]))
        self.assertEqual(self.pixel("inversa", 10, 10), m.rgb(self.palette["accent-on-ink-habits"]["light"]))

    def test_watch_icon_is_the_light_icon_inside_the_circle(self):
        icon = self.icons["watch"]
        inner = int(m.CANVAS * m.WATCH_SAFE)
        offset = (m.CANVAS - inner) // 2
        cell = inner / m.GRID
        stop = (int(offset + 10.5 * cell), int(offset + 10.5 * cell))
        self.assertEqual(icon.getpixel(stop), m.rgb(self.palette["accent-habits"]["light"]))
        radius = ((stop[0] - m.CANVAS / 2) ** 2 + (stop[1] - m.CANVAS / 2) ** 2) ** 0.5
        self.assertLess(radius + cell / 2, m.CANVAS / 2, "the full stop must stay inside the watch circle")


class WriteTests(unittest.TestCase):
    def test_writes_every_asset_catalog(self):
        icons = m.variants(m.parse(drawing((2, 2))), m.colors(), "accent-habits")
        with tempfile.TemporaryDirectory() as tmp:
            out = Path(tmp)
            m.write_appiconset({k: icons[k] for k in ("light", "dark", "tinted")}, out / "AppIcon.appiconset")
            m.write_appiconset({"light": icons["inversa"]}, out / "AppIcon-Inversa.appiconset")
            m.write_artwork(icons, out / "AppIconArtwork.imageset")
            m.write_mac_appiconset(icons["light"], out / "Mac.appiconset")
            m.write_watch_appiconset(icons["watch"], out / "Watch.appiconset")
            self.assertEqual(len(json.loads((out / "AppIcon.appiconset/Contents.json").read_text())["images"]), 3)
            self.assertEqual(len(list((out / "Mac.appiconset").glob("*.png"))), 10)
            self.assertTrue((out / "Watch.appiconset/AppIcon-watch.png").exists())
            self.assertEqual(len(list((out / "AppIconArtwork.imageset").glob("*.png"))), 2)


if __name__ == "__main__":
    unittest.main()
