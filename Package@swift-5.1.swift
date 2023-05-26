// swift-tools-version:5.1
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
