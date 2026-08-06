// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "AppDimensDynamic",
    platforms: [.iOS(.v13), .macOS(.v10_15), .tvOS(.v13), .visionOS(.v1)],
    products: [
        .library(name: "AppDimens", targets: ["AppDimens"]),
        .library(name: "AppDimensDynamic", targets: ["AppDimensDynamic"]),
        .library(name: "AppDimensAuto", targets: ["AppDimensAuto"]),
        .library(name: "AppDimensStrategies", targets: ["AppDimensStrategies"]),
        .library(name: "AppDimensDensity", targets: ["AppDimensDensity"]),
        .library(name: "AppDimensDiagonal", targets: ["AppDimensDiagonal"]),
        .library(name: "AppDimensFill", targets: ["AppDimensFill"]),
        .library(name: "AppDimensFit", targets: ["AppDimensFit"]),
        .library(name: "AppDimensFluid", targets: ["AppDimensFluid"]),
        .library(name: "AppDimensInterpolated", targets: ["AppDimensInterpolated"]),
        .library(name: "AppDimensLogarithmic", targets: ["AppDimensLogarithmic"]),
        .library(name: "AppDimensPercent", targets: ["AppDimensPercent"]),
        .library(name: "AppDimensPerimeter", targets: ["AppDimensPerimeter"]),
        .library(name: "AppDimensPower", targets: ["AppDimensPower"]),
        .library(name: "AppDimensResize", targets: ["AppDimensResize"]),
        .library(name: "AppDimensUnits", targets: ["AppDimensUnits"]),
        .library(name: "AppDimensMetal", targets: ["AppDimensMetal"])
    ],
    targets: [
        .target(name: "AppDimens"),
        .target(name: "AppDimensStrategies", dependencies: ["AppDimens"]),
        .target(name: "AppDimensDensity", dependencies: ["AppDimensStrategies"]),
        .target(name: "AppDimensDiagonal", dependencies: ["AppDimensStrategies"]),
        .target(name: "AppDimensFill", dependencies: ["AppDimensStrategies"]),
        .target(name: "AppDimensFit", dependencies: ["AppDimensStrategies"]),
        .target(name: "AppDimensFluid", dependencies: ["AppDimensStrategies"]),
        .target(name: "AppDimensInterpolated", dependencies: ["AppDimensStrategies"]),
        .target(name: "AppDimensLogarithmic", dependencies: ["AppDimensStrategies"]),
        .target(name: "AppDimensPercent", dependencies: ["AppDimensStrategies"]),
        .target(name: "AppDimensPerimeter", dependencies: ["AppDimensStrategies"]),
        .target(name: "AppDimensPower", dependencies: ["AppDimensStrategies"]),
        .target(name: "AppDimensAuto", dependencies: ["AppDimens"]),
        .target(name: "AppDimensResize", dependencies: ["AppDimens"]),
        .target(name: "AppDimensUnits", dependencies: ["AppDimens"]),
        .target(name: "AppDimensMetal", dependencies: ["AppDimens", "AppDimensStrategies"]),
        .target(name: "AppDimensDynamic", dependencies: ["AppDimens", "AppDimensStrategies", "AppDimensAuto", "AppDimensResize", "AppDimensUnits", "AppDimensMetal"]),
        .testTarget(name: "AppDimensTests", dependencies: ["AppDimensDynamic"])
    ]
)
