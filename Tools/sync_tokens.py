#!/usr/bin/env python3
"""Generate SbuKit color assets, token constants and the site CSS from Design/tokens.json.

Usage: python3 Tools/sync_tokens.py
Writes:
  Packages/SbuKit/Sources/SbuKit/Resources/Colors.xcassets/<token>.colorset
  Packages/SbuKit/Sources/SbuKit/Theme/SbuTheme+Tokens.swift
  ../site/src/styles/tokens.css (the sbudotdev/site clone next to this repo, when present)
  ../os/sandbox/src/theme.rs (the sbudotdev/os clone next to this repo, when present)
"""
import json
import re
import shutil
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
TOKENS = ROOT / "Design" / "tokens.json"
KIT = ROOT / "Packages" / "SbuKit" / "Sources" / "SbuKit"
ASSETS = KIT / "Resources" / "Colors.xcassets"
SWIFT = KIT / "Theme" / "SbuTheme+Tokens.swift"
SITE = ROOT.parent / "site"
CSS = SITE / "src" / "styles" / "tokens.css"
OS = ROOT.parent / "os"
THEME_RS = OS / "sandbox" / "src" / "theme.rs"


def camel(name: str) -> str:
    head, *rest = name.split("-")
    return head + "".join(part[:1].upper() + part[1:] for part in rest)


def number(value: str) -> str:
    """'16px' -> '16', '22.5%' -> '0.225', '0.18s' -> '0.18'."""
    if value.endswith("%"):
        return repr(float(value[:-1]) / 100)
    return re.sub(r"(px|s)$", "", value)


def is_accent(name: str) -> bool:
    return name.startswith("accent-") and not name.startswith("accent-on-ink-")


def colorset(hex_light: str, hex_dark: str) -> dict:
    def entry(hex_value: str, dark: bool, idiom: str = "universal") -> dict:
        h = hex_value.lstrip("#")
        item = {
            "idiom": idiom,
            "color": {
                "color-space": "srgb",
                "components": {
                    "red": f"0x{h[0:2].upper()}",
                    "green": f"0x{h[2:4].upper()}",
                    "blue": f"0x{h[4:6].upper()}",
                    "alpha": f"{int(h[6:8], 16) / 255:.3f}" if len(h) == 8 else "1.000",
                },
            },
        }
        if dark:
            item["appearances"] = [{"appearance": "luminosity", "value": "dark"}]
        return item

    # watchOS ignores the dark appearance and always runs dark: the watch idiom takes the dark value.
    return {
        "colors": [entry(hex_light, False), entry(hex_dark, True), entry(hex_dark, False, "watch")],
        "info": {"author": "xcode", "version": 1},
    }


def luminance(hex_value: str) -> float:
    h = hex_value.lstrip("#")
    channels = [int(h[i : i + 2], 16) / 255 for i in (0, 2, 4)]
    r, g, b = [c / 12.92 if c <= 0.04045 else ((c + 0.055) / 1.055) ** 2.4 for c in channels]
    return 0.2126 * r + 0.7152 * g + 0.0722 * b


def contrast(a: str, b: str) -> float:
    high, low = sorted([luminance(a), luminance(b)], reverse=True)
    return (high + 0.05) / (low + 0.05)


def check_contrast(colors: list[dict]) -> list[str]:
    """WCAG pairs the design system promises, in both themes. Returns the failures."""
    by_name = {t["name"]: t["value"] for t in colors}
    grounds = ["paper", "surface-raised"]
    accents = [n for n in by_name if is_accent(n)]
    on_ink = [n for n in by_name if n.startswith("accent-on-ink-")]
    pairs = [("ink", g, 7) for g in grounds]
    # ink-muted is text (4.5) and the waiting full stop (graphic, 3): 4.5 covers both.
    pairs += [(n, g, 4.5) for n in ["ink-muted", "success", "warning", "danger", *accents] for g in grounds]
    pairs += [("on-accent", a, 4.5) for a in accents] + [("on-brand", "brand", 4.5), ("focus", "paper", 3)]
    # The Closure: paper word (text) and accent-on-ink full stop (graphic) on the ink block.
    pairs += [("paper", "ink", 7)] + [(n, "ink", 3) for n in on_ink]
    failures = []
    for theme in ("light", "dark"):
        for fg, bg, minimum in pairs:
            ratio = contrast(by_name[fg][theme][:7], by_name[bg][theme][:7])
            if ratio < minimum:
                failures.append(f"{theme}: {fg} on {bg} is {ratio:.2f}:1, needs {minimum}:1")
    return failures


def oklab(hex_value: str) -> tuple[float, float, float]:
    h = hex_value.lstrip("#")
    channels = [int(h[i : i + 2], 16) / 255 for i in (0, 2, 4)]
    r, g, b = [c / 12.92 if c <= 0.04045 else ((c + 0.055) / 1.055) ** 2.4 for c in channels]
    l = (0.4122214708 * r + 0.5363325363 * g + 0.0514459929 * b) ** (1 / 3)
    m = (0.2119034982 * r + 0.6806995451 * g + 0.1073969566 * b) ** (1 / 3)
    s = (0.0883024619 * r + 0.2817188376 * g + 0.6299787005 * b) ** (1 / 3)
    return (
        0.2104542553 * l + 0.7936177850 * m - 0.0040720468 * s,
        1.9779984951 * l - 2.4285922050 * m + 0.4505937099 * s,
        0.0259040371 * l + 0.7827717662 * m - 0.8086757660 * s,
    )


def xterm256(hex_value: str) -> int:
    """Nearest xterm-256 index in OKLab, skipping 0-15 (the terminal theme redefines those)."""
    levels = [0, 95, 135, 175, 215, 255]
    palette = {16 + i: (levels[i // 36], levels[i // 6 % 6], levels[i % 6]) for i in range(216)}
    palette |= {232 + i: (8 + 10 * i,) * 3 for i in range(24)}
    target = oklab(hex_value)
    return min(
        palette,
        key=lambda i: sum((a - b) ** 2 for a, b in zip(target, oklab("%02x%02x%02x" % palette[i]))),
    )


def rust(colors: list[dict]) -> str:
    """The `sbu` CLI's full stop: accent-os light, always (no background detection, #74)."""
    hex_value = next(t for t in colors if t["name"] == "accent-os")["value"]["light"]
    r, g, b = (hex_value[i : i + 2] for i in (1, 3, 5))
    return "\n".join(
        [
            "// Generated by apps/Tools/sync_tokens.py from Design/tokens.json. Do not edit.",
            "",
            f"/// `accent-os` light ({hex_value}): the full stop in a 24-bit terminal.",
            f"pub const ACCENT_OS: (u8, u8, u8) = (0x{r}, 0x{g}, 0x{b});",
            "/// The xterm-256 index nearest to `ACCENT_OS` in OKLab.",
            f"pub const ACCENT_OS_256: u8 = {xterm256(hex_value)};",
            "",
        ]
    )


def css(tokens: dict) -> str:
    """Light and dark custom properties, plus a Tailwind theme that holds only design-system tokens."""
    colors = tokens["color"]["tokens"]
    shadows = tokens["shadow"]["tokens"]
    themed = colors + shadows

    def block(theme: str) -> list[str]:
        return [f"  --sbu-{t['name']}: {t['value'][theme]};" for t in themed]

    quaderno = [t for key in QUADERNO for t in tokens[key]["tokens"]]

    lines = [
        "/* Generated by Tools/sync_tokens.py from Design/tokens.json. Do not edit. */",
        "",
        ":root {",
        "  color-scheme: light dark;",
        *block("light"),
        *[f"  --sbu-{t['name']}: {t['value']};" for t in tokens["stroke"]["tokens"]],
        *[f"  --sbu-{t['name']}: {float(t['value'][:-1]) / 100:g}em;" for t in tokens["mark"]["tokens"]],
        *[f"  --sbu-{t['name']}: {css_value(t['value'])};" for t in quaderno],
        "}",
        "",
        "@media (prefers-color-scheme: dark) {",
        "  :root {",
        *["  " + line for line in block("dark")],
        "  }",
        "}",
        "",
        "/* Tailwind keeps only these: no default palette, spacing, radii, fonts or shadows. */",
        "@theme inline {",
        "  --*: initial;",
        *[f"  --color-{t['name']}: var(--sbu-{t['name']});" for t in colors],
        *[f"  --spacing-{t['name'].removeprefix('space-')}: {t['value']};" for t in tokens["spacing"]["tokens"]],
        *[f"  --radius-{t['name'].removeprefix('radius-')}: {t['value']};" for t in tokens["radius"]["tokens"]],
        *[f"  --font-{name}: {family};" for name, family in tokens["type"]["families"].items()],
    ]
    def rem(px: str) -> str:
        """Type sizes in rem (16px = 1rem) so they follow the browser text size, like Dynamic Type."""
        return f"{float(number(px)) / 16:g}rem"

    for group in tokens["type"]["groups"]:
        for style in group["styles"]:
            name = style["name"]
            lines.append(f"  --text-{name}: {rem(style['fontSize'])};")
            lines.append(f"  --text-{name}--line-height: {rem(style['lineHeight'])};")
            lines.append(f"  --text-{name}--font-weight: {style['fontWeight']};")
            if "letterSpacing" in style:
                lines.append(f"  --text-{name}--letter-spacing: {style['letterSpacing']};")
    lines += ["}", ""]
    return "\n".join(lines)


QUADERNO = ["grid", "full-stop", "control", "figure", "motion"]


def css_value(value: str) -> str:
    """Percentages become em (cartiglio tracking), the rest stays as written."""
    return f"{float(value[:-1]) / 100:g}em" if value.endswith("%") else value


def main() -> None:
    tokens = json.loads(TOKENS.read_text())
    colors = tokens["color"]["tokens"]
    metrics = [
        ("Spacing", tokens["spacing"]["tokens"]),
        ("Radius", tokens["radius"]["tokens"]),
        ("Stroke", tokens["stroke"]["tokens"]),
        ("Size", tokens["size"]["tokens"]),
        ("Mark", tokens["mark"]["tokens"]),
        *[(key.replace("-", " ").title(), tokens[key]["tokens"]) for key in QUADERNO],
    ]

    failures = check_contrast(colors)
    if failures:
        raise SystemExit("Contrast below the design system minimum:\n  " + "\n  ".join(failures))

    if ASSETS.exists():
        shutil.rmtree(ASSETS)
    ASSETS.mkdir(parents=True)
    (ASSETS / "Contents.json").write_text(json.dumps({"info": {"author": "xcode", "version": 1}}, indent=2) + "\n")
    for token in colors:
        folder = ASSETS / f"{token['name']}.colorset"
        folder.mkdir()
        body = colorset(token["value"]["light"], token["value"]["dark"])
        (folder / "Contents.json").write_text(json.dumps(body, indent=2) + "\n")

    lines = [
        "// Generated by Tools/sync_tokens.py from Design/tokens.json. Do not edit.",
        "",
        "import SwiftUI",
        "",
        "public extension SbuTheme {",
        "    // MARK: - Color",
        "",
    ]
    for token in colors:
        lines.append(f"    /// {token['usage']}")
        lines.append(f"    nonisolated static let {camel(token['name'])} = Color(\"{token['name']}\", bundle: .module)")
    lines += [
        "",
        "    /// `surface` is `paper` since v5.",
        '    @available(*, deprecated, renamed: "paper")',
        "    static var surface: Color { paper }",
    ]
    for title, group in metrics:
        lines += ["", f"    // MARK: - {title}", ""]
        for token in group:
            lines.append(f"    /// {token['usage']}")
            lines.append(f"    nonisolated static let {camel(token['name'])}: CGFloat = {number(token['value'])}")
    lines += ["}", "", "public extension SbuAccent {"]
    names = {t["name"] for t in colors}
    for token in colors:
        if is_accent(token["name"]) and f"accent-on-ink-{token['name'][7:]}" in names:
            app = camel(token["name"][7:])
            lines.append(f"    static let {app} = SbuAccent(base: SbuTheme.{camel(token['name'])}, onInk: SbuTheme.{camel('accent-on-ink-' + token['name'][7:])})")
    lines += ["}", "", "extension SbuTheme {"]
    lines.append("    /// Color asset names, in token order.")
    names = ", ".join(f'"{t["name"]}"' for t in colors)
    lines.append(f"    static let colorTokenNames = [{names}]")
    lines.append("")
    lines.append("    /// Numeric tokens by original name, for checking against tokens.json.")
    lines.append("    static let metricTokens: [String: CGFloat] = [")
    for _, group in metrics:
        for token in group:
            lines.append(f"        \"{token['name']}\": {camel(token['name'])},")
    lines += ["    ]", "}", ""]
    SWIFT.parent.mkdir(parents=True, exist_ok=True)
    SWIFT.write_text("\n".join(lines))
    print(f"{len(colors)} colors, {sum(len(g) for _, g in metrics)} metrics -> {SWIFT.relative_to(ROOT)}")

    if SITE.is_dir():
        CSS.write_text(css(tokens))
        print(f"-> {CSS}")
    else:
        print(f"No site clone at {SITE}: site CSS skipped")

    if OS.is_dir():
        THEME_RS.write_text(rust(colors))
        print(f"-> {THEME_RS}")
    else:
        print(f"No os clone at {OS}: theme.rs skipped")


if __name__ == "__main__":
    main()
