// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "AppDimensDynamic",
    platforms: [.iOS(.v13), .macOS(.v10_15), .tvOS(.v13), .watchOS(.v7), .visionOS(.v1)],
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
        .target(name: "AppDimensDensity", dependencies: ["AppDimens", "AppDimensStrategies"]),
        .target(name: "AppDimensDiagonal", dependencies: ["AppDimens", "AppDimensStrategies"]),
        .target(name: "AppDimensFill", dependencies: ["AppDimens", "AppDimensStrategies"]),
        .target(name: "AppDimensFit", dependencies: ["AppDimens", "AppDimensStrategies"]),
        .target(name: "AppDimensFluid", dependencies: ["AppDimens", "AppDimensStrategies"]),
        .target(name: "AppDimensInterpolated", dependencies: ["AppDimens", "AppDimensStrategies"]),
        .target(name: "AppDimensLogarithmic", dependencies: ["AppDimens", "AppDimensStrategies"]),
        .target(name: "AppDimensPercent", dependencies: ["AppDimens", "AppDimensStrategies"]),
        .target(name: "AppDimensPerimeter", dependencies: ["AppDimens", "AppDimensStrategies"]),
        .target(name: "AppDimensPower", dependencies: ["AppDimens", "AppDimensStrategies"]),
        .target(name: "AppDimensAuto", dependencies: ["AppDimens"]),
        .target(name: "AppDimensResize", dependencies: ["AppDimens"]),
        .target(name: "AppDimensUnits", dependencies: ["AppDimens"]),
        .target(name: "AppDimensMetal", dependencies: ["AppDimens", "AppDimensStrategies"]),
        .target(name: "AppDimensDynamic", dependencies: ["AppDimens", "AppDimensStrategies", "AppDimensAuto", "AppDimensResize", "AppDimensUnits", "AppDimensMetal"]),
        .testTarget(name: "AppDimensTests", dependencies: ["AppDimensDynamic", "AppDimens", "AppDimensStrategies",
            "AppDimensAuto", "AppDimensResize", "AppDimensUnits", "AppDimensPercent", "AppDimensPower",
            "AppDimensFluid", "AppDimensDensity", "AppDimensDiagonal", "AppDimensFill", "AppDimensFit",
            "AppDimensInterpolated", "AppDimensLogarithmic", "AppDimensPerimeter"])
    ]
)
