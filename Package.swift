// swift-tools-version: 6.0

import PackageDescription

let package = Package(
    name: "NumericGauge",
    platforms: [
        .iOS(.v15),
        .visionOS(.v1),
        // macOS builds the module empty (see the guard atop each source):
        // the Mac uses system controls rather than this touch-first gauge.
        .macOS(.v14)
    ],
    products: [
        .library(
            name: "NumericGauge",
            targets: ["NumericGauge"]),
    ],
    dependencies: [
        .package(path: "../TransientLabel"),
    ],
    targets: [
        .target(name: "NumericGauge", dependencies: ["TransientLabel"]),
        .testTarget(
            name: "NumericGaugeTests",
            dependencies: ["NumericGauge"]
        ),
    ]
)
