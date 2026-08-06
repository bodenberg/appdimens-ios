# AppDimens Dynamic for Apple — principal library

<p align="center">
  <a href="https://github.com/bodenberg/appdimens-ios/actions/workflows/ci.yml"><img alt="Swift Package CI" src="https://img.shields.io/github/actions/workflow/status/bodenberg/appdimens-ios/ci.yml?branch=main&amp;style=for-the-badge&amp;logo=swift"></a>
  <a href="LICENSE"><img alt="License" src="https://img.shields.io/badge/license-Apache--2.0-6f42c1?style=for-the-badge"></a>
  <img alt="Apple platforms" src="https://img.shields.io/badge/Apple-iOS%20%7C%20macOS%20%7C%20tvOS%20%7C%20watchOS%20%7C%20visionOS-111?style=for-the-badge&amp;logo=apple">
</p>

<p align="center"><strong>Responsive points and Dynamic Type for SwiftUI and UIKit, directly inspired by AppDimens Dynamic for Android.</strong></p>

<p align="center">
<a href="#installation">Install</a> · <a href="#swiftui--automatic-window-metrics">SwiftUI</a> · <a href="#uikit--automatic-window-metrics">UIKit</a> · <a href="#strategies">Strategies</a> · <a href="Documentation/README.md">Full documentation</a> · <a href="GUIDE-FOR-BEGINNERS.md">Beginner guide</a>
</p>

> [!IMPORTANT]
> AppDimens reads one active window/scene configuration. Child view bounds never redefine `sdp`, so the same value remains consistent throughout a window.


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

The engine is stateless, allocation-free and `@inlinable` on calculation paths. Configuration is captured once at the SwiftUI root or resolved from the UIKit window; it is not read from every child view. No global dictionary, lock, notification observer or per-value cache is required for an O(1) multiplication. SwiftUI's `Hashable` environment value invalidates consumers only when window metrics actually change; install exactly one provider. For a render loop, create `DimensFactors` once per changed configuration and call `resolve(_:strategy:)` to reuse its ratios.

> [!NOTE]
> watchOS supports the deterministic core, strategies, units, resize and aggregate imports. The window-level SwiftUI provider is excluded, and the Metal satellite becomes an empty compatibility module because those contracts are unavailable on the package's watchOS 6 target.

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

Individual strategy products reexport the shared strategy API, so applications can express intent in their dependency graph while using the same tested engine.

## Product selection

| Need | Product | Import |
|---|---|---|
| Complete library | `AppDimensDynamic` | `import AppDimensDynamic` |
| Principal scaled/plain API | `AppDimens` | `import AppDimens` |
| Adaptive conditions | `AppDimensAuto` | `import AppDimensAuto` |
| All mathematical curves | `AppDimensStrategies` | `import AppDimensStrategies` |
| One curve only | corresponding product | e.g. `import AppDimensPower` |
| Auto-resize math | `AppDimensResize` | `import AppDimensResize` |
| Physical units | `AppDimensUnits` | `import AppDimensUnits` |
| GPU uniforms | `AppDimensMetal` | `import AppDimensMetal` |

Individual strategy products reexport the shared strategy API, so applications can express intent in their dependency graph while using the same tested engine.

## Complete SwiftUI example

```swift
import SwiftUI
import AppDimensDynamic

@main
struct AppDimensDemo: App {
    var body: some Scene {
        WindowGroup {
            Dashboard()
                .appDimens() // exactly once per scene
        }
    }
}

struct Dashboard: View {
    @ScaledDimension(16) private var spacing
    @ScaledDimension(12, aspectRatio: true) private var radius
    @ScaledDimension(text: 17) private var bodyText
    @Environment(\.appDimensConfiguration) private var configuration

    var body: some View {
        let cardWidth = 320.fitDp(configuration)
        let horizontalInset = 100.percentDp(
            configuration,
            percent: 4,
            qualifier: .width
        )

        ScrollView {
            VStack(spacing: spacing) {
                Text("Dashboard")
                    .font(.system(size: bodyText, weight: .bold))

                RoundedRectangle(cornerRadius: radius)
                    .frame(width: cardWidth, height: 180)
            }
            .padding(.horizontal, horizontalInset)
        }
    }
}
```

### Why a root provider?

Android Compose reads `LocalConfiguration`, a shared window configuration. SwiftUI has no identical public value containing every required metric, so `.appDimens()` creates the equivalent at the scene root. It does not require dimensions from the caller and does not inspect each child view.

## Complete UIKit example

```swift
import UIKit
import AppDimensDynamic

final class CardViewController: UIViewController {
    private let card = UIView()
    private let titleLabel = UILabel()

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()

        let configuration = DimensConfiguration.current(in: view)
        let inset = CGFloat(16.sdp(configuration))
        let radius = CGFloat(12.sdpa(configuration))

        card.layer.cornerRadius = radius
        card.directionalLayoutMargins = .init(
            top: inset,
            leading: inset,
            bottom: inset,
            trailing: inset
        )

        titleLabel.font = .systemFont(
            ofSize: CGFloat(17.ssp(configuration))
        )
    }
}
```

`current(in:)` is main-actor isolated because UIKit scene and trait access must occur on the main thread.

## Principal formulas

For base value `v`, selected window axis `d`, baseline `b = 300`, aspect ratio `ar`, and reference ratio `1.78`:

```text
scaled = v × d / 300
aspect = v × [1 + (d - 300) × (1/300 + k × ln(ar/1.78)/300)]
ssp    = scaled × DynamicTypeScale
sem    = scaled
```

Apple layouts use points, the conceptual equivalent of Android dp. Pixel conversion is explicit and never silently applied to a SwiftUI frame.

## Auto examples

### Width qualifier

```swift
let spacing = 16.autoScaledDp
    .qualifier(20, .width, minimum: 600)
    .qualifier(24, .width, minimum: 900)
    .resolve(configuration)
```

### Combined screen condition

```swift
let televisionTitle = 24.autoScaledDp
    .screen(42, condition: .init(
        mode: .television,
        orientation: .landscape,
        qualifier: .width,
        minimum: 1280
    ))
    .resolve(configuration)
```

### Adaptive text

```swift
let title = 20.autoSp
    .screen(28, condition: .init(qualifier: .width, minimum: 700))
    .resolve(configuration)
```

Conditions are ranked deterministically by specificity, threshold, and declaration order.

## Strategy examples

### Diagonal and perimeter

```swift
let twoDimensional = 24.diagonalDp(configuration)
let balanced = 24.perimeterDp(configuration)
```

### Fit versus fill

```swift
let fullyVisible = 320.fitDp(configuration)
let coversViewport = 320.fillDp(configuration)
```

`fit` takes the smaller width/height ratio. `fill` takes the larger ratio.

### Fluid

```swift
let gap = 16.fluidDp(configuration, options: .init(
    qualifier: .width,
    fluidViewport: 320...1200,
    fluidScale: 0.85...1.4
))
```

The result is clamped below and above the configured viewport range.

### Interpolated

```swift
let subtle = 16.interpolatedDp(configuration, options: .init(
    interpolation: 0.25
))
```

An interpolation of `0` is fixed; `1` is linear; intermediate values damp scaling.

### Power and logarithmic

```swift
let perceptual = 24.powerDp(configuration, options: .init(power: 0.75))
let damped = 24.logarithmicDp(configuration)
```

These are useful on large iPad, Mac, television, and visionOS windows where linear growth may be excessive.

### Percent

```swift
let halfWidth = 100.percentDp(
    configuration,
    percent: 50,
    qualifier: .width
)
```

With a base value of `100`, this returns the literal percentage of the selected axis.

## Resize example

```swift
let candidates = DimensResize.steps(
    minimum: ResizeBound.fixedSp(12).points(configuration),
    maximum: ResizeBound.percent(12, .width).points(configuration),
    step: 1
)

let fontSize = DimensResize.largestFitting(candidates) { candidate in
    measuredTextWidth(fontSize: candidate) <= availableWidth
}
```

The fitting predicate must transition monotonically from true to false.

## Physical unit examples

```swift
let tenMillimeters = DimensUnits.points(
    10,
    from: .millimeter,
    configuration: configuration
)

let oneInchOnKnownHardware = DimensUnits.pixels(
    1,
    from: .inch,
    configuration: configuration,
    pixelsPerInch: 460
)
```

`UIScreen.scale`/`displayScale` means pixels per point, not physical pixels per inch. Pass PPI only when the application has a reliable hardware mapping.

## Metal usage

```swift
import Metal
import AppDimensMetal

let uniforms = AppDimensUniforms(configuration)
precondition(MemoryLayout<AppDimensUniforms>.stride == 64)
let buffer = AppDimensMetal.makeBuffer(
    device: device,
    configuration: configuration
)!
```

Matching Metal Shading Language declaration:

```metal
struct AppDimensUniforms {
    float4 viewport;
    float4 ratios;
    float4 display;
    float4 reserved;
};
```

Retain the buffer. Call `update` only after window, display, orientation, or Dynamic Type changes.

## Android → Apple migration

| Android | Apple port |
|---|---|
| `Configuration` | `DimensConfiguration` |
| `LocalConfiguration.current` | environment installed by `.appDimens()` |
| `16.sdp` | `@ScaledDimension(16)` or `16.sdp(configuration)` |
| `16.ssp` | `@ScaledDimension(text: 16)` |
| `DpQualifier.SMALL_WIDTH` | `.smallWidth` |
| `Inverter.SW_TO_LW` | `.swToLw` |
| Maven principal artifact | `AppDimens` product |
| Maven satellite artifact | corresponding SwiftPM product |
| BOM/all dependencies | `AppDimensDynamic` product |

## Correctness rules

1. Install one SwiftUI provider per scene, at the root.
2. Never create a new principal configuration from a card or child view.
3. In UIKit, pass any descendant only to locate its window; the implementation uses window bounds.
4. Use percent/fit/fill when local proportional behavior is explicitly wanted.
5. Treat points and pixels as different units.
6. Re-resolve after window configuration changes.
7. Keep Metal buffer allocation outside the frame loop.

## Troubleshooting

### Values remain at the 300-point baseline

The SwiftUI tree probably lacks `.appDimens()` at its scene root. Install the provider once above every consumer.

### UIKit values differ between windows

That is expected: each `UIWindowScene` is an independent Android-Configuration equivalent. Values must remain identical only inside the same window.

### A view should scale relative to its own bounds

Do not replace the principal configuration. Use an explicit percent, fit, or fill calculation for that container-specific requirement.

### Text is scaled twice

Do not combine a pre-scaled `ssp` point size with another `UIFontMetrics` scaling pass unless double scaling is intentional. Prefer one Dynamic Type path.

### Physical size is inaccurate

Provide verified PPI. Display scale alone cannot determine physical dimensions.

## Documentation

- [Documentation hub](Documentation/README.md)
- [Beginner guide](GUIDE-FOR-BEGINNERS.md)
- [Complete API reference](Documentation/API.md)
- [Strategy catalog and individual guides](Documentation/STRATEGIES.md)
- [Mathematics and calculus](Documentation/MATHEMATICS-AND-CALCULUS.md)
- [SwiftUI and UIKit integration](Documentation/APPLE-INTEGRATION.md)
- [Android migration map](Documentation/MIGRATION.md)
- [Performance and recomposition](Documentation/PERFORMANCE.md)
- [Troubleshooting](Documentation/TROUBLESHOOTING.md)
- [Complete module matrix](Documentation/MODULES.md)
- [Principal parity audit](Documentation/PRINCIPAL-PARITY.md)
- [Codex usage skill](skills/appdimens-ios/SKILL.md)
- [Contributing guide](CONTRIBUTING.md)
- [Security policy](SECURITY.md)

## Validation commands

```bash
swift package dump-package
swift package describe
swift test --parallel
swift test --sanitize=thread
swift build -c release
```

The GitHub workflow additionally builds `AppDimensDynamic` against iOS, tvOS, visionOS, and macOS SDKs without code signing.
