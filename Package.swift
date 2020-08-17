// swift-tools-version:5.0
import PackageDescription

let package = Package(
    name: "swift-baggage-context",
    products: [
        .library(name: "Baggage",
            targets: [
                "Baggage"
            ]
        ),
        .library(name: "BaggageLogging",
            targets: [
                "BaggageLogging"
            ]
        ),
    ],
    dependencies: [
        .package(url: "https://github.com/apple/swift-log.git", from: "1.3.0")
    ],
    targets: [

        .target(
            name: "Baggage",
            dependencies: []
        ),

        .target(
            name: "BaggageLogging",
            dependencies: [
                "Baggage",
                .product(name: "Logging", package: "swift-log"),
            ]
        ),

        // ==== --------------------------------------------------------------------------------------------------------
        // MARK: Tests

        .testTarget(
            name: "BaggageTests",
            dependencies: [
                "Baggage"
            ]
        ),

        .testTarget(
            name: "BaggageLoggingTests",
            dependencies: [
                "Baggage",
                "BaggageLogging"
            ]
        ),

        // ==== --------------------------------------------------------------------------------------------------------
        // MARK: Performance / Benchmarks

        .target(
            name: "Benchmarks",
            dependencies: [
                "Baggage",
                "BaggageLogging",
                "SwiftBenchmarkTools",
]
        ),
        .target(
            name: "SwiftBenchmarkTools",
            dependencies: []
        ),
    ]
)
