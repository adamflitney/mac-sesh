// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "MacSesh",
    platforms: [.macOS(.v14)],
    targets: [
        // Core logic — importable by both the app and the test suite
        .target(
            name: "MacSeshCore",
            path: "Sources/MacSeshCore"
        ),
        // App entry point
        .executableTarget(
            name: "MacSesh",
            dependencies: ["MacSeshCore"],
            path: "Sources/MacSesh"
        ),
        // Test suite: swift test
        .testTarget(
            name: "MacSeshTests",
            dependencies: ["MacSeshCore"],
            path: "Tests/MacSeshTests"
        ),
    ],
    swiftLanguageModes: [.v6]
)
