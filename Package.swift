// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "AppDimensDynamic",
    platforms: [.iOS(.v13), .macOS(.v10_15), .tvOS(.v13), .watchOS(.v6), .visionOS(.v1)],
    products: [.library(name: "AppDimens", targets: ["AppDimens"])],
    targets: [
        .target(name: "AppDimens"),
        .testTarget(name: "AppDimensTests", dependencies: ["AppDimens"])
    ]
)
