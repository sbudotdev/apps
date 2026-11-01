#!/usr/bin/env python3
"""Download the OSM extracts Sbu ZTL bundles: roads (for build_graph.py) and parkings (for build_parkings.py). Data (c) OpenStreetMap, ODbL.

Build time only, never at runtime. Keep the output in its own directory: it is untrusted input.
Usage: python3 -I fetch_osm.py <out-dir> [city ...]
"""
import sys
import time
import urllib.parse
import urllib.request
from pathlib import Path

# south, west, north, east: the zones' bounding box plus about 5.5 km, as for Milano and Firenze. Roma: Fascia Verde plus about 3 km.
EXTENTS = {
    "milano": (45.3883, 9.0722, 45.5372, 9.2913),
    "firenze": (43.7111, 11.1692, 43.8341, 11.3317),
    "bologna": (44.435, 11.259, 44.553, 11.427),
    "roma": (41.770, 12.386, 42.017, 12.611),
    "torino": (45.009, 7.599, 45.128, 7.768),
}
HIGHWAYS = "motorway|motorway_link|trunk|trunk_link|primary|primary_link|secondary|secondary_link|tertiary|tertiary_link|unclassified|residential|living_street|service|road"
ROADS = '[out:json][timeout:600];(way["highway"~"^({h})$"]({b});rel["restriction"]({b}););out body;>;out skel qt;'
PARKINGS = '[out:json][timeout:300];nwr["amenity"="parking"]({b});out center tags;'


def fetch(query, path):
    if path.exists():
        return
    data = urllib.parse.urlencode({"data": query}).encode()
    request = urllib.request.Request("https://overpass-api.de/api/interpreter", data, {"User-Agent": "sbu.dev-ztl-build/1.0"})
    with urllib.request.urlopen(request, timeout=700) as response:
        body = response.read()
    assert body.lstrip()[:1] == b"{", body[:300]
    path.write_bytes(body)
    print(path.name, len(body), flush=True)
    time.sleep(20)


def main(out, cities):
    for city in cities or EXTENTS:
        s, w, n, e = EXTENTS[city]
        box = f"{s},{w},{n},{e}"
        fetch(PARKINGS.format(b=box), Path(out) / f"{city}.parkings.json")
        if city not in ("milano", "firenze"):  # their graphs are already bundled
            fetch(ROADS.format(h=HIGHWAYS, b=box), Path(out) / f"{city}.roads.json")


if __name__ == "__main__":
    main(sys.argv[1], sys.argv[2:])
