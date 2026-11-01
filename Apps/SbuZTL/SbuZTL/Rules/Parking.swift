/// A parking from OpenStreetMap: where it is, and its name if it has one.
nonisolated struct Parking: Sendable, Identifiable, Equatable {
    let id: Int
    let point: Point
    let name: String
}
