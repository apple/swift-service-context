// swift-tools-version:5.6

import PackageDescription

let package = Package(
    name: "swift-service-context",
    products: [
        .library(
            name: "ServiceContextModule",
            targets: [
                "ServiceContextModule",
            ]
        ),

        // Deprecated/legacy module
        .library(
            name: "InstrumentationBaggage",
            targets: [
                "InstrumentationBaggage",
            ]
        ),
    ],
    dependencies: [
        .package(url: "https://github.com/apple/swift-docc-plugin", from: "1.0.0"),
    ],
    targets: [
        .target(name: "ServiceContextModule"),

        // Deprecated/legacy module
        .target(
            name: "InstrumentationBaggage",
            dependencies: [
                .target(name: "ServiceContextModule"),
            ]
        ),

        // ==== --------------------------------------------------------------------------------------------------------
        // MARK: Tests

        .testTarget(
            name: "ServiceContextTests",
            dependencies: [
                .target(name: "ServiceContextModule"),
            ]
        ),
    ]
)
