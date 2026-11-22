extension Route {
    /// A stable name for UI tests, the same in every language.
    var identifier: String {
        switch self {
        case .swipe(let source): "swipe.\(source.identifier)"
        case .months: "months"
        case .onThisDay: "onThisDay"
        case .albums: "albums"
        case .duplicates: "duplicates"
        case .groups(let kind): "groups.\(kind.rawValue)"
        case .grid(let category): "grid.\(category.rawValue)"
        case .videos: "videos"
        case .livePhotos: "livePhotos"
        case .compress: "compress"
        case .bin: "bin"
        case .keepForever: "keepForever"
        case .stats: "stats"
        case .contacts: "contacts"
        }
    }
}

extension SwipeSource {
    var identifier: String {
        switch self {
        case .recent: "recent"
        case .random: "random"
        case .onThisDay: "onThisDay"
        case .onDay(let day): "onDay.\(day.month).\(day.day)"
        case .later: "later"
        case .month(let month): "month.\(month.year).\(month.month)"
        case .album(let album): "album.\(album.id)"
        case .category(let category): "category.\(category.rawValue)"
        }
    }
}
