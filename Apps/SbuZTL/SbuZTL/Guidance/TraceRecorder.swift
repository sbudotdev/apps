#if DEBUG
import Foundation

/// GPS traces of real drives, kept on the phone, to calibrate arrival times (#629, #658). Debug builds only.
final class TraceRecorder {
    private let url: URL?

    init(date: Date = .now) {
        let folder = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first?.appendingPathComponent("tracks")
        if let folder { try? FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true) }
        url = folder?.appendingPathComponent("\(Int(date.timeIntervalSince1970)).csv")
    }

    func append(_ fix: LocationFix) {
        guard let url else { return }
        let line = "\(fix.date.timeIntervalSince1970),\(fix.point.lat),\(fix.point.lon),\(fix.accuracy),\(fix.speed)\n"
        guard let data = line.data(using: .utf8) else { return }
        if let handle = try? FileHandle(forWritingTo: url) {
            defer { try? handle.close() }
            _ = try? handle.seekToEnd()
            try? handle.write(contentsOf: data)
        } else {
            try? data.write(to: url)
        }
    }

    static var files: [URL] {
        guard let folder = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first?.appendingPathComponent("tracks") else { return [] }
        return (try? FileManager.default.contentsOfDirectory(at: folder, includingPropertiesForKeys: nil))?.sorted { $0.path < $1.path } ?? []
    }
}
#endif
