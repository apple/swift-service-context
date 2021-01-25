// swift-tools-version:5.0
import PackageDescription

let package = Package(
    name: "swift-distributed-tracing-baggage",
    products: [
        .library(
            name: "Baggage",
            targets: [
                "Baggage",
            ]
        ),
    ],
    dependencies: [
        .package(url: "https://github.com/apple/swift-log.git", from: "1.0.0"),
        .package(url: "https://github.com/apple/swift-distributed-tracing-baggage-core.git", from: "0.1.0"),
    ],
    targets: [
        .target(
            name: "Baggage",
            dependencies: [
                .product(name: "Logging", package: "swift-log"),
                .product(name: "CoreBaggage", package: "swift-distributed-tracing-baggage-core"),
            ]
        ),

        // ==== --------------------------------------------------------------------------------------------------------
        // MARK: Tests

        .testTarget(
            name: "BaggageTests",
            dependencies: [
                "Baggage",
            ]
        ),

        // ==== --------------------------------------------------------------------------------------------------------
        // MARK: Performance / Benchmarks

        .target(
            name: "BaggageBenchmarks",
            dependencies: [
                "Baggage",
                "BaggageBenchmarkTools",
            ]
        ),
        .target(
            name: "BaggageBenchmarkTools",
            dependencies: []
        ),
    ]
)
