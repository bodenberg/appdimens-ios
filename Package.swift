// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "AppDimensDynamic",
    defaultLocalization: "en",
    platforms: [.iOS(.v13), .macOS(.v10_15), .tvOS(.v13), .watchOS(.v6), .visionOS(.v1)],
    products: [
        .library(name: "AppDimens", targets: ["AppDimensCore", "AppDimensStrategies", "AppDimensUI"]),
        .library(name: "AppDimensCore", targets: ["AppDimensCore"]),
        .library(name: "AppDimensStrategies", targets: ["AppDimensStrategies"]),
        .library(name: "AppDimensUI", targets: ["AppDimensUI"])
    ],
    targets: [
        .target(name: "AppDimensCore"),
        .target(name: "AppDimensStrategies", dependencies: ["AppDimensCore"]),
        .target(name: "AppDimensUI", dependencies: ["AppDimensCore", "AppDimensStrategies"]),
        .testTarget(name: "AppDimensCoreTests", dependencies: ["AppDimensCore"]),
        .testTarget(name: "AppDimensStrategiesTests", dependencies: ["AppDimensCore", "AppDimensStrategies"])
    ]
)
