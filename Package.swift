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
        .testTarget(
            name: "BaggageTests",
            dependencies: [
                "Baggage"
            ]
        )
    ]
)
