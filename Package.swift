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
        // Run with: swift run MacSeshTests
        // (swift test requires full Xcode install; this runner works with CLT)
        .executableTarget(
            name: "MacSeshTests",
            dependencies: ["MacSesh"],
            path: "Tests/MacSeshTests"
        ),
    ],
    swiftLanguageModes: [.v6]
)
