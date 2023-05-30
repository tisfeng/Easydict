// swift-tools-version: 5.8
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "Easydict",
    products: [
        // Products define the executables and libraries a package produces, making them visible to other packages.
        .library(
            name: "Easydict",
            targets: ["Easydict"]),
    ],
    // name, platforms, products, etc.
    dependencies: [
        // other dependencies
        .package(url: "https://github.com/apple/swift-argument-parser", from: "1.2.0"),
    ],
    targets: [
        // Targets are the basic building blocks of a package, defining a module or a test suite.
        // Targets can depend on other targets in this package and products from dependencies.
        .target(
            name: "Easydict"),
        .testTarget(
            name: "EasydictTests",
            dependencies: ["Easydict"]),
        .executableTarget(name: "easydict", dependencies: [
            // other dependencies
            .product(name: "ArgumentParser", package: "swift-argument-parser"),
        ]),
    ]
)
