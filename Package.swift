// swift-tools-version: 5.7
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "EightSleepKit",
    platforms: [
        .iOS(.v13),
        .tvOS(.v13),
        .macOS(.v10_15),
        .watchOS(.v6)
    ],
    products: [
        .library(
            name: "EightSleepKit",
            targets: ["EightSleepKit"]),
        .executable(
            name: "eight-sleep-cli",
            targets: ["EightSleepCLI"]),
        .executable(
            name: "eight-sleep-cli-args",
            targets: ["EightSleepCLIArgs"])
    ],
    dependencies: [],
    targets: [
        .target(
            name: "EightSleepKit",
            dependencies: []),
        .executableTarget(
            name: "EightSleepCLI",
            dependencies: ["EightSleepKit"]),
        .executableTarget(
            name: "EightSleepCLIArgs",
            dependencies: ["EightSleepKit"]),
        .testTarget(
            name: "EightSleepKitTests",
            dependencies: ["EightSleepKit"]),
    ]
)