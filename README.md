# AppDimens Dynamic for Apple

<p align="center">
  <a href="https://github.com/bodenberg/appdimens-ios/actions/workflows/ci.yml"><img alt="Swift Package CI" src="https://img.shields.io/github/actions/workflow/status/bodenberg/appdimens-ios/ci.yml?branch=main&amp;style=for-the-badge&amp;logo=swift"></a>
  <img alt="Version 3.2.0" src="https://img.shields.io/badge/version-3.2.0-6f42c1?style=for-the-badge">
  <a href="LICENSE"><img alt="License" src="https://img.shields.io/badge/license-Apache--2.0-6f42c1?style=for-the-badge"></a>
  <img alt="Apple platforms" src="https://img.shields.io/badge/Apple-iOS%20%7C%20macOS%20%7C%20tvOS%20%7C%20watchOS%20%7C%20visionOS-111?style=for-the-badge&amp;logo=apple">
</p>

<p align="center"><strong>Responsive points and text for Swift, SwiftUI, UIKit, AppKit and Metal — the Apple port of <a href="https://github.com/bodenberg/appdimens-dynamic">AppDimens Dynamic for Android</a>, with the same names, the same formulas and the same usage.</strong></p>

<p align="center">
<a href="#installation">Install</a> · <a href="#quick-start--swiftui">SwiftUI</a> · <a href="#uikit--appkit">UIKit / AppKit</a> · <a href="#metal">Metal</a> · <a href="#strategies">Strategies</a> · <a href="Documentation/README.md">Documentation</a> · <a href="GUIDE-FOR-BEGINNERS.md">Beginner guide</a>
</p>

Write `16.sdp` and the value scales with the current **window** — exactly like `16.sdp` in Jetpack Compose:

```swift
Text("Hello")
    .font(.system(size: 16.ssp))
    .padding(16.sdp)
    .frame(width: 100.wdp, height: 48.hdp)
```

| Android (Compose) | Apple (SwiftUI / UIKit) | Meaning |
|---|---|---|
| `16.sdp` → `Dp` | `16.sdp` → `CGFloat` | smallest window side / 300 |
| `16.hdp`, `16.wdp` | `16.hdp`, `16.wdp` | window height / width |
| `16.ssp`, `16.sem` | `16.ssp`, `16.sem` | text with / without Dynamic Type |
| `16.sdp(context)` → px | `16.sdp(configuration)` → points | explicit window (tests, background work) |
| `16.sdpPx` | `16.sdpPx` | pixels (`points × displayScale`) |
| suffixes `a`, `i`, `ia` | `16.sdpa`, `16.sdpi`, `16.sdpia` | aspect ratio, ignore multi-window |
| `32.sdpPh`, `50.hdpLw` … | `32.sdpPh`, `50.hdpLw` … | orientation inverters |
| `80.sdpRotate(50)` | `80.sdpRotate(50)` | facilitators: `Rotate`, `Mode`, `Qualifier`, `Screen` (+`Px`, `Plain`) |
| `16.scaledDp().screen(…)` | `16.scaledDp().screen(…)` | conditional builder, same priority rules |
| `16.pwsdp`, `16.asdp`, `16.fsdp` … | identical | every satellite strategy |
| `AppDimensProvider { }` | `AppDimensProvider { }` / `.appDimens()` | per-window provider |
| `LocalConfiguration` | `@Environment(\.appDimensConfiguration)` | window snapshot |

The design baseline is **300 × 533 points** (Android's 300 × 533 dp). Results are bit-for-bit the Android formulas, computed in `Double` (the test suite cross-checks every factor against the Kotlin `Float` implementation).

---

## Installation

Xcode: **File › Add Package Dependencies…** → `https://github.com/bodenberg/appdimens-ios`.

```swift
// Package.swift
.package(url: "https://github.com/bodenberg/appdimens-ios", from: "3.2.0")

.target(name: "App", dependencies: [
    .product(name: "AppDimensDynamic", package: "appdimens-ios"),  // core + strategies + auto + resize + units + metal
    .product(name: "AppDimensPower", package: "appdimens-ios"),    // add satellites you use
])
```

| Product | Android artifact | Contents |
|---|---|---|
| `AppDimens` | `appdimens-dynamic` | core: `sdp`/`hdp`/`wdp`/`ssp`/`sem`…, builders, providers |
| `AppDimensDynamic` | BOM-style aggregate | core + strategies + auto + resize + units + Metal |
| `AppDimensPercent`, `AppDimensPower`, `AppDimensFluid`, `AppDimensAuto`, `AppDimensDensity`, `AppDimensDiagonal`, `AppDimensFill`, `AppDimensFit`, `AppDimensInterpolated`, `AppDimensLogarithmic`, `AppDimensPerimeter` | `appdimens-dynamic-<strategy>` | satellite catalogs (`p*`, `pw*`, `f*`, `a*`, `d*`, `dg*`, `fl*`, `ft*`, `i*`, `log*`, `pr*`) |
| `AppDimensResize`, `AppDimensUnits` | `-resize`, `-units` | auto-resize ladders, physical units |
| `AppDimensCustom` | `-custom` | **your own strategies**: `ScalingStrategy.define`, JSON shared with every AppDimens platform, presets, `16.cdp(brand)` |
| `AppDimensStrategies` | — | runtime strategy selection, `DimensFactors` |
| `AppDimensMetal` | — | GPU uniforms + MSL helpers |

Requirements: Swift 5.9+ (Xcode 15+), iOS 13, macOS 10.15, tvOS 13, watchOS 7, visionOS 1. Linux is supported for the platform-independent API.

## Quick start — SwiftUI

Install the provider once per window (Android `AppDimensProvider`):

```swift
import SwiftUI
import AppDimensDynamic

@main
struct ExampleApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView().appDimens()          // or AppDimensProvider { ContentView() }
        }
    }
}

struct ContentView: View {
    var body: some View {
        VStack(spacing: 12.sdp) {
            Text("Title").font(.system(size: 22.ssp, weight: .bold))
            Text("Body").font(.system(size: 16.ssp))
            RoundedRectangle(cornerRadius: 12.sdp)
                .frame(width: 100.wdp, height: 48.hdp)
        }
        .padding(16.sdp)
    }
}
```

The provider measures the **full window** (safe-area insets — including the keyboard — are added back, so showing the keyboard never rescales the UI), reads `displayScale` and Dynamic Type, and publishes one `DimensConfiguration` to:

* the ambient store read by `16.sdp` — on **iOS 17 / macOS 14 / tvOS 17 / watchOS 10 / visionOS 1+** every `body` that reads `16.sdp` is re-evaluated automatically on rotation, resize, Split View or Dynamic Type changes (Swift Observation — the Compose `LocalConfiguration` behaviour);
* the environment value `\.appDimensConfiguration` — the per-window, every-OS-version path.

**Multi-window apps and iOS 13–16:** read the environment so each view resolves against its own window and is invalidated by SwiftUI on every OS version:

```swift
struct Card: View {
    @Environment(\.appDimensConfiguration) private var dimens
    @ScaledDimension(16) private var padding              // sdp
    @ScaledDimension(text: 18) private var titleSize      // ssp
    @ScaledDimension(24, strategy: .power) private var gap // pwsdp

    var body: some View {
        VStack(spacing: gap) {
            Text("Card").font(.system(size: titleSize))
            Divider().frame(width: 120.wdp(dimens))         // explicit window → Double
        }
        .padding(padding)
    }
}
```

Previews and snapshot tests can pin a window: `.appDimensConfiguration(DimensConfiguration(screenWidth: 390, screenHeight: 844, displayScale: 3))`.

## UIKit / AppKit

```swift
import UIKit
import AppDimensDynamic

func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options: UIScene.ConnectionOptions) {
    AppDimens.startAutomaticUpdates()   // tracks the key window: rotation, Split View, Stage Manager, Dynamic Type
}

final class ProfileCell: UICollectionViewCell {
    override init(frame: CGRect) {
        super.init(frame: frame)
        layer.cornerRadius = 12.sdp
        titleLabel.font = .ssp(17, weight: .semibold)   // UIFont.systemFont sized with ssp
        heightAnchor.constraint(equalToConstant: 72.hdp).isActive = true
    }
}

// Resolve against the window hosting a specific view (multi-window iPad):
let radius = 12.sdp(in: view)
```

macOS (AppKit) uses the same calls: `AppDimens.startAutomaticUpdates()` follows the key window (resize, full screen, screen and backing-scale changes) and `NSFont.ssp(_:weight:)` is available.

Without automatic updates, call `AppDimens.refresh(from: view)` from `viewWillTransition(to:with:)`, or set any snapshot yourself with `AppDimens.update(_:)`. `AppDimens.observe { configuration in … }` notifies you of every change (e.g. to invalidate a layout or a Metal buffer).

## Explicit configuration (Android `code` API)

Every accessor also takes a configuration and returns `Double` points — deterministic, allocation-free and safe on any thread:

```swift
let c = DimensConfiguration(screenWidth: 390, screenHeight: 844, displayScale: 3, fontScale: 1)
16.sdp(c)      // 20.8
16.hdp(c)      // 45.01
16.ssp(c)      // 20.8 × fontScale
16.sdpPx(c)    // 62.4 pixels
16.pwsdp(c)    // power strategy
```

## Variants

```swift
16.sdpa        // aspect-ratio-aware curve
32.hdpi        // ignore multi-window (raw value when the window is constrained)
16.sspia       // both
32.sdpPh       // smallest width → height in portrait
50.hdpLw       // height → width in landscape
50.wdpLh       // width → height in landscape
16.sei         // sem in pixels
16.sdpPx, 16.sdpPxPh, 16.sspPxa   // pixel variants (Android spellings and <name>Px)
```

Inverters: `phToLw`, `pwToLh`, `lhToPw`, `lwToPh`, `swToLh`, `swToLw`, `swToPh`, `swToPw` (`.default` never swaps — `hdp` is always the window height).

## Facilitators

```swift
80.sdpRotate(50)                                   // 50 in landscape, 80 otherwise
80.sdpRotate(50, orientation: .portrait)
30.sdpMode(200, .television)                       // Apple TV
16.sdpQualifier(24, .smallWidth, 600)              // ≥ 600 pt smallest width
16.sdpScreen(40, .television, .width, 1280)        // mode AND qualifier
16.sspRotate(20, fontScale: false)                 // text, options as on Android
16.sdpRotate(24, finalQualifierResolver: .width, applyAspectRatio: true)
resolved.sdpRotatePlain(50)                        // receiver passes through unchanged when not matching
80.sdpRotatePx(50)                                 // pixels
```

Every facilitator exists for `sdp`/`hdp`/`wdp`/`ssp`/`hsp`/`wsp` and for every satellite prefix (`pwsdpMode`, `asspScreen` …), ambient (`CGFloat`) or with a trailing configuration (`Double`).

## Conditional builders

Same priority rules as Android `DimenScaled`: **1** mode + qualifier, **2** mode, **3** qualifier, **4** orientation; ties break by the higher qualifier threshold.

```swift
let padding = 16.scaledDp()
    .screen(.television, customValue: 40)
    .screen(.smallWidth, 600, customValue: 24)
    .screen(.smallWidth, 840, customValue: 32)
    .screen(.landscape, customValue: 12)
    .applyAspectRatio()

padding.sdp            // CGFloat, ambient
padding.hdp(c)         // Double, explicit window

let title = 20.scaledSp().screen(.smallWidth, 600, customValue: 28)
Text("Title").font(.system(size: title.ssp))

16.powerDp().screen(.landscape, customValue: 12).sdp     // any strategy: powerDp(), autoDp(), fluidSp() …
16.dimen(.logarithmic).sdp                               // strategy chosen at run time
```

## Strategies

| Strategy | Prefix | Formula (`d` = resolved axis, default smallest width) | Typical use |
|---|---|---|---|
| Scaled | — | `v·d/300` | default for spacing and text |
| Percent | `p` | `v·d/300` (+ literal `25.spaceW`, `10.space(200)`) | proportional layouts |
| Power | `pw` | `v·(d/300)^0.75` | damped growth on tablets |
| Logarithmic | `log` | `v·(1 ± 0.4·ln(d/300))` | strong damping |
| Auto | `a` | linear to 480, logarithmic beyond | phones linear, tablets damped |
| Fluid | `f` | `v × 0.8…1.2` over 320…768 | bounded typography |
| Interpolated | `i` | `v·(1 + (d/300 − 1)/2)` | half-way between fixed and scaled |
| Diagonal | `dg` | `v·√(w²+h²)/611.63` | screen-size aware icons |
| Perimeter | `pr` | `v·(w+h)/833` | balanced 2-axis growth |
| Fit / Fill | `ft` / `fl` | `v·min/max(sm/300, lg/533)` | contain / cover |
| Density | `d` | `v·displayScale` | pixel-density aware strokes |

Each satellite has the full catalog: `16.pwsdp`, `16.pwhdpLw`, `16.pwsspa`, `30.pwsdpMode(…)`, `16.powerDp().screen(…)`. Runtime selection: `16.dynamic(.power)` or `DynamicDimens.resolve(16, strategy: .power, configuration: c)`. Details: [Strategy catalog](Documentation/STRATEGIES.md), [Mathematics](Documentation/MATHEMATICS-AND-CALCULUS.md).

### Custom strategies (`AppDimensCustom`)

When none of the curves above fits, define your own. The simplest way is to write the math as ordinary Swift on one line. Xcode autocompletes `base`, `sw`, `width`, `tablet`, `pow`, `clamp`…, and typos fail at compile time:

```swift
import AppDimensCustom

let product = CustomScaleStrategy { s in s.clamp(s.width / 360, 0.85, 1.80) }   // factor × every value
let hud = scalingFormula { $0.base * $0.pow($0.sw / 360, 0.8) }                 // final value (base = 16 in 16.cdp)
Text("Hi").padding(16.cdp(product))
Text("Score").font(.system(size: 18.csp(hud)))
let remote = try scalingFormula("base * pow(sw / 360, 0.8)")                     // same thing as text, for JSON / remote config
```

For rules per device, factor bounds or a font-scale policy, use the full configuration. The same JSON works on Android, Flutter, Web, RN, KMP, Games and .NET:

```swift
let brand = try ScalingStrategy.define("brand",
    reference: ReferenceScreen(width: 360, height: 640),
    curve: .power(0.8), minFactor: 0.85, maxFactor: 1.6,
    rules: [.on([.tablet, .desktop], ScalingPatch(curve: .logarithmic(0.4)))])

Text("Hi").font(.system(size: 14.csp(brand))).padding(16.cdp(brand))
ContentView().scalingStrategy(brand)        // scope for @CustomDimension(16)
```

Presets (`CustomPresets.tvSafe`, `tabletFriendly`, …), `BuiltInStrategies.power.extend(…)` and `ScalingStrategies.load(resource:)`. Guide: [Documentation/strategies/custom.md](Documentation/strategies/custom.md).

## Metal

```swift
import AppDimensMetal

let library = try AppDimensMetal.makeLibrary(device: device, additionalSource: myShaderSource)
encoder.setAppDimensUniforms(index: 1)                // ambient window, setVertexBytes + setFragmentBytes
// or a persistent buffer:
let buffer = AppDimensMetal.makeBuffer(device: device)!
let token = AppDimens.observe { c in AppDimensMetal.update(buffer, configuration: c) }
```

```metal
vertex VertexOut vertex_main(uint vid [[vertex_id]], constant AppDimensUniforms& u [[buffer(1)]]) {
    float corner = appdimens_sdp(u, 12.0);          // same value as 12.sdp on the CPU
    float stroke = appdimens_px(u, appdimens_power(u, 2.0));
    float2 ndc   = appdimens_ndc(u, float2(appdimens_wdp(u, 20.0), appdimens_hdp(u, 40.0)));
    …
}
```

`AppDimensUniforms` (96 bytes) carries every strategy factor plus display scale, font scale, aspect ratio and the multi-window flag; `AppDimensUniforms.metalSource` contains the matching MSL struct and helpers. See [Metal guide](Documentation/METAL.md).

## Performance

| Path | Cost per value | Notes |
|---|---|---|
| `16.sdp(configuration)` | < 1 ns | factors precomputed per window; inlined multiply |
| `DimensFactors(c).resolve(_:strategy:)` | < 1 ns | hot loops, buffers (`resolve(&array, strategy:)`) |
| `16.sdp` (ambient) | one uncontended `os_unfair_lock` (+ ~20 ns Observation registration on the main thread once a SwiftUI provider is installed) | thread-safe, coherent snapshot |
| `DimensConfiguration(...)` | ~45 ns | all `log`/`pow`/`sqrt` evaluated once here |

No caches to invalidate and no allocation on any resolution path. On the default smallest-width path every strategy is a precomputed factor; non-default axes of power/logarithmic/auto evaluate one `pow`/`log` per call. Run `swift test -c release --filter PerformanceTests` for local numbers; see [Performance](Documentation/PERFORMANCE.md).

## Correctness rules

* `sdp`/`hdp`/`wdp` always describe the **window**, never the view they are used in. Use `GeometryReader` for container-relative layout.
* `ssp`/`hsp`/`wsp` multiply by the Dynamic Type scale (body size ÷ 17 pt); `sem`/`hem`/`wem` ignore it. SwiftUI `.system(size:)` fonts are fixed-size, so the scale is applied exactly once.
* `*i` variants return the unscaled value when the window is constrained (iPad Split View / Slide Over / Stage Manager, resized Mac window).
* Invalid inputs (zero, negative, NaN) fall back to the 300 × 533 reference instead of crashing.

## Documentation

* [Beginner guide](GUIDE-FOR-BEGINNERS.md)
* [Documentation hub](Documentation/README.md) — [API](Documentation/API.md) · [Apple integration](Documentation/APPLE-INTEGRATION.md) · [Metal](Documentation/METAL.md) · [Strategies](Documentation/STRATEGIES.md) · [Mathematics](Documentation/MATHEMATICS-AND-CALCULUS.md) · [Performance](Documentation/PERFORMANCE.md) · [Migration](Documentation/MIGRATION.md) · [Android parity](Documentation/PRINCIPAL-PARITY.md) · [Troubleshooting](Documentation/TROUBLESHOOTING.md)
* [Changelog](CHANGELOG.md)

## Development

```bash
swift test                                   # all platforms incl. Linux
swift test -c release --filter PerformanceTests
python3 scripts/generate_catalogs.py         # regenerate the catalogs (CI checks they are current)
python3 .github/scripts/validate_repository.py
```

Licensed under the [Apache License 2.0](LICENSE).
