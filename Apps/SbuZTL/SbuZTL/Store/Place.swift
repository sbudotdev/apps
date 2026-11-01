import Foundation

/// A destination the user chose.
nonisolated struct Place: Identifiable, Codable, Hashable, Sendable {
    var id: String { "\(point.lat),\(point.lon)" }
    let name: String
    let address: String
    let point: Point
    var symbol = "mappin"
}
