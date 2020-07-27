// swift-tools-version:5.2
import PackageDescription

let package = Package(
    name: "swift-baggage-context",
    products: [
        .library(name: "Baggage", targets: ["Baggage"])
    ],
    targets: [
        .target(
            name: "Baggage",
            dependencies: []
        ),

        // ==== --------------------------------------------------------------------------------------------------------
        // MARK: Tests

        .testTarget(
            name: "BaggageTests",
            dependencies: [
                "Baggage"
            ]
        ),

        // ==== --------------------------------------------------------------------------------------------------------
        // MARK: Performance / Benchmarks

        .target(
            name: "Benchmarks",
            dependencies: [
                "Baggage",
                "SwiftBenchmarkTools",
            ]
        ),
        .target(
            name: "SwiftBenchmarkTools",
            dependencies: []
        ),
    ]
)
