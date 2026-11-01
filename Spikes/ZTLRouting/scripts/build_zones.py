#!/usr/bin/env python3
"""Spike 2: official perimeters to [[ring, ...], ...] with [lat, lon] points. Usage: python3 -I build_zones.py <mi.geojson> <fi.geojson> <outdir>"""
import json
import sys
from datetime import date


def polygons(feature):
    geometry = feature["geometry"]
    if geometry["type"] == "Polygon":
        return [geometry["coordinates"]]
    if geometry["type"] == "MultiPolygon":
        return geometry["coordinates"]
    print("skipped", geometry["type"])
    return []


def rings(polygon):
    return [[[p[1], p[0]] for p in ring] for ring in polygon]


def expired(feature):
    end = feature["properties"].get("val_fine")
    return end is not None and date.fromisoformat(end[:10]) < date(2026, 11, 1)


mi, fi, out = json.load(open(sys.argv[1]))["features"], json.load(open(sys.argv[2]))["features"], sys.argv[3]
sets = {
    "milano-c": [f for f in mi if f["properties"]["tipo"] == "AREA_C"],
    # Area B is left out: it covers the whole city, every trip would start inside it.
    "milano-tutte": [f for f in mi if f["properties"]["tipo"] != "AREA_B" and not expired(f)],
    "firenze": fi,
}
for name, features in sets.items():
    zones = [rings(p) for f in features for p in polygons(f)]
    json.dump(zones, open(f"{out}/zones-{name}.json", "w"))
    print(name, len(features), "features,", len(zones), "polygons")
