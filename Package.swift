// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "MacSesh",
    platforms: [.macOS(.v14)],
    targets: [
        .executableTarget(
            name: "MacSesh",
            path: "Sources/MacSesh"
        ),
        .testTarget(
            name: "MacSeshTests",
            dependencies: ["MacSesh"],
            path: "Tests/MacSeshTests"
        ),
    ],
    swiftLanguageModes: [.v6]
)
