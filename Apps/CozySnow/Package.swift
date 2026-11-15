// swift-tools-version:5.9
import PackageDescription

let package = Package(
    name: "CozySnow",
    platforms: [
        .macOS(.v14)
    ],
    targets: [
        .executableTarget(
            name: "CozySnow",
            path: "Sources/CozySnow"
        ),
        .testTarget(
            name: "CozySnowTests",
            dependencies: ["CozySnow"],
            path: "Tests/CozySnowTests"
        )
    ]
)
