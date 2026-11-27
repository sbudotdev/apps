#!/usr/bin/env python3
"""Engrave a plate: an instrument in copperplate style, kept as an ink mask.

Since ADR-0027 the app icons are drawn in cells (Tools/make_icons.py); the engravings stay as the
plates beside the sbu.dev column, the Open Graph previews (Tools/make_og.py) and the screenshot scenes
(Tools/make_screenshots.py). Subjects live in Design/icons/engravings.json ({name: {accent, subject, name}});
the mask is Design/icons/source/sbu-<name>.png (white, alpha = ink), so nothing calls a model twice.

Usage:
  python3 Tools/engrave.py level --generate           # new engraving from Gemini (GEMINI_API_KEY)
  python3 Tools/engrave.py level --from-image raw.png # engraving from an image you supply
"""
import argparse
import base64
import json
import os
import sys
import urllib.request
from pathlib import Path

from PIL import Image, ImageFilter, ImageOps

ROOT = Path(__file__).resolve().parent.parent
ICONS = ROOT / "Design" / "icons"
SPECS = ICONS / "engravings.json"
CANVAS = 1024
MARGIN = 0.15  # space around the engraving, as a fraction of its longer side
MODEL = "gemini-2.5-flash-image"
STYLE = (
    "Single subject, centered, filling about 70% of a square frame, generous empty margin. "
    "Fine copperplate engraving / etching style with dense crosshatching and stipple, "
    "warm near-black ink on plain flat off-white paper background, no paper texture, no color, "
    "no border, no frame, no text, no letters, no shadow on the ground, crisp lines that stay legible when small."
)


def subject_box(ink: Image.Image, cell: int = 8) -> tuple[int, int, int, int] | None:
    """Bounding box of the subject, ignoring specks of dust that would push it off centre.

    On a grid of `cell` pixels, grown by one cell so the strokes of the engraving join up, the
    subject is the largest connected blob; a speck away from it is a blob of its own. The box is
    then measured on the full-size ink inside that blob's area.
    """
    w, h = ink.size
    gw, gh = max(1, w // cell), max(1, h // cell)
    grid = ink.resize((gw, gh), Image.BOX).point(lambda v: 255 if v else 0).filter(ImageFilter.MaxFilter(3))
    on = grid.load()
    seen: set[tuple[int, int]] = set()
    best: list[tuple[int, int]] = []
    for start in ((x, y) for y in range(gh) for x in range(gw)):
        if on[start] == 0 or start in seen:
            continue
        blob, stack = [], [start]
        seen.add(start)
        while stack:
            x, y = stack.pop()
            blob.append((x, y))
            for nx, ny in ((x + 1, y), (x - 1, y), (x, y + 1), (x, y - 1)):
                if 0 <= nx < gw and 0 <= ny < gh and on[nx, ny] and (nx, ny) not in seen:
                    seen.add((nx, ny))
                    stack.append((nx, ny))
        if len(blob) > len(best):
            best = blob
    if not best:
        return None
    xs, ys = [x for x, _ in best], [y for _, y in best]
    area = (min(xs) * w // gw, min(ys) * h // gh, (max(xs) + 1) * w // gw, (max(ys) + 1) * h // gh)
    inner = ink.crop(area).getbbox()
    return (area[0] + inner[0], area[1] + inner[1], area[0] + inner[2], area[1] + inner[3]) if inner else None


def ink_mask(image: Image.Image) -> Image.Image:
    """Greyscale engraving -> mask where white is ink, cropped to the subject and centred."""
    grey = ImageOps.autocontrast(ImageOps.grayscale(image), cutoff=0.5)
    paper = 200  # anything lighter is paper
    grey = grey.point(lambda v: 255 if v >= paper else int(v * 255 / paper))
    ink = grey.point(lambda v: 255 if v < 180 else 0)
    box = subject_box(ink)
    if box is None:
        sys.exit("no ink found in the image")
    grey = grey.crop(box)
    w, h = grey.size
    side = max(w, h)
    pad = int(side * MARGIN)
    framed = Image.new("L", (side + 2 * pad, side + 2 * pad), 255)
    framed.paste(grey, ((side - w) // 2 + pad, (side - h) // 2 + pad))
    return ImageOps.invert(framed.resize((CANVAS, CANVAS), Image.LANCZOS))


def generate(subject: str) -> Image.Image:
    key = os.environ.get("GEMINI_API_KEY") or sys.exit("GEMINI_API_KEY is not set")
    body = {
        "contents": [{"parts": [{"text": f"Illustration: {subject}. {STYLE}"}]}],
        "generationConfig": {"responseModalities": ["IMAGE"], "imageConfig": {"aspectRatio": "1:1"}},
    }
    request = urllib.request.Request(
        f"https://generativelanguage.googleapis.com/v1beta/models/{MODEL}:generateContent",
        data=json.dumps(body).encode(),
        headers={"Content-Type": "application/json", "x-goog-api-key": key},
    )
    reply = json.load(urllib.request.urlopen(request, timeout=180))
    for part in reply["candidates"][0]["content"]["parts"]:
        if "inlineData" in part:
            from io import BytesIO

            return Image.open(BytesIO(base64.b64decode(part["inlineData"]["data"])))
    sys.exit("the model returned no image: " + json.dumps(reply)[:300])



def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    parser.add_argument("name", help="app name in Design/icons/engravings.json, like level")
    source_group = parser.add_mutually_exclusive_group(required=True)
    source_group.add_argument("--generate", action="store_true", help="draw a new engraving with Gemini")
    source_group.add_argument("--from-image", type=Path, help="use this image as the engraving")
    args = parser.parse_args()
    spec = json.loads(SPECS.read_text()).get(args.name) or sys.exit(f"{args.name} is not in {SPECS.relative_to(ROOT)}")
    raw = generate(spec["subject"]) if args.generate else Image.open(args.from_image)
    mask = ink_mask(raw)
    source = ICONS / "source" / f"sbu-{args.name}.png"
    source.parent.mkdir(parents=True, exist_ok=True)
    Image.merge("LA", (Image.new("L", mask.size, 255), mask)).save(source)
    print(source.relative_to(ROOT))


if __name__ == "__main__":
    main()
