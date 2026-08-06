# AppDimens Dynamic for Apple — principal library

Complete modular Apple port of **AppDimens Dynamic**: the principal artifact, all thirteen Android satellite artifacts, an aggregate module, and the Apple-specific Metal bridge.

## Contract

` sdp / wdp / hdp ` always use the current **window/scene configuration**, exactly as Android uses `Configuration`/`LocalConfiguration`. A child view never becomes a new scaling reference. Container-relative sizing is not mixed with these APIs.

Baseline: `300` points, reference aspect ratio: `1.78`.

## Installation

In Xcode choose **File › Add Package Dependencies…** and enter:

```text
https://github.com/bodenberg/appdimens-ios
```

Select `AppDimensDynamic` for everything, `AppDimens` for the principal artifact, or an individual satellite product. With SwiftPM:

```swift
.package(url: "https://github.com/bodenberg/appdimens-ios", branch: "main")
// .product(name: "AppDimens", package: "appdimens-ios")
```

## SwiftUI — automatic window metrics

Install once at the `WindowGroup` root. No width, height, display scale, font scale or device mode is passed by the app:

```swift
import SwiftUI
import AppDimens

@main
struct ExampleApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView().appDimens()
        }
    }
}

struct ContentView: View {
    @ScaledDimension(16) private var spacing
    @ScaledDimension(100, .width) private var width
    @ScaledDimension(text: 16) private var textSize

    var body: some View {
        VStack(spacing: spacing) {
            Text("AppDimens").font(.system(size: textSize))
        }.frame(width: width)
    }
}
```

The provider observes the root window container plus SwiftUI `displayScale` and `sizeCategory`. All descendants share one `DimensConfiguration`.

## UIKit — automatic window metrics

```swift
import UIKit
import AppDimens

@MainActor
func configure(view: UIView) {
    view.layer.cornerRadius = 10.sdp(in: view)
    let width = 100.wdp(in: view)
}
```

The view is used only to locate its `UIWindowScene`; its own bounds never affect `sdp`, `wdp` or `hdp`. Two child views in the same window therefore resolve identical values.

## Deterministic/headless use

Explicit configuration remains available for tests and non-UI code:

```swift
let configuration = DimensConfiguration(screenWidth: 390, screenHeight: 844)
let spacing = 10.sdp(configuration) // 13
```

## Principal scaled API

| Android | Swift deterministic | SwiftUI |
|---|---|---|
| `16.sdp` | `16.sdp(configuration)` | `@ScaledDimension(16)` |
| `100.wdp` | `100.wdp(configuration)` | `@ScaledDimension(100, .width)` |
| `48.hdp` | `48.hdp(configuration)` | `@ScaledDimension(48, .height)` |
| `16.ssp` | `16.ssp(configuration)` | `@ScaledDimension(text: 16)` |
| `16.hsp` | `16.hsp(configuration)` | `@ScaledDimension(text: 16, .height)` |
| `16.wsp` | `16.wsp(configuration)` | `@ScaledDimension(text: 16, .width)` |
| `16.sem` | `16.sem(configuration)` | `@ScaledDimension(text: 16, fontScale: false)` |
| suffix `a` | `sdpa` / `aspectRatio: true` | `aspectRatio: true` |
| suffix `i` | `sdpi` / `ignoreMultiWindow: true` | `ignoreMultiWindow: true` |
| suffix `ia` | `sdpia` | both flags |

## Qualifiers and inverters

`DpQualifier` ports `SMALL_WIDTH`, `HEIGHT`, and `WIDTH`. All eight principal inverter mappings are present: `phToLw`, `pwToLh`, `lhToPw`, `lwToPh`, `swToLh`, `swToLw`, `swToPh`, and `swToPw`.

```swift
let value = AppDimens.dp(16, configuration: configuration,
    qualifier: .smallWidth, inverter: .swToLw)
```

## Facilitators and builder

```swift
let responsive = AppDimens.qualified(16, qualifiedValue: 24,
    configuration: configuration, qualifier: .width, minimum: 600)

let rotated = AppDimens.rotate(16, rotationValue: 12,
    configuration: configuration, orientation: .landscape)

let built = 16.scaledDp
    .screen(24, qualifier: .width, minimum: 600)
    .rotate(12, .landscape)
    .aspectRatio()
    .resolve(configuration)
```

## Performance

The engine is stateless, allocation-free and `@inlinable` on calculation paths. Configuration is captured once at the SwiftUI root or resolved from the UIKit window; it is not read from every child view. No global dictionary, lock, notification observer or per-value cache is required for an O(1) multiplication.

## Complete module installation

```swift
import AppDimensDynamic // every module
// or import AppDimens, AppDimensAuto, AppDimensPercent, etc.
```

The package provides `AppDimens`, `AppDimensAuto`, `AppDimensDensity`, `AppDimensDiagonal`, `AppDimensFill`, `AppDimensFit`, `AppDimensFluid`, `AppDimensInterpolated`, `AppDimensLogarithmic`, `AppDimensPercent`, `AppDimensPerimeter`, `AppDimensPower`, `AppDimensResize`, `AppDimensUnits`, `AppDimensMetal`, and the aggregate `AppDimensDynamic`.

## Strategies

```swift
let power = 16.powerDp(configuration)
let fluid = 16.fluidDp(configuration)
let halfWidth = 100.percentDp(configuration, percent: 50, qualifier: .width)
let any = 16.dynamic(.diagonal, configuration)
```

All strategies accept `StrategyOptions` for qualifier, inverter, aspect ratio, multi-window, sensitivity, percent, power, interpolation, and fluid ranges.

## Auto

```swift
let value = 16.autoScaledDp
    .qualifier(24, .width, minimum: 600)
    .rotate(14, .landscape)
    .mode(28, .television)
    .resolve(configuration)
```

## Resize and units

```swift
let steps = DimensResize.steps(minimum: 12, maximum: 48, step: 1)
let fitted = DimensResize.largestFitting(steps) { measure($0) <= available }
let millimeters = DimensUnits.points(10, from: .millimeter, configuration: configuration)
```

## Metal

`AppDimensUniforms` is a fixed 64-byte CPU/GPU ABI. Create one shared `MTLBuffer` and update it only when the window configuration changes.

See [the complete module matrix](Documentation/MODULES.md) and [principal parity audit](Documentation/PRINCIPAL-PARITY.md).
