import Foundation

/// What Vision says about one photo: enough to group it and to pick the best of a group.
nonisolated struct ImageAnalysis: Codable, Equatable, Sendable {
    /// The Vision feature print (revision 2): 768 numbers, close for pictures that look alike.
    var featurePrint: [Float]
    /// The best face capture quality in the picture, 0 to 1; `nil` without faces.
    var faceQuality: Float?
    /// The variance of the Laplacian of a small grey copy: higher is sharper.
    var sharpness: Float
    /// The longer side, in pixels, of the picture analysed: a small copy reads as blurry.
    var side: Int

    private enum CodingKeys: String, CodingKey {
        case featurePrint
        case faceQuality
        case sharpness
        case side
    }

    init(featurePrint: [Float], faceQuality: Float? = nil, sharpness: Float = 0, side: Int = 0) {
        self.featurePrint = featurePrint
        self.faceQuality = faceQuality
        self.sharpness = sharpness
        self.side = side
    }

    // The print is stored as raw bytes: a cache of thousands of photos stays small and fast.
    init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let data = try container.decode(Data.self, forKey: .featurePrint)
        featurePrint = data.withUnsafeBytes { Array($0.bindMemory(to: Float.self)) }
        faceQuality = try container.decodeIfPresent(Float.self, forKey: .faceQuality)
        sharpness = try container.decode(Float.self, forKey: .sharpness)
        // Analyses saved before 1.1 have no side: never judged blurry.
        side = try container.decodeIfPresent(Int.self, forKey: .side) ?? 0
    }

    func encode(to encoder: any Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        let data = featurePrint.withUnsafeBufferPointer { Data(buffer: $0) }
        try container.encode(data, forKey: .featurePrint)
        try container.encodeIfPresent(faceQuality, forKey: .faceQuality)
        try container.encode(sharpness, forKey: .sharpness)
        try container.encode(side, forKey: .side)
    }
}
