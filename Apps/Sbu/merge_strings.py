#!/usr/bin/env python3
"""Builds Sbu/Localizable.xcstrings from the shell's strings and each tool app's catalog (ADR-0027).

The tools are static libraries: their Text("...") looks in Bundle.main's Localizable table, so the
Sbu app ships one table with every key. The apps' catalogs stay the only source: never edit the output.

    python3 merge_strings.py          # writes the merged catalog
    python3 merge_strings.py --check  # fails if it is out of date (the Xcode build runs this)

A key two sources translate differently keeps the first one (shell, then the tools in order) and is printed.
"""
import json
import sys
from pathlib import Path

HERE = Path(__file__).resolve().parent
SOURCES = [
    HERE / "Strings/Shell.xcstrings",
    HERE / "../SbuLevel/SbuLevel/Localizable.xcstrings",
    HERE / "../SbuMoon/SbuMoon/Localizable.xcstrings",
    HERE / "../SbuSubscriptions/SbuSubscriptions/Localizable.xcstrings",
]
OUTPUT = HERE / "Sbu/Localizable.xcstrings"


def merged():
    strings, origin = {}, {}
    for source in SOURCES:
        for key, value in json.loads(source.read_text())["strings"].items():
            if key not in strings:
                strings[key], origin[key] = value, source
            elif strings[key].get("localizations") != value.get("localizations"):
                print(f"merge_strings: '{key}' differs in {source.relative_to(HERE.parent)}; "
                      f"kept {origin[key].relative_to(HERE.parent)}", file=sys.stderr)
    catalog = {"sourceLanguage": "it", "strings": dict(sorted(strings.items())), "version": "1.0"}
    return json.dumps(catalog, ensure_ascii=False, indent=2, sort_keys=True) + "\n"


def main():
    text = merged()
    if "--check" in sys.argv:
        if not OUTPUT.exists() or OUTPUT.read_text() != text:
            print(f"error: {OUTPUT.name} is out of date: run python3 Apps/Sbu/merge_strings.py", file=sys.stderr)
            return 1
        return 0
    OUTPUT.write_text(text)
    return 0


if __name__ == "__main__":
    sys.exit(main())
