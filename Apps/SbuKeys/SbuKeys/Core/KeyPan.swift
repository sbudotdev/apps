/// Where a key sits on the keyboard, left to right, as a stereo pan from -1 to 1.
nonisolated enum KeyPan {
    /// How far the outermost keys go: never fully in one ear.
    static let width: Float = 0.8

    /// Column of each key on an ANSI keyboard, in key widths from the left edge.
    private static let columns: [Int: Float] = {
        var columns: [Int: Float] = [:]
        let rows: [(start: Float, codes: [Int])] = [
            (0, [50, 18, 19, 20, 21, 23, 22, 26, 28, 25, 29, 27, 24, 51]),
            (0.5, [48, 12, 13, 14, 15, 17, 16, 32, 34, 31, 35, 33, 30, 42]),
            (0.75, [57, 0, 1, 2, 3, 5, 4, 38, 40, 37, 41, 39, 36]),
            (1.25, [56, 6, 7, 8, 9, 11, 45, 46, 43, 47, 44, 60]),
        ]
        for row in rows {
            for (offset, code) in row.codes.enumerated() {
                columns[code] = row.start + Float(offset)
            }
        }
        columns[49] = 6.5 // space, centred under B
        return columns
    }()

    /// Backslash, at the end of the Q row.
    private static let rightmostColumn = columns.values.max() ?? 1

    /// The pan for a key code; keys not on the main block (arrows, keypad, F-keys) sit in the centre.
    static func pan(forKeyCode keyCode: Int) -> Float {
        guard let column = columns[keyCode] else { return 0 }
        return (column / rightmostColumn * 2 - 1) * width
    }
}
