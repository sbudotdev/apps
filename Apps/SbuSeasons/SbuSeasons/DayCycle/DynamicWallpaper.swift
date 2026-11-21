import CoreImage
import ImageIO
import UniformTypeIdentifiers

/// «Giorno e notte» fatto da macOS: un solo HEIC con gli otto momenti e, nei metadati XMP del primo fotogramma,
/// l'ora a cui comincia ognuno (`apple_desktop:h24`, lo stesso formato degli sfondi dinamici di Apple).
/// Lo cambia il Mac da solo, anche ad app chiusa: nessun timer, nessuna CPU nostra.
nonisolated enum DynamicWallpaper {
    /// L'ordine dei fotogrammi: mezzogiorno per primo, perché macOS usa il primo come anteprima.
    static let frames: [DayMoment] = [.noon] + DayMoment.allCases.filter { $0 != .noon }

    /// I metadati `h24`: per ogni fotogramma la frazione del giorno (ora locale / 24) a cui comincia,
    /// più i fotogrammi per il tema chiaro e scuro fissi.
    struct Timeline: Codable, Equatable {
        struct Item: Codable, Equatable {
            var frame: Int
            var time: Double
            enum CodingKeys: String, CodingKey { case frame = "i", time = "t" }
        }
        struct Appearance: Codable, Equatable {
            var light: Int
            var dark: Int
            enum CodingKeys: String, CodingKey { case light = "l", dark = "d" }
        }
        var items: [Item]
        var appearance: Appearance
        var light: Int { appearance.light }
        var dark: Int { appearance.dark }
        enum CodingKeys: String, CodingKey { case items = "ti", appearance = "ap" }
    }

    static let timeline = Timeline(
        items: frames.enumerated()
            .map { Timeline.Item(frame: $0.offset, time: Tuning.momentStarts[$0.element, default: 0] / 24) }
            .sorted { $0.time < $1.time },   // in ordine d'ora, come negli sfondi di Apple
        appearance: .init(light: frames.firstIndex(of: .noon)!, dark: frames.firstIndex(of: .night)!)
    )

    /// Legge `source`, ne fa gli otto momenti con `DayTint` e scrive l'HEIC in `destination`.
    /// Lento (otto fotogrammi grandi): mai sul main thread. Prima in un file a parte, poi al suo posto:
    /// un file a metà non resta in cache.
    static func render(_ source: URL, to destination: URL, context: CIContext = CIContext()) throws {
        guard let input = CIImage(contentsOf: source) else { throw CocoaError(.fileReadCorruptFile) }
        let space = CGColorSpace(name: CGColorSpace.sRGB)!
        let brightness = DayTint.brightness(of: input, context: context)
        let partial = destination.deletingLastPathComponent().appending(path: ".\(destination.lastPathComponent).partial")
        guard let file = CGImageDestinationCreateWithURL(partial as CFURL, UTType.heic.identifier as CFString, frames.count, nil)
        else { throw CocoaError(.fileWriteUnknown) }
        let options = [kCGImageDestinationLossyCompressionQuality: Tuning.dynamicWallpaperQuality] as CFDictionary
        for (index, moment) in frames.enumerated() {
            try autoreleasepool {
                let tinted = DayTint.apply(Tuning.momentLooks[moment] ?? MomentLook(), to: input, brightness: brightness)
                guard let frame = context.createCGImage(tinted, from: input.extent, format: .RGBA8, colorSpace: space)
                else { throw CocoaError(.fileWriteUnknown) }
                if index == 0 {
                    CGImageDestinationAddImageAndMetadata(file, frame, try metadata(), options)
                } else {
                    CGImageDestinationAddImage(file, frame, options)
                }
            }
        }
        guard CGImageDestinationFinalize(file) else {
            try? FileManager.default.removeItem(at: partial)
            throw CocoaError(.fileWriteUnknown)
        }
        _ = try? FileManager.default.removeItem(at: destination)
        try FileManager.default.moveItem(at: partial, to: destination)
    }

    /// L'XMP del primo fotogramma: la timeline come plist binario in base64.
    private static func metadata() throws -> CGImageMetadata {
        let encoder = PropertyListEncoder()
        encoder.outputFormat = .binary
        let value = try encoder.encode(timeline).base64EncodedString() as CFString
        let metadata = CGImageMetadataCreateMutable()
        guard CGImageMetadataRegisterNamespaceForPrefix(metadata, "http://ns.apple.com/namespace/1.0/" as CFString, "apple_desktop" as CFString, nil),
              CGImageMetadataSetValueWithPath(metadata, nil, "apple_desktop:h24" as CFString, value)
        else { throw CocoaError(.fileWriteUnknown) }
        return metadata
    }

    /// La timeline scritta in un file, se c'è: nil per un'immagine qualsiasi.
    static func timeline(of url: URL) -> Timeline? {
        guard let images = CGImageSourceCreateWithURL(url as CFURL, nil),
              let metadata = CGImageSourceCopyMetadataAtIndex(images, 0, nil),
              let value = CGImageMetadataCopyStringValueWithPath(metadata, nil, "apple_desktop:h24" as CFString),
              let data = Data(base64Encoded: value as String)
        else { return nil }
        return try? PropertyListDecoder().decode(Timeline.self, from: data)
    }
}
