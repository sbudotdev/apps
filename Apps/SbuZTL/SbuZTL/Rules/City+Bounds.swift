extension City {
    /// The extent of the bundled graph, from Data/build_graph.py.
    nonisolated var bounds: Polygon {
        switch self {
        case .milano: Polygon(ring: [Point(45.3883, 9.0722), Point(45.5372, 9.0722), Point(45.5372, 9.2913), Point(45.3883, 9.2913)])
        case .firenze: Polygon(ring: [Point(43.7111, 11.1692), Point(43.8341, 11.1692), Point(43.8341, 11.3317), Point(43.7111, 11.3317)])
        case .bologna: Polygon(ring: [Point(44.435, 11.259), Point(44.553, 11.259), Point(44.553, 11.427), Point(44.435, 11.427)])
        case .roma: Polygon(ring: [Point(41.770, 12.386), Point(42.017, 12.386), Point(42.017, 12.611), Point(41.770, 12.611)])
        case .torino: Polygon(ring: [Point(45.009, 7.599), Point(45.128, 7.599), Point(45.128, 7.768), Point(45.009, 7.768)])
        }
    }
}
