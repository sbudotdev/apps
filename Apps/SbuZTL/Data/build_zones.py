#!/usr/bin/env python3
"""Official perimeters to the zones Sbu ZTL bundles. Only geometry and the act's own fields, nothing derived.

Usage: python3 -I build_zones.py <milano.geojson> <firenze.geojson> <zones.json>
"""
import json
import sys
from datetime import date


def polygons(geometry):
    if geometry["type"] == "Polygon":
        return [geometry["coordinates"]]
    return geometry["coordinates"] if geometry["type"] == "MultiPolygon" else []


def rings(geometry):
    return [[[[round(p[1], 6), round(p[0], 6)] for p in ring] for ring in polygon] for polygon in polygons(geometry)]


def expired(properties):
    end = properties.get("val_fine")
    return end is not None and date.fromisoformat(end[:10]) < date.today()


KINDS = {"AP": "pedestrian", "DT": "noTransit", "DA": "other", "ZTL": "ztl", "AREA_C": "areaC", "AREA_B": "areaB"}
NAMES = {"AREA_C": "Area C", "AREA_B": "Area B"}
zones = []
for f in json.load(open(sys.argv[1]))["features"]:
    p = f["properties"]
    if expired(p) or not polygons(f["geometry"]):
        continue
    zones.append({
        "id": f"mi-{p['id_amat']}", "city": "milano", "name": NAMES.get(p["tipo"]) or p["nome"] or p["tipo"], "kind": KINDS[p["tipo"]],
        "act": p["ordinanza"], "exceptions": p["deroghe"], "section": p["tratto"], "polygons": rings(f["geometry"]),
    })
for f in json.load(open(sys.argv[2]))["features"]:
    p = f["properties"]
    zones.append({
        "id": f"fi-{p['id']}", "city": "firenze", "name": f"ZTL Settore {p['tipologia']}", "kind": "florenceSector",
        "act": p["atto_iniz"].strip(), "exceptions": None, "section": None, "polygons": rings(f["geometry"]),
    })
json.dump(zones, open(sys.argv[3], "w"), separators=(",", ":"), ensure_ascii=False)
print(len(zones), "zones")
