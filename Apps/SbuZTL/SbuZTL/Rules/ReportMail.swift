import Foundation

/// A wrong rule goes to Sbu by email, filled in: no server, nothing sent until you send it.
nonisolated enum ReportMail {
    static let address = "matteogiuditta@gmail.com"

    static func url(zone: String? = nil) -> URL? {
        var components = URLComponents()
        components.scheme = "mailto"
        components.path = address
        let about = zone.map { " (\($0))" } ?? ""
        components.queryItems = [
            URLQueryItem(name: "subject", value: String(localized: "Sbu ZTL: dato sbagliato") + about),
            URLQueryItem(name: "body", value: String(localized: "Cosa è sbagliato, e dove lo hai visto:")),
        ]
        return components.url
    }
}
