#!/usr/bin/env python3
"""Turn an Overpass road dump into the compact driving graph Sbu ZTL bundles. Data (c) OpenStreetMap, ODbL.

Usage: python3 -I build_graph.py <overpass.json> <out-prefix>
Writes <prefix>.bin (graph, street name and speed limit per edge), <prefix>.turns (banned turns)
and <prefix>.names (street names, one per line).
"""
import json
import math
import re
import struct
import sys
from array import array

SPEED = {  # km/h where maxspeed is missing: urban guesses, not measured
    "motorway": 90, "motorway_link": 50, "trunk": 70, "trunk_link": 40, "primary": 50, "primary_link": 35,
    "secondary": 40, "secondary_link": 30, "tertiary": 35, "tertiary_link": 25, "unclassified": 30,
    "residential": 25, "living_street": 10, "service": 15, "road": 25,
}
NO_ACCESS = {"no", "private", "agricultural", "forestry", "emergency", "psv", "bus", "delivery", "customers", "military"}


def intern(names, tags):
    name = tags.get("name", "").replace("\n", " ")
    return names.setdefault(name, len(names))


def speed(tags):
    raw = tags.get("maxspeed", "")
    match = re.fullmatch(r"(\d+)", raw)
    return (int(match.group(1)), True) if match and int(match.group(1)) > 0 else (SPEED[tags["highway"]], False)


def metres(a, b):
    dy = (b[0] - a[0]) * 111_320
    dx = (b[1] - a[1]) * 111_320 * math.cos(math.radians(a[0]))
    return math.hypot(dx, dy)


def main(path, prefix):
    elements = json.load(open(path))["elements"]
    coords = {e["id"]: (e["lat"], e["lon"]) for e in elements if e["type"] == "node"}
    ways = [e for e in elements if e["type"] == "way"]
    adjacency, used, names = {}, set(), {"": 0}
    tagged, total, kept_ways = 0.0, 0.0, {}
    for way in ways:
        tags = way.get("tags", {})
        if tags.get("highway") not in SPEED:
            continue
        if tags.get("motor_vehicle", tags.get("motorcar", tags.get("vehicle", tags.get("access", "yes")))) in NO_ACCESS:
            continue
        kph, has_tag = speed(tags)
        name = intern(names, tags)
        limit = kph if has_tag and kph < 256 else 0
        one = tags.get("oneway", "no")
        forward = one != "-1"
        backward = one in ("no", "-1") and tags.get("junction") not in ("roundabout", "circular") and tags["highway"] not in ("motorway",)
        if one in ("reversible", "alternating"):
            continue
        kept_ways[way["id"]] = way["nodes"]
        for a, b in zip(way["nodes"], way["nodes"][1:]):
            if a not in coords or b not in coords:
                continue
            m = metres(coords[a], coords[b])
            total += m
            tagged += m if has_tag else 0
            seconds = m / (kph / 3.6)
            used.update((a, b))
            if forward:
                adjacency.setdefault(a, []).append((b, seconds, m, name, limit))
            if backward:
                adjacency.setdefault(b, []).append((a, seconds, m, name, limit))
    nodes = sorted(used)
    index = {n: i for i, n in enumerate(nodes)}
    forward = [[index[e[0]] for e in adjacency.get(n, [])] for n in nodes]
    backward = [[] for _ in nodes]
    for u, targets in enumerate(forward):
        for v in targets:
            backward[v].append(u)

    # Kosaraju, iterative: keep the largest strongly connected component so every node can reach every other.
    seen, order = [False] * len(nodes), []
    for start in range(len(nodes)):
        if seen[start]:
            continue
        seen[start] = True
        stack = [(start, 0)]
        while stack:
            u, i = stack.pop()
            if i < len(forward[u]):
                stack.append((u, i + 1))
                v = forward[u][i]
                if not seen[v]:
                    seen[v] = True
                    stack.append((v, 0))
            else:
                order.append(u)
    component, sizes = [-1] * len(nodes), {}
    for root in reversed(order):
        if component[root] >= 0:
            continue
        component[root] = root
        stack, size = [root], 0
        while stack:
            u = stack.pop()
            size += 1
            for v in backward[u]:
                if component[v] < 0:
                    component[v] = root
                    stack.append(v)
        sizes[root] = size
    main_component = max(sizes, key=sizes.get)
    keep = [i for i in range(len(nodes)) if component[i] == main_component]
    new = {old: i for i, old in enumerate(keep)}

    first, to, secs, dist, edge_names, limits = array("i", [0]), array("i"), array("f"), array("f"), array("i"), array("B")
    for old in keep:
        for v, s, m, name, limit in adjacency.get(nodes[old], []):
            target = new.get(index[v])
            if target is not None:
                to.append(target)
                secs.append(s)
                dist.append(m)
                edge_names.append(name)
                limits.append(limit)
        first.append(len(to))
    with open(prefix + ".bin", "wb") as out:
        out.write(struct.pack("<ii", len(keep), len(to)))
        array("i", [round(coords[nodes[o]][0] * 1e7) for o in keep]).tofile(out)
        array("i", [round(coords[nodes[o]][1] * 1e7) for o in keep]).tofile(out)
        first.tofile(out)
        to.tofile(out)
        secs.tofile(out)
        dist.tofile(out)
        edge_names.tofile(out)
        limits.tofile(out)
    with open(prefix + ".names", "w") as out:
        out.write("\n".join(names))
    restrictions = []
    for r in (e for e in elements if e["type"] == "relation"):
        kind = r.get("tags", {}).get("restriction", "")
        members = r.get("members", [])
        via = [m["ref"] for m in members if m["role"] == "via" and m["type"] == "node"]
        source = [m["ref"] for m in members if m["role"] == "from" and m["type"] == "way"]
        target = [m["ref"] for m in members if m["role"] == "to" and m["type"] == "way"]
        if kind and len(via) == 1 and source and target and all(w in kept_ways for w in source + target):
            restrictions.append({"kind": kind, "via": via[0], "from": [kept_ways[w] for w in source], "to": [kept_ways[w] for w in target]})
    # Every restriction becomes banned (from, via, to) triples in graph indices; via-way restrictions aren't modelled.
    def neighbours(way, node):
        return {x for i, n in enumerate(way) if n == node for x in way[max(i - 1, 0):i] + way[i + 1:i + 2]}

    graph = {nodes[o]: i for i, o in enumerate(keep)}
    banned = set()
    for x in restrictions:
        via = graph.get(x["via"])
        if via is None:
            continue
        sources = {n for w in x["from"] for n in neighbours(w, x["via"])}
        targets = {n for w in x["to"] for n in neighbours(w, x["via"])}
        exits = {e[0] for e in adjacency.get(x["via"], [])}
        hit = targets if x["kind"].startswith("no_") else exits - targets if x["kind"].startswith("only_") else set()
        for a in sources:
            for b in hit:
                if a in graph and b in graph:
                    banned.add((graph[a], via, graph[b]))
    with open(prefix + ".turns", "wb") as out:
        array("i", [v for t in sorted(banned) for v in t]).tofile(out)
    print(f"banned turns: {len(banned)}")
    print(f"{prefix}: nodes {len(keep)} of {len(nodes)}, edges {len(to)}, restrictions {len(restrictions)}, maxspeed on {tagged / total:.0%} of length")


if __name__ == "__main__":
    main(sys.argv[1], sys.argv[2])
