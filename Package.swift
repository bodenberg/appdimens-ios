// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "AppDimens",
    platforms: [.iOS(.v15), .macOS(.v12), .tvOS(.v15), .watchOS(.v8)],
    products: [
        .library(name: "AppDimens", targets: ["AppDimens"]),
        .library(name: "AppDimensUI", targets: ["AppDimensUI"])
    ],
    targets: [
        .target(name: "AppDimens"),
        .target(name: "AppDimensUI", dependencies: ["AppDimens"]),
        .testTarget(name: "AppDimensTests", dependencies: ["AppDimens"])
    ]
)
