#!/usr/bin/env python3
"""Export the Instagram assets of sbu.dev from instagram.html with Chrome headless.

Usage: python3 marketing/social/instagram/source/render.py [name ...]   -> marketing/social/instagram/<name>.png
Without names it exports every frame. Needs Google Chrome and ImageMagick (`magick`, to keep the top of the render); sips checks the size.
"""
import functools
import subprocess
import sys
import tempfile
import threading
from http.server import SimpleHTTPRequestHandler, ThreadingHTTPServer
from pathlib import Path

ROOT = Path(__file__).resolve().parents[4]  # the apps repo: the page loads fonts and icons from Design/
OUT = Path(__file__).resolve().parent.parent
CHROME = "/Applications/Google Chrome.app/Contents/MacOS/Google Chrome"
FRAMES = {
    "profile-1080": (1080, 1080),
    "highlight-apps": (1080, 1920),
    "highlight-free": (1080, 1920),
    "highlight-privacy": (1080, 1920),
    "highlight-behind-the-scenes": (1080, 1920),
    "highlight-faq": (1080, 1920),
    "post-1-intro": (1080, 1350),
    "post-2-promises": (1080, 1350),
    "post-3-apps": (1080, 1350),
}


class QuietHandler(SimpleHTTPRequestHandler):
    def log_message(self, *_):
        pass


def size_of(path):
    out = subprocess.run(["sips", "-g", "pixelWidth", "-g", "pixelHeight", str(path)], capture_output=True, text=True, check=True).stdout
    values = [int(line.split()[-1]) for line in out.splitlines() if "pixel" in line]
    return tuple(values)


def shoot(url, out, width, height):
    # Same trick as Tools/make_screenshots.py: headless Chrome can leave the bottom of the window
    # unpainted, so render 200 px taller and keep the top.
    with tempfile.TemporaryDirectory() as tmp:
        raw = Path(tmp) / "raw.png"
        subprocess.run([CHROME, "--headless=new", "--disable-gpu", "--hide-scrollbars", "--force-device-scale-factor=1",
                        "--run-all-compositor-stages-before-draw", f"--window-size={width},{height + 200}",
                        "--virtual-time-budget=10000", f"--screenshot={raw}", url], check=True, capture_output=True)
        subprocess.run(["magick", str(raw), "-crop", f"{width}x{height}+0+0", "+repage", "-alpha", "off", str(out)],
                       check=True, capture_output=True)
    if size_of(out) != (width, height):
        sys.exit(f"{out.name}: {size_of(out)}, expected {width}×{height}")


def main():
    names = sys.argv[1:] or list(FRAMES)
    unknown = [n for n in names if n not in FRAMES]
    if unknown:
        sys.exit(f"unknown frame: {', '.join(unknown)} (one of {', '.join(FRAMES)})")
    server = ThreadingHTTPServer(("127.0.0.1", 0), functools.partial(QuietHandler, directory=ROOT))
    threading.Thread(target=server.serve_forever, daemon=True).start()
    page = f"http://127.0.0.1:{server.server_port}/{Path(__file__).resolve().parent.relative_to(ROOT)}/instagram.html"
    for name in names:
        width, height = FRAMES[name]
        shoot(f"{page}?f={name}", OUT / f"{name}.png", width, height)
        print(f"{name}.png {width}×{height}")
    server.shutdown()


if __name__ == "__main__":
    main()
