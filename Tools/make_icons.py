#!/usr/bin/env python3
"""Generate a Sbu app icon: the instrument drawn in cells on the notebook page, closed by the full stop.

Grammar (ADR-0027, Design/README.md, CLAUDE.md): a fixed 12x12 grid; the instrument is whole cells
in `ink`, inside columns 1-9 and rows 1-10, never touching the stop, at most 40 cells; the full stop is the one coloured
cell, always cell (10, 10) (column, row from the top left, counting from 0), in the app's accent.
Light: ink cells on `paper` with the `grid` lines. Dark: light cells on warm black, the stop in the
accent's dark value. Tinted: white cells on black and a grey stop, for iOS to tint. Inversa, the
one alternate icon: paper cells on ink, the stop in `accent-on-ink-*`. Mac: the light icon in the
Big Sur rounded square. Watch: the light icon shrunk into the circle's safe square, the grid running
on to the edge (a dark Watch icon was rejected, SBU-409).

Drawings live in Design/icons/cells.json ({name: {name: {it, en}, cells: [12 rows of 12 "." or "#"]}});
accents come from Design/icons/engravings.json. The engravings themselves (Tools/engrave.py) stay as
plates on sbu.dev, not icons.

Usage:
  python3 Tools/make_icons.py level [--appiconset Apps/SbuLevel/SbuLevel/Assets.xcassets/AppIcon.appiconset]
      [--artwork Apps/SbuLevel/SbuLevel/Assets.xcassets/AppIconArtwork.imageset]
      [--inverse Apps/SbuLevel/SbuLevel/Assets.xcassets/AppIcon-Inversa.appiconset]
  python3 Tools/make_icons.py habits --watch-appiconset Apps/SbuHabits/SbuHabitsWatch/Assets.xcassets/AppIcon.appiconset
  python3 Tools/make_icons.py seasons --mac-appiconset Apps/SbuSeasons/SbuSeasons/Assets.xcassets/AppIcon.appiconset
  python3 Tools/make_icons.py all                      # Design/icons/sbu-<name>.png for every drawing
  python3 Tools/make_icons.py all --sheet sheet.png    # proof: every icon light/dark/tinted at 60, 40, 29 pt

Writes Design/icons/sbu-<name>.png (light, 1024, no alpha); the variants go only where you ask.
"""
import argparse
import json
import sys
from pathlib import Path

from PIL import Image, ImageDraw, ImageFilter, ImageOps, ImageStat

ROOT = Path(__file__).resolve().parent.parent
TOKENS = ROOT / "Design" / "tokens.json"
ICONS = ROOT / "Design" / "icons"
CELLS = ICONS / "cells.json"
SPECS = ICONS / "engravings.json"
CANVAS = 1024
GRID = 12  # cells per side
STOP = (10, 10)  # the full stop's cell: column, row
COLUMNS, ROWS = range(1, 10), range(1, 11)  # where the drawing may put ink
MAX_CELLS = 40  # more and it stops reading at 29 pt
CLEAR = {(9, 9), (9, 10)}  # the stop's neighbours inside the drawing area: ink there joins the stop to the drawing
GRID_LINE = 4  # grid line width at 1024 px
TINTED_STOP = "#9a9a92"  # ink-muted dark: a grey apart from the white drawing
MAC_SHAPE = 824  # macOS: side of the rounded square inside the 1024 canvas (Apple's icon grid)
WATCH_SAFE = 0.70  # watchOS: side of the drawn page, as a fraction of the canvas (inscribed square is 0.707)


def rgb(hex_value: str) -> tuple[int, int, int]:
    h = hex_value.lstrip("#")
    return tuple(int(h[i : i + 2], 16) for i in (0, 2, 4))


def colors() -> dict:
    return {t["name"]: t["value"] for t in json.loads(TOKENS.read_text())["color"]["tokens"]}


def parse(rows: list[str]) -> set[tuple[int, int]]:
    """12 rows of 12 '.' or '#' -> the ink cells as (column, row); ValueError if a rule is broken."""
    if len(rows) != GRID or any(len(row) != GRID for row in rows):
        raise ValueError(f"the drawing must be {GRID} rows of {GRID} cells")
    if any(set(row) - {".", "#"} for row in rows):
        raise ValueError("cells are '.' (paper) or '#' (ink)")
    cells = {(x, y) for y, row in enumerate(rows) for x, c in enumerate(row) if c == "#"}
    if not cells:
        raise ValueError("the drawing is empty")
    outside = sorted((x, y) for x, y in cells if x not in COLUMNS or y not in ROWS)
    if outside:
        raise ValueError(f"ink outside columns 1-9 and rows 1-10: {outside}")
    touching = sorted(cells & CLEAR)
    if touching:
        raise ValueError(f"ink touching the full stop: {touching}")
    if len(cells) > MAX_CELLS:
        raise ValueError(f"{len(cells)} cells, at most {MAX_CELLS}")
    return cells


def render(cells: set, ink: str, ground: str, stop: str, grid: str | None, page: int = CANVAS) -> Image.Image:
    """Ground, grid lines, ink cells, stop. The page of 12 cells is `page` px, centred on the canvas;
    the grid keeps its pitch out to the canvas edge."""
    icon = Image.new("RGB", (CANVAS, CANVAS), rgb(ground))
    draw = ImageDraw.Draw(icon)
    cell, offset = page / GRID, (CANVAS - page) / 2

    def edge(i: float) -> int:
        return round(offset + i * cell)

    if grid:
        width = max(1, round(GRID_LINE * page / CANVAS))
        reach = int(offset // cell) + 1
        for i in range(-reach, GRID + reach + 1):
            at = edge(i) - width // 2
            draw.rectangle([at, 0, at + width - 1, CANVAS], fill=rgb(grid))
            draw.rectangle([0, at, CANVAS, at + width - 1], fill=rgb(grid))
    for (x, y), fill in [*((c, ink) for c in cells), (STOP, stop)]:
        draw.rectangle([edge(x), edge(y), edge(x + 1) - 1, edge(y + 1) - 1], fill=rgb(fill))
    return icon


def variants(cells: set, palette: dict, accent: str) -> dict[str, Image.Image]:
    ink, paper, grid, stop = palette["ink"], palette["paper"], palette["grid"], palette[accent]
    on_ink = palette.get(accent.replace("accent-", "accent-on-ink-"), stop)
    watch = render(cells, ink["light"], paper["light"], stop["light"], grid["light"], round(CANVAS * WATCH_SAFE))
    assert ImageStat.Stat(ImageOps.grayscale(watch)).mean[0] > 180, "a dark Watch icon reads as a black square (SBU-409)"
    return {
        "light": render(cells, ink["light"], paper["light"], stop["light"], grid["light"]),
        "dark": render(cells, ink["dark"], ink["light"], stop["dark"], grid["dark"]),
        "tinted": ImageOps.grayscale(render(cells, "#ffffff", "#000000", TINTED_STOP, grid["dark"])).convert("RGB"),
        "inversa": render(cells, paper["light"], ink["light"], on_ink["light"], grid["dark"]),
        "watch": watch,
    }


def write_appiconset(icons: dict, folder: Path) -> None:
    folder.mkdir(parents=True, exist_ok=True)
    for old in folder.glob("*.png"):
        old.unlink()
    images = []
    for variant, image in icons.items():
        image.save(folder / f"AppIcon-{variant}.png")
        entry = {"filename": f"AppIcon-{variant}.png", "idiom": "universal", "platform": "ios", "size": "1024x1024"}
        if variant != "light":
            entry["appearances"] = [{"appearance": "luminosity", "value": variant}]
        images.append(entry)
    (folder / "Contents.json").write_text(json.dumps({"images": images, "info": {"author": "xcode", "version": 1}}, indent=2) + "\n")


def write_watch_appiconset(icon: Image.Image, folder: Path) -> None:
    folder.mkdir(parents=True, exist_ok=True)
    for old in folder.glob("*.png"):
        old.unlink()
    icon.save(folder / "AppIcon-watch.png")
    entry = {"filename": "AppIcon-watch.png", "idiom": "universal", "platform": "watchos", "size": "1024x1024"}
    (folder / "Contents.json").write_text(json.dumps({"images": [entry], "info": {"author": "xcode", "version": 1}}, indent=2) + "\n")


def mac_icon(icon: Image.Image) -> Image.Image:
    """macOS draws no mask: the light icon goes in the Big Sur rounded square (824 of 1024, radius 185), with its shadow."""
    side, radius = MAC_SHAPE, round(MAC_SHAPE * 0.225)
    offset = (CANVAS - side) // 2
    shape = Image.new("L", (CANVAS, CANVAS), 0)
    ImageDraw.Draw(shape).rounded_rectangle([offset, offset, offset + side - 1, offset + side - 1], radius, fill=255)
    out = Image.new("RGBA", (CANVAS, CANVAS), (0, 0, 0, 0))
    shadow = shape.filter(ImageFilter.GaussianBlur(10)).point(lambda v: v * 77 // 255)  # 30% black, 10 px down
    out.paste((0, 0, 0, 255), (0, 10), shadow.crop((0, 0, CANVAS, CANVAS - 10)))
    out.paste(icon.resize((side, side), Image.LANCZOS), (offset, offset), shape.crop((offset, offset, offset + side, offset + side)))
    return out


def write_mac_appiconset(icon: Image.Image, folder: Path) -> None:
    folder.mkdir(parents=True, exist_ok=True)
    for old in folder.glob("*.png"):
        old.unlink()
    full, images = mac_icon(icon), []
    for points in (16, 32, 128, 256, 512):
        for scale in (1, 2):
            name = f"AppIcon-{points}@{scale}x.png"
            full.resize((points * scale,) * 2, Image.LANCZOS).save(folder / name)
            images.append({"filename": name, "idiom": "mac", "scale": f"{scale}x", "size": f"{points}x{points}"})
    (folder / "Contents.json").write_text(json.dumps({"images": images, "info": {"author": "xcode", "version": 1}}, indent=2) + "\n")


def write_artwork(icons: dict, folder: Path) -> None:
    """Same icon for SbuAppIconView, light and dark."""
    folder.mkdir(parents=True, exist_ok=True)
    for old in folder.iterdir():
        if old.name != "Contents.json":
            old.unlink()
    images = []
    for variant in ("light", "dark"):
        name = f"AppIconArtwork-{variant}.png"
        icons[variant].resize((512, 512), Image.LANCZOS).save(folder / name)
        entry = {"filename": name, "idiom": "universal"}
        if variant == "dark":
            entry["appearances"] = [{"appearance": "luminosity", "value": "dark"}]
        images.append(entry)
    (folder / "Contents.json").write_text(json.dumps({"images": images, "info": {"author": "xcode", "version": 1}}, indent=2) + "\n")


def sheet(all_icons: dict[str, dict], path: Path) -> None:
    """Proof at real size on an iPhone (@3x): every icon at 60, 40 and 29 pt, light, dark and tinted, on its wallpaper."""
    sizes, pad, columns = (180, 120, 87), 24, 4
    slot = sum(sizes) + pad * (len(sizes) + 1)
    rows = -(-len(all_icons) // columns)
    panels = (("light", "#d9d9d0"), ("dark", "#1a1a17"), ("tinted", "#1a1a17"))
    out = Image.new("RGB", (columns * slot * len(panels) + pad * (len(panels) - 1), rows * (sizes[0] + pad) + pad), "white")
    for p, (variant, wallpaper) in enumerate(panels):
        left = p * (columns * slot + pad)
        ImageDraw.Draw(out).rectangle([left, 0, left + columns * slot - 1, out.height], fill=rgb(wallpaper))
        for i, icons in enumerate(all_icons.values()):
            x, y = left + (i % columns) * slot + pad, pad + (i // columns) * (sizes[0] + pad)
            for side in sizes:
                small = icons[variant].resize((side, side), Image.LANCZOS)
                mask = Image.new("L", (side, side), 0)
                ImageDraw.Draw(mask).rounded_rectangle([0, 0, side - 1, side - 1], round(side * 0.2237), fill=255)
                out.paste(small, (x, y), mask)
                x += side + pad
    out.save(path)


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    parser.add_argument("name", help="app name in Design/icons/cells.json, like level, or all")
    parser.add_argument("--appiconset", type=Path, help="also write this AppIcon.appiconset (light, dark, tinted)")
    parser.add_argument("--artwork", type=Path, help="also write this AppIconArtwork.imageset")
    parser.add_argument("--watch-appiconset", type=Path, help="also write this watchOS AppIcon.appiconset (light, circle-safe)")
    parser.add_argument("--mac-appiconset", type=Path, help="also write this macOS AppIcon.appiconset (light, rounded square, 16-1024)")
    parser.add_argument("--inverse", type=Path, help="also write the Inversa alternate icon to this AppIcon-Inversa.appiconset")
    parser.add_argument("--sheet", type=Path, help="also write the real-size proof of these icons to this PNG")
    args = parser.parse_args()

    drawings, specs, palette = json.loads(CELLS.read_text()), json.loads(SPECS.read_text()), colors()
    names = list(drawings) if args.name == "all" else [args.name]
    if args.name == "all" and any([args.appiconset, args.artwork, args.watch_appiconset, args.mac_appiconset, args.inverse]):
        sys.exit("asset catalogs are per app: name one app")
    made = {}
    for name in names:
        entry = drawings.get(name) or sys.exit(f"{name} has no drawing in {CELLS.relative_to(ROOT)}")
        spec = specs.get(name) or sys.exit(f"{name} has no accent in {SPECS.relative_to(ROOT)}")
        try:
            cells = parse(entry["cells"])
        except ValueError as error:
            sys.exit(f"{name}: {error}")
        made[name] = icons = variants(cells, palette, spec["accent"])
        icons["light"].save(ICONS / f"sbu-{name}.png")
        print(ICONS.relative_to(ROOT) / f"sbu-{name}.png")
    if args.appiconset:
        write_appiconset({k: icons[k] for k in ("light", "dark", "tinted")}, args.appiconset)
        print(args.appiconset)
    if args.artwork:
        write_artwork(icons, args.artwork)
        print(args.artwork)
    if args.inverse:
        write_appiconset({"light": icons["inversa"]}, args.inverse)
        print(args.inverse)
    if args.mac_appiconset:
        write_mac_appiconset(icons["light"], args.mac_appiconset)
        print(args.mac_appiconset)
    if args.watch_appiconset:
        write_watch_appiconset(icons["watch"], args.watch_appiconset)
        print(args.watch_appiconset)
    if args.sheet:
        sheet(made, args.sheet)
        print(args.sheet)


if __name__ == "__main__":
    main()
