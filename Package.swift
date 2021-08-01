// swift-tools-version:5.2
import PackageDescription

let package = Package(
    name: "swift-distributed-tracing-baggage",
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
