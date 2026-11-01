@testable import SbuZTL

/// A small city: a 3x3 street grid, each block 100 m at 10 m/s.
enum GraphFixture {
    static let step = 0.0009

    static func point(_ row: Int, _ column: Int) -> Point { Point(Double(row) * step, Double(column) * step) }

    static func grid(banned: Set<Turn> = []) -> Graph {
        var first: [Int32] = [0], to: [Int32] = [], seconds: [Float32] = [], metres: [Float32] = [], names: [Int32] = [], limits: [UInt8] = []
        for row in 0..<3 {
            for column in 0..<3 {
                let here = row * 3 + column
                let neighbours = [(row - 1, column, Int32(1)), (row + 1, column, 1), (row, column - 1, Int32(2)), (row, column + 1, 2)]
                for (r, c, name) in neighbours where (0..<3).contains(r) && (0..<3).contains(c) {
                    _ = here
                    to.append(Int32(r * 3 + c))
                    seconds.append(10)
                    metres.append(100)
                    names.append(name)
                    limits.append(name == 1 ? 50 : 30)
                }
                first.append(Int32(to.count))
            }
        }
        let points = (0..<9).map { point($0 / 3, $0 % 3) }
        return Graph(lat: points.map(\.lat), lon: points.map(\.lon), first: first, to: to, seconds: seconds, metres: metres,
                     nameIndex: names, limit: limits, names: ["", "Via Nord", "Via Est"], bannedTurns: banned)
    }
}
