#!/usr/bin/env python3
"""Official perimeters of Bologna, Roma and Torino, merged into zones.json. Milano and Firenze are left as build_zones.py wrote them.

Only geometry and the source's own fields; the rule for each kind lives in ZoneRule+Table.swift.
Usage: python3 -I build_cities.py <download-dir> <zones.json>
<download-dir> holds bologna/zones.geojson, bologna/t.geojson, torino/access.xml and roma/<layer>.geojson. Sources in SbuZTL/Rules/Dataset+All.swift.
"""
import json
import sys
import xml.etree.ElementTree as ET

BOUNDS = {"bologna": (44.435, 11.259, 44.553, 11.427), "roma": (41.770, 12.386, 42.017, 12.611), "torino": (45.009, 7.599, 45.128, 7.768)}


def ring(points):
    return [[round(p[1], 6), round(p[0], 6)] for p in points]


def polygons(geometry):
    if geometry is None:
        return []
    multi = [geometry["coordinates"]] if geometry["type"] == "Polygon" else geometry["coordinates"]
    return [[ring(loop) for loop in polygon] for polygon in multi]


def features(path):
    return json.load(open(path))["features"]


def zone(zone_id, city, name, kind, shapes, act=None, section=None):
    zone = {"id": zone_id, "city": city, "name": name, "kind": kind, "act": act, "exceptions": None, "section": section, "polygons": shapes}
    points = [p for shape in shapes for loop in shape for p in loop]
    s, w, n, e = BOUNDS[city]
    assert points, zone_id
    assert all(s <= p[0] <= n and w <= p[1] <= e for p in points), f"{zone_id} is outside {city}"
    return zone


def bologna(base):
    t = {f["properties"]["codice"] for f in features(f"{base}/bologna/t.geojson")}  # the Zona T dataset names one code of the ZTL dataset
    assert t == {41}, t
    zones = []
    for f in sorted(features(f"{base}/bologna/zones.geojson"), key=lambda f: f["properties"]["codice"]):
        p = f["properties"]
        act = p["ordinanza"]
        streets = sorted({p[f"nomevia{i}"].title() for i in range(1, 8) if p[f"nomevia{i}"]})
        shapes = polygons(f["geometry"])
        if p["codice"] == 40:
            # Outer ring only: the holes and islets are pedestrian areas, which answer "not known" rather than "no zone here".
            zones.append(zone("bo-40", "bologna", "ZTL Bologna", "bolognaZtl", [[shapes[0][0]]], act))
        elif p["codice"] == 41:
            zones.append(zone("bo-41", "bologna", "Zona T", "bolognaT", shapes, act))
        else:
            zones.append(zone(f"bo-{p['codice']}", "bologna", f"Zona Bologna, codice {p['codice']}", "bolognaUnnamed", shapes, act, ", ".join(streets) or None))
    return zones


def roma(base):
    def shapes(layer, keep=lambda p: True):
        return [s for f in features(f"{base}/roma/{layer}.geojson") if keep(f["properties"]) for s in polygons(f["geometry"])]

    return [
        zone("rm-centro-diurna", "roma", "ZTL Centro diurna", "romaCentroDay", shapes("centro_diurna")),
        zone("rm-centro-notturna", "roma", "ZTL Centro notturna", "romaCentroNight", shapes("centro_notturna")),
        zone("rm-tridente-area", "roma", "Settori A e C, possibile Tridente", "romaTridenteArea", shapes("settori", lambda p: p["Name"] in ("SETTORE A", "SETTORE C"))),
        zone("rm-trastevere-diurna", "roma", "ZTL Trastevere diurna", "romaTrastevereDay", shapes("trastevere_diurna")),
        zone("rm-trastevere-notturna", "roma", "ZTL Trastevere notturna", "romaTrastevereNight", shapes("trastevere_notturna")),
        zone("rm-san-lorenzo", "roma", "ZTL San Lorenzo notturna", "romaSanLorenzoNight", shapes("sanlorenzo")),
        # Last: a tap names the place after the first zone under the finger.
        zone("rm-fascia-verde", "roma", "ZTL Fascia Verde", "romaFasciaVerde", shapes("fascia_verde")),
    ]


def torino(base):
    ns = {"a": "https://simone.5t.torino.it/ns/access_control.xsd"}
    ztl = ET.parse(f"{base}/torino/access.xml").getroot().find("a:ztl", ns)
    assert ztl.get("name") == "ZTL Centrale"
    line = [[float(p.get("lng")), float(p.get("lat"))] for p in ztl.findall("a:polyline/a:point", ns)]
    assert line[0] == line[-1], "the perimeter should close"
    return [zone("to-centrale", "torino", "ZTL Centrale", "torinoCentrale", [[ring(line)]])]


def main(base, out):
    kept = [z for z in json.load(open(out)) if z["city"] in ("milano", "firenze")]
    added = bologna(base) + roma(base) + torino(base)
    json.dump(kept + added, open(out, "w"), separators=(",", ":"), ensure_ascii=False)
    for city in BOUNDS:
        zs = [z for z in added if z["city"] == city]
        points = [p for z in zs for shape in z["polygons"] for loop in shape for p in loop]
        print(city, len(zs), "zones, lat", min(p[0] for p in points), max(p[0] for p in points), "lon", min(p[1] for p in points), max(p[1] for p in points))
        print("  ", [z["name"] for z in zs])
    print(len(kept) + len(added), "zones in all")


if __name__ == "__main__":
    main(sys.argv[1], sys.argv[2])
