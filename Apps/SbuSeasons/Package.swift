// swift-tools-version:5.9
import PackageDescription

let package = Package(
    name: "SbuSeasons",
    platforms: [
        .macOS(.v14)
    ],
    targets: [
        .executableTarget(
            name: "SbuSeasons",
            path: "Sources/SbuSeasons"
        )
    ]
)
