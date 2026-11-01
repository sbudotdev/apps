import Foundation

/// Road graph in compressed sparse row form, as written by scripts/build_graph.py.
public struct Graph: Sendable {
    public let lat: [Float64]
    public let lon: [Float64]
    let first: [Int32]
    let to: [Int32]
    let seconds: [Float32]
    let metres: [Float32]
    let maxMetresPerSecond: Double
    let tails: [Int]
    let bannedTurns: Set<Turn>

    public var nodeCount: Int { lat.count }

    public init(lat: [Double], lon: [Double], first: [Int32], to: [Int32], seconds: [Float32], metres: [Float32], bannedTurns: Set<Turn> = []) {
        self.bannedTurns = bannedTurns
        var tails = [Int](repeating: 0, count: to.count)
        for u in 0..<lat.count {
            for e in Int(first[u])..<Int(first[u + 1]) { tails[e] = u }
        }
        self.tails = tails
        self.lat = lat
        self.lon = lon
        self.first = first
        self.to = to
        self.seconds = seconds
        self.metres = metres
        var fastest = 1.0
        for i in to.indices where seconds[i] > 0 {
            fastest = max(fastest, Double(metres[i] / seconds[i]))
        }
        maxMetresPerSecond = fastest
    }

    public init(contentsOf url: URL) throws {
        let data = try Data(contentsOf: url)
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
        let turnData = (try? Data(contentsOf: url.deletingPathExtension().appendingPathExtension("turns"))) ?? Data()
        let triples = turnData.withUnsafeBytes { raw in
            (0..<(turnData.count / 4)).map { raw.loadUnaligned(fromByteOffset: $0 * 4, as: Int32.self) }
        }
        let banned = stride(from: 0, to: triples.count, by: 3).map {
            Turn(from: Int(triples[$0]), via: Int(triples[$0 + 1]), to: Int(triples[$0 + 2]))
        }
        self.init(lat: lat, lon: lon, first: first, to: to, seconds: seconds, metres: metres, bannedTurns: Set(banned))
    }

    public func point(_ node: Int) -> Point { Point(lat[node], lon[node]) }

    /// Nearest nodes first, skipping those `excluded` rejects.
    public func nearest(to p: Point, count: Int = 1, excluding excluded: (Int) -> Bool = { _ in false }) -> [Int] {
        (0..<nodeCount)
            .filter { abs(lat[$0] - p.lat) < 0.05 && abs(lon[$0] - p.lon) < 0.05 && !excluded($0) }
            .map { (node: $0, d: point($0).metres(to: p)) }
            .sorted { $0.d < $1.d }
            .prefix(count)
            .map(\.node)
    }

    public struct Path: Sendable {
        public let nodes: [Int]
        public let seconds: Double
        public let metres: Double
    }

    /// A* over edges, so a turn can be checked against the one before it. An edge into a blocked node is
    /// allowed only from another blocked node: a route can leave the zone it starts in and never enter one.
    /// Driving inside the start zone costs `insideFactor` times more in the search, so the way out is short.
    public func route(from start: Int, to goal: Int, blocked: [Bool]? = nil, insideFactor: Double = 5) -> Path? {
        guard start != goal else { return Path(nodes: [start], seconds: 0, metres: 0) }
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
        while parent[edges.last!] >= 0 { edges.append(Int(parent[edges.last!])) }
        edges.reverse()
        return Path(
            nodes: [start] + edges.map { Int(to[$0]) },
            seconds: edges.reduce(0) { $0 + Double(seconds[$1]) },
            metres: edges.reduce(0) { $0 + Double(metres[$1]) })
    }

    /// Nodes inside any zone. Also blocks both ends of an edge whose midpoint is inside, for long edges crossing a corner.
    public func blockedNodes(zones: [Zone]) -> [Bool] {
        var blocked = (0..<nodeCount).map { node in zones.contains { $0.contains(point(node)) } }
        for u in 0..<nodeCount {
            for e in Int(first[u])..<Int(first[u + 1]) {
                let v = Int(to[e])
                if blocked[u] || blocked[v] { continue }
                let mid = Point((lat[u] + lat[v]) / 2, (lon[u] + lon[v]) / 2)
                if zones.contains(where: { $0.contains(mid) }) {
                    blocked[u] = true
                    blocked[v] = true
                }
            }
        }
        return blocked
    }
}

public struct Turn: Sendable, Hashable {
    public let from: Int
    public let via: Int
    public let to: Int

    public init(from: Int, via: Int, to: Int) {
        self.from = from
        self.via = via
        self.to = to
    }
}

struct MinHeap {
    private var items: [(key: Double, value: Int)] = []

    mutating func push(_ key: Double, _ value: Int) {
        items.append((key, value))
        var i = items.count - 1
        while i > 0, items[(i - 1) / 2].key > items[i].key {
            items.swapAt(i, (i - 1) / 2)
            i = (i - 1) / 2
        }
    }

    mutating func pop() -> (key: Double, value: Int)? {
        guard let top = items.first else { return nil }
        let last = items.removeLast()
        if !items.isEmpty {
            items[0] = last
            var i = 0
            while true {
                let l = 2 * i + 1, r = l + 1
                var m = i
                if l < items.count, items[l].key < items[m].key { m = l }
                if r < items.count, items[r].key < items[m].key { m = r }
                if m == i { break }
                items.swapAt(i, m)
                i = m
            }
        }
        return top
    }
}
