import Foundation

/// Turns `RemoteMessage` into bytes and back, inside an envelope that carries the protocol version.
/// A peer with another version is refused before its message is read, so the format can change later.
nonisolated enum RemoteCodec {
    static let version = 1

    enum Failure: Error, Equatable {
        case unsupportedVersion(Int)
    }

    private struct Envelope: Codable {
        var version: Int
        var message: RemoteMessage
    }

    private struct Header: Decodable {
        var version: Int
    }

    static func encode(_ message: RemoteMessage) throws -> Data {
        try JSONEncoder().encode(Envelope(version: version, message: message))
    }

    static func decode(_ data: Data) throws -> RemoteMessage {
        let header = try JSONDecoder().decode(Header.self, from: data)
        guard header.version == version else { throw Failure.unsupportedVersion(header.version) }
        return try JSONDecoder().decode(Envelope.self, from: data).message
    }
}
