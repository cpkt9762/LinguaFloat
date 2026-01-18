// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "LinguaFloat",
    defaultLocalization: "en",
    platforms: [
        .macOS(.v14)
    ],
    products: [
        .executable(name: "LinguaFloat", targets: ["LinguaFloat"])
    ],
    dependencies: [
        .package(url: "https://github.com/sindresorhus/KeyboardShortcuts", from: "2.0.0"),
        .package(url: "https://github.com/sparkle-project/Sparkle", from: "2.0.0")
    ],
    targets: [
        .executableTarget(
            name: "LinguaFloat",
            dependencies: [
                "KeyboardShortcuts",
                .product(name: "Sparkle", package: "Sparkle")
            ],
            path: "Sources"
        ),
        .testTarget(
            name: "LinguaFloatTests",
            dependencies: ["LinguaFloat"],
            path: "Tests/LinguaFloatTests"
        )
    ]
)
