// swift-tools-version:5.4
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "ConfigurationCodable",
    platforms: [.macOS(.v10_10), .iOS(.v9), .tvOS(.v9), .watchOS(.v2)],
    products: [
        .library(
            name: "ConfigurationCodable",
            targets: ["ConfigurationCodable"])
    ],
    dependencies: [],
    targets: [
        .target(
            name: "ConfigurationCodable",
            dependencies: []),
        .testTarget(
            name: "ConfigurationCodableTests",
            dependencies: ["ConfigurationCodable"])
    ]
)
