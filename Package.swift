// swift-tools-version:6.2

import PackageDescription

let package = Package(
    name: "swift-service-context",
    products: [
        .library(
            name: "ServiceContextModule",
            targets: [
                "ServiceContextModuleCompatibility"
            ]
        ),

        // Deprecated/legacy module
        .library(
            name: "InstrumentationBaggage",
            targets: [
                "InstrumentationBaggage"
            ]
        ),
    ],
    dependencies: [
        .package(
            url: "https://github.com/apple/swift-distributed-tracing.git",
            from: "1.7.0"
        )
    ],
    targets: [
        // The `ServiceContextModule` module lives in swift-distributed-tracing, as part of its `Instrumentation`
        // product. Target names must be unique across the package graph. So this target has a different name and only
        // keeps the `ServiceContextModule` product of this package.
        .target(
            name: "ServiceContextModuleCompatibility",
            dependencies: [
                .product(name: "Instrumentation", package: "swift-distributed-tracing")
            ],
            path: "Sources/ServiceContextModule"
        ),

        // Deprecated/legacy module
        .target(
            name: "InstrumentationBaggage",
            dependencies: [
                .product(name: "Instrumentation", package: "swift-distributed-tracing")
            ]
        ),

        // ==== --------------------------------------------------------------------------------------------------------
        // MARK: Tests

        .testTarget(
            name: "ServiceContextTests",
            dependencies: [
                .target(name: "ServiceContextModuleCompatibility"),
                .product(name: "Instrumentation", package: "swift-distributed-tracing"),
            ]
        ),
    ]
)

for target in package.targets {
    var settings = target.swiftSettings ?? []
    settings.append(.enableExperimentalFeature("StrictConcurrency=complete"))
    target.swiftSettings = settings
}
