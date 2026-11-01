extension City {
    /// The extent of the bundled graph, from Data/build_graph.py.
    nonisolated var bounds: Polygon {
        switch self {
        case .milano: Polygon(ring: [Point(45.3883, 9.0722), Point(45.5372, 9.0722), Point(45.5372, 9.2913), Point(45.3883, 9.2913)])
        case .firenze: Polygon(ring: [Point(43.7111, 11.1692), Point(43.8341, 11.1692), Point(43.8341, 11.3317), Point(43.7111, 11.3317)])
        }
    }
}
