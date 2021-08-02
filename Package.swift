// swift-tools-version:5.2
import PackageDescription

let package = Package(
    name: "swift-distributed-tracing-baggage",
    products: [
        .library(
            name: "InstrumentationBaggage",
            targets: [
                "InstrumentationBaggage",
            ]
        ),
    ],
    targets: [
        .target(name: "InstrumentationBaggage"),

        // ==== --------------------------------------------------------------------------------------------------------
        // MARK: Tests

        .testTarget(
            name: "InstrumentationBaggageTests",
            dependencies: [
                .target(name: "InstrumentationBaggage"),
            ]
        ),
    ]
)
