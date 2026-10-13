// swift-tools-version:6.2

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
        //        .package(
        //            url: "https://github.com/apple/swift-distributed-tracing.git",
        //            from: "1.7.0"
        //        )
        .package(
            url: "https://github.com/kukushechkin/swift-distributed-tracing.git",
            branch: "add-ServiceContextModule-compatibility-module"
        )
    ],
    targets: [
        .target(
            name: "ServiceContextModule",
            dependencies: [
                // The `Instrumentation` product of swift-distributed-tracing also contains a module named
                // `ServiceContextModule`. Target names must be unique across the package graph. The alias renames that
                // module in every build that contains this package. The module of this target keeps the name.
                .product(
                    name: "Instrumentation",
                    package: "swift-distributed-tracing",
                    moduleAliases: ["ServiceContextModule": "SDTServiceContextModule"]
                )
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
