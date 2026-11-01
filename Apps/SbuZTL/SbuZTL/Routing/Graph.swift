import Foundation

/// Road graph in compressed sparse row form, as written by Data/build_graph.py. Data (c) OpenStreetMap, ODbL.
nonisolated struct Graph: Sendable {
    let lat: [Double]
    let lon: [Double]
    let first: [Int32]
    let to: [Int32]
    let seconds: [Float32]
    let metres: [Float32]
    let nameIndex: [Int32]
    let limit: [UInt8]
    let names: [String]
    let bannedTurns: Set<Turn>
    private let maxMetresPerSecond: Double
    private let tails: [Int]
    private let minLat: Double
    private let maxLat: Double
    private let minLon: Double
    private let maxLon: Double

    var nodeCount: Int { lat.count }

    init(lat: [Double], lon: [Double], first: [Int32], to: [Int32], seconds: [Float32], metres: [Float32],
         nameIndex: [Int32]? = nil, limit: [UInt8]? = nil, names: [String] = [""], bannedTurns: Set<Turn> = []) {
        self.lat = lat
        self.lon = lon
        self.first = first
        self.to = to
        self.seconds = seconds
        self.metres = metres
        self.nameIndex = nameIndex ?? [Int32](repeating: 0, count: to.count)
        self.limit = limit ?? [UInt8](repeating: 0, count: to.count)
        self.names = names
        self.bannedTurns = bannedTurns
        var tails = [Int](repeating: 0, count: to.count)
        for u in 0..<lat.count {
            for e in Int(first[u])..<Int(first[u + 1]) { tails[e] = u }
        }
        self.tails = tails
        var fastest = 1.0
        for i in to.indices where seconds[i] > 0 {
            fastest = max(fastest, Double(metres[i] / seconds[i]))
        }
        maxMetresPerSecond = fastest
        minLat = lat.min() ?? 0
        maxLat = lat.max() ?? 0
        minLon = lon.min() ?? 0
        maxLon = lon.max() ?? 0
    }

    init(contentsOf url: URL) throws {
        let data = try Data(contentsOf: url, options: .mappedIfSafe)
        func read<T>(_ type: T.Type, at offset: Int, count: Int) -> [T] {
            data.withUnsafeBytes { raw in
                (0..<count).map { raw.loadUnaligned(fromByteOffset: offset + $0 * MemoryLayout<T>.size, as: T.self) }
            }
        }
        let header = read(Int32.self, at: 0, count: 2)
        let n = Int(header[0]), m = Int(header[1])
        var offset = 8
        let lat = read(Int32.self, at: offset, count: n).map { Double($0) / 1e7 }
        offset += n * 4
        let lon = read(Int32.self, at: offset, count: n).map { Double($0) / 1e7 }
        offset += n * 4
        let first = read(Int32.self, at: offset, count: n + 1)
        offset += (n + 1) * 4
        let to = read(Int32.self, at: offset, count: m)
        offset += m * 4
        let seconds = read(Float32.self, at: offset, count: m)
        offset += m * 4
        let metres = read(Float32.self, at: offset, count: m)
        offset += m * 4
        let nameIndex = read(Int32.self, at: offset, count: m)
        offset += m * 4
        let limit = read(UInt8.self, at: offset, count: m)
        let names = try String(contentsOf: url.deletingPathExtension().appendingPathExtension("names"), encoding: .utf8)
            .split(separator: "\n", omittingEmptySubsequences: false).map(String.init)
        let turnData = try Data(contentsOf: url.deletingPathExtension().appendingPathExtension("turns"))
        let triples = turnData.withUnsafeBytes { raw in
            (0..<(turnData.count / 4)).map { raw.loadUnaligned(fromByteOffset: $0 * 4, as: Int32.self) }
        }
        let banned = stride(from: 0, to: triples.count, by: 3).map {
            Turn(from: Int(triples[$0]), via: Int(triples[$0 + 1]), to: Int(triples[$0 + 2]))
        }
        self.init(lat: lat, lon: lon, first: first, to: to, seconds: seconds, metres: metres,
                  nameIndex: nameIndex, limit: limit, names: names, bannedTurns: Set(banned))
    }

    func point(_ node: Int) -> Point { Point(lat[node], lon[node]) }

    func covers(_ p: Point) -> Bool {
        p.lat >= minLat && p.lat <= maxLat && p.lon >= minLon && p.lon <= maxLon
    }

    /// Nearest nodes first, skipping those `excluded` rejects.
    func nearest(to p: Point, count: Int = 1, excluding excluded: (Int) -> Bool = { _ in false }) -> [Int] {
        (0..<nodeCount)
            .filter { abs(lat[$0] - p.lat) < 0.05 && abs(lon[$0] - p.lon) < 0.05 && !excluded($0) }
            .map { (node: $0, d: point($0).metres(to: p)) }
            .sorted { $0.d < $1.d }
            .prefix(count)
            .map(\.node)
    }

    struct Path: Sendable {
        let nodes: [Int]
        let edges: [Int]
        let seconds: Double
        let metres: Double
    }

    /// A* over edges, so a turn can be checked against the one before it. An edge into a blocked node is
    /// allowed only from another blocked node: a route can leave the zone it starts in and never enter one.
    /// Driving inside the start zone costs `insideFactor` times more in the search, so the way out is short.
    func route(from start: Int, to goal: Int, blocked: [Bool]? = nil, insideFactor: Double = 5) -> Path? {
        guard start != goal else { return Path(nodes: [start], edges: [], seconds: 0, metres: 0) }
        var best = [Double](repeating: .infinity, count: to.count)
        var parent = [Int32](repeating: -1, count: to.count)
        var heap = MinHeap()
        let goalPoint = point(goal)
        func cost(_ e: Int, from u: Int) -> Double {
            let v = Int(to[e])
            return Double(seconds[e]) * (blocked?[u] == true && blocked?[v] == true ? insideFactor : 1)
        }
        func enterable(_ v: Int, from u: Int) -> Bool {
            !(blocked?[v] == true && blocked?[u] != true)
        }
        for e in Int(first[start])..<Int(first[start + 1]) where enterable(Int(to[e]), from: start) {
            best[e] = cost(e, from: start)
            heap.push(best[e] + point(Int(to[e])).metres(to: goalPoint) / maxMetresPerSecond, e)
        }
        var last = -1
        while let (_, e) = heap.pop() {
            let u = Int(to[e])
            if u == goal { last = e; break }
            let tail = tails[e]
            let exits = Int(first[u + 1]) - Int(first[u])
            for next in Int(first[u])..<Int(first[u + 1]) {
                let v = Int(to[next])
                if v == tail && exits > 1 { continue }
                if !enterable(v, from: u) || bannedTurns.contains(Turn(from: tail, via: u, to: v)) { continue }
                let total = best[e] + cost(next, from: u)
                if total < best[next] {
                    best[next] = total
                    parent[next] = Int32(e)
                    heap.push(total + point(v).metres(to: goalPoint) / maxMetresPerSecond, next)
                }
            }
        }
        guard last >= 0 else { return nil }
        var edges = [last]
        while parent[edges[edges.count - 1]] >= 0 { edges.append(Int(parent[edges[edges.count - 1]])) }
        edges.reverse()
        return Path(
            nodes: [start] + edges.map { Int(to[$0]) },
            edges: edges,
            seconds: edges.reduce(0) { $0 + Double(seconds[$1]) },
            metres: edges.reduce(0) { $0 + Double(metres[$1]) })
    }

    /// Nodes inside any polygon. Also blocks both ends of an edge whose midpoint is inside, for long edges crossing a corner.
    func blockedNodes(polygons: [Polygon]) -> [Bool] {
        var blocked = (0..<nodeCount).map { node in polygons.contains { $0.contains(point(node)) } }
        for u in 0..<nodeCount {
            for e in Int(first[u])..<Int(first[u + 1]) {
                let v = Int(to[e])
                if blocked[u] || blocked[v] { continue }
                let mid = Point((lat[u] + lat[v]) / 2, (lon[u] + lon[v]) / 2)
                if polygons.contains(where: { $0.contains(mid) }) {
                    blocked[u] = true
                    blocked[v] = true
                }
            }
        }
        return blocked
    }
}
