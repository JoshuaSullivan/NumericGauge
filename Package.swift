// swift-tools-version: 5.10

import PackageDescription

let package = Package(
    name: "NumericGauge",
    platforms: [
        .iOS(.v15)
    ],
    products: [
        .library(
            name: "NumericGauge",
            targets: ["NumericGauge"]),
    ],
    dependencies: [
        .package(url: "https://github.com/JoshuaSullivan/TransientLabel.git", from: "0.0.1"),
    ],
    targets: [
        .target(name: "NumericGauge", dependencies: ["TransientLabel"]),
    ]
)
