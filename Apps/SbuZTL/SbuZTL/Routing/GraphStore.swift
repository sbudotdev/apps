import Foundation

/// Loads each city's graph once, off the main actor.
actor GraphStore {
    private var graphs: [City: Graph] = [:]

    func graph(for city: City) throws -> Graph {
        if let graph = graphs[city] { return graph }
        guard let url = Bundle.main.url(forResource: city.rawValue, withExtension: "bin") else { throw RouteError.noRoute }
        let graph = try Graph(contentsOf: url)
        graphs[city] = graph
        return graph
    }
}
