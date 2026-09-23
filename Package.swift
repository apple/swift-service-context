// swift-tools-version:6.1

import PackageDescription

let package = Package(
    name: "swift-service-context",
    products: [
        .library(
            name: "ServiceContextModule",
            targets: [
                "ServiceContextModule"
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
            url: "https://github.com/kukushechkin/swift-distributed-tracing.git",
            branch: "move-service-context-to-sdt"
        )
    ],
    targets: [
        .target(
            name: "ServiceContextModule",
            dependencies: [
                .product(name: "ContextStorage", package: "swift-distributed-tracing")
            ]
        ),

        // Deprecated/legacy module
        .target(
            name: "InstrumentationBaggage",
            dependencies: [
                .target(name: "ServiceContextModule")
            ]
        ),

        // ==== --------------------------------------------------------------------------------------------------------
        // MARK: Tests

        .testTarget(
            name: "ServiceContextTests",
            dependencies: [
                .target(name: "ServiceContextModule")
            ]
        ),
    ]
)

for target in package.targets {
    var settings = target.swiftSettings ?? []
    settings.append(.enableExperimentalFeature("StrictConcurrency=complete"))
    target.swiftSettings = settings
}
