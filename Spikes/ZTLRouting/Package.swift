// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "ZTLRouting",
    platforms: [.macOS(.v14)],
    targets: [
        .target(name: "ZTLCore"),
        .executableTarget(name: "ztlspike", dependencies: ["ZTLCore"]),
        .executableTarget(name: "ztlgraph", dependencies: ["ZTLCore"]),
        .testTarget(name: "ZTLCoreTests", dependencies: ["ZTLCore"]),
    ]
)
