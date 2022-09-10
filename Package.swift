// swift-tools-version: 5.6

import PackageDescription

let package = Package(
    name: "LeapEdge",
    platforms: [
        .iOS(.v12),
        .macOS(.v12)
    ],
    products: [
        .library(
            name: "LeapEdge",
            targets: ["LeapEdge"]),
    ],
    dependencies: [
        .package(url: "https://github.com/daltoniam/Starscream.git", from: "4.0.0"),
        .package(url: "https://github.com/rishi8094/flexemit.git", from: "0.0.1")
    ],
    targets: [
        .target(
            name: "LeapEdge",
            dependencies: [
                .product(name: "Starscream", package: "Starscream"),
                .product(name: "FlexEmit", package: "FlexEmit")
            ]),
        .testTarget(
            name: "LeapEdgeTests",
            dependencies: ["LeapEdge"]),
    ]
)
