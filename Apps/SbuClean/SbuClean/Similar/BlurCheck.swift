/// Tells a photo out of focus or shaken from a sharp one, by its sharpness score.
///
/// The threshold comes from real photos measured the way `ImageAnalyzer` does (grey, 256 pixels
/// on the longer side): sharp ones, shallow focus included, score above 130; the same photos
/// blurred by a few pixels fall under 40. Very dark or empty shots, such as a photo taken in a
/// pocket, score low too, and belong in the same list.
nonisolated enum BlurCheck {
    /// Scores below this are blurry.
    static let threshold: Float = 30
    /// The smallest analysed picture whose score means something: a smaller copy, scaled up,
    /// would read as blurry.
    static let minimumSide = ImageAnalyzer.sharpnessSide

    /// Whether the item is a blurry photo. Screenshots and favourites never are: the first are
    /// flat by nature, the second the user chose to keep.
    static func isBlurry(_ item: MediaItem, analysis: ImageAnalysis?) -> Bool {
        guard item.kind == .photo, !item.isScreenshot, !item.isFavorite,
              let analysis, analysis.side >= minimumSide else { return false }

        return analysis.sharpness < threshold
    }
}
