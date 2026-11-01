#!/usr/bin/env python3
"""Spike 2: count routes that break an OSM turn restriction. Usage: python3 -I check_turns.py <routes.json> <prefix-by-city dir>"""
import json
import sys
from array import array
from pathlib import Path


def touches(way, node):
    return node in way


def main(routes_path, base):
    routes = json.load(open(routes_path))
    total = broken = 0
    for r in routes:
        ids = array("q")
        path = Path(base) / f"{r['city']}.ids"
        ids.frombytes(path.read_bytes())
        restrictions = {}
        for x in json.load(open(Path(base) / f"{r['city']}.restrictions.json")):
            restrictions.setdefault(x["via"], []).append(x)
        nodes = [ids[i] for i in r["nodes"]]
        hits = []
        for a, via, b in zip(nodes, nodes[1:], nodes[2:]):
            for x in restrictions.get(via, []):
                came = any(a in w and via in w for w in x["from"])
                goes = any(b in w and via in w for w in x["to"])
                if x["kind"].startswith("no_") and came and goes:
                    hits.append(x["kind"])
                if x["kind"].startswith("only_") and came and not goes:
                    hits.append(x["kind"])
        total += 1
        broken += bool(hits)
        print(f"{r['label']}: {len(hits)} divieti di svolta violati {sorted(set(hits))}")
    print(f"Percorsi con almeno un divieto violato: {broken}/{total}")


main(sys.argv[1], sys.argv[2])
