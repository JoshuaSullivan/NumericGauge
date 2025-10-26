// swift-tools-version: 6.0

import PackageDescription

let package = Package(
    name: "NumericGauge",
    platforms: [
        .iOS(.v15),
        .visionOS(.v1)
    ],
    products: [
        .library(
            name: "NumericGauge",
            targets: ["NumericGauge"]),
    ],
    dependencies: [
        .package(url: "https://github.com/JoshuaSullivan/TransientLabel.git", from: "1.0.0"),
    ],
    targets: [
        .target(name: "NumericGauge", dependencies: ["TransientLabel"]),
        .testTarget(
            name: "NumericGaugeTests",
            dependencies: ["NumericGauge"]
        ),
    ]
)
