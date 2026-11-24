// swift-tools-version: 6.0
// Throwaway arranger spike (Sbu Bar plan 1, task 2). Not part of the SbuBar app target.
import PackageDescription

let package = Package(
    name: "BarSpike",
    platforms: [.macOS(.v15)],
    targets: [.executableTarget(name: "BarSpike")]
)
