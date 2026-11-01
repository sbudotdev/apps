#!/usr/bin/env python3
"""OSM parkings (amenity=parking) to the small file Sbu ZTL bundles: points and names. Data (c) OpenStreetMap, ODbL.

Usage: python3 -I build_parkings.py <parkings.json> <city.parkings.json> [...]
"""
import json
import sys

CLOSED = {"private", "no", "customers", "permit", "residents", "employees", "military"}


def main(out, paths):
    lat, lon, names, seen = [], [], [], set()
    for path in paths:
        count = 0
        for e in json.load(open(path))["elements"]:
            tags = e.get("tags", {})
            p = e.get("center") or e
            if tags.get("amenity") != "parking" or tags.get("access") in CLOSED or "lat" not in p:
                continue
            if tags.get("parking") == "street_side":  # painted bays: thousands of them, and no use on a map of the city
                continue
            point = (round(p["lat"], 5), round(p["lon"], 5))
            if point in seen:
                continue
            seen.add(point)
            lat.append(point[0])
            lon.append(point[1])
            names.append(tags.get("name", "").replace("\n", " "))
            count += 1
        print(path.rsplit("/", 1)[-1], count)
    assert all(35 < x < 47 for x in lat) and all(6 < x < 19 for x in lon), "outside Italy"
    json.dump({"lat": lat, "lon": lon, "names": names}, open(out, "w"), separators=(",", ":"), ensure_ascii=False)
    print(len(lat), "parkings")


if __name__ == "__main__":
    main(sys.argv[1], sys.argv[2:])
