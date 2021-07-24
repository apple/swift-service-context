// swift-tools-version:5.5
import PackageDescription

let package = Package(
    name: "swift-distributed-tracing-baggage",
    platforms: [
        .macOS(.v12),
        .iOS(.v15),
        .watchOS(.v8),
        .tvOS(.v15),
    ],
    products: [
        .library(
            name: "BaggageModule",
            targets: [
                "BaggageModule",
            ]
        ),
    ],
    targets: [
        .target(name: "BaggageModule"),

        // ==== --------------------------------------------------------------------------------------------------------
        // MARK: Tests

        .testTarget(
            name: "BaggageModuleTests",
            dependencies: [
                .target(name: "BaggageModule"),
            ]
        ),
    ]
)
