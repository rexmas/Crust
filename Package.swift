// swift-tools-version:5.0
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "Crust",
    products: [
        .library(
            name: "Crust",
            targets: ["Crust"]),
    ],
    dependencies: [
        .package(url: "https://github.com/rexmas/JSONValue.git", .upToNextMinor(from: "5.0.0"))
    ],
    targets: [
        // Targets are the basic building blocks of a package. A target can define a module or a test suite.
        // Targets can depend on other targets in this package, and on products in packages which this package depends on.
        .target(
            name: "Crust",
            dependencies: ["JSONValueRX"],
            path: "./Crust"),
        .testTarget(
            name: "CrustTests",
            dependencies: ["Crust"],
            path: "./CrustTests"),
    ]
)
