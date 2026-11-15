# Quick start

## 1. Install

Xcode: **File › Add Package Dependencies…** → `https://github.com/bodenberg/appdimens-ios`, then add the `AppDimensCustom` product. `AppDimensDynamic` does not include it.

```swift
// Package.swift
.package(url: "https://github.com/bodenberg/appdimens-ios", from: "3.2.0")

.target(name: "App", dependencies: [
    .product(name: "AppDimensCustom", package: "appdimens-ios"),
])
```

```swift
import AppDimensCustom   // re-exports AppDimens (DimensConfiguration, .appDimens(), 16.sdp…)
```

The zero-argument forms (`16.cdp(product)`) read the ambient window, `AppDimens.configuration`, kept up to date by `.appDimens()` in SwiftUI or `AppDimens.startAutomaticUpdates()` in UIKit / AppKit, exactly like `16.sdp`.

## 2. Write the math (recommended)

Declare the strategy **once** (for example as a `static let`), then use it anywhere.

```swift
enum AppStrategies {
    // Factor: the number that multiplies every value
    static let product = CustomScaleStrategy { s in s.clamp(s.width / 360, 0.85, 1.80) }

    // Formula: the final value (`base` = the value you pass, the 16 in 16.cdp(hud))
    static let hud = scalingFormula { $0.base * $0.pow($0.sw / 360, 0.8) }
}
```

The closure receives a typed scope. Xcode autocompletes `width`, `sw`, `height`, `ratio`, `tablet`, `tv`, `landscape`, `pow`, `clamp`, `min`, `max`, `lerp`… and a typo is a compile error. Any other Swift works too (`if`, `switch`, your own helpers). The full list is in [Code formulas](code-formulas.md).

## 3. Use it

```swift
// SwiftUI
Text("Body").padding(16.cdp(AppStrategies.product))                 // CGFloat points
Text("Score").font(.system(size: 18.csp(AppStrategies.hud)))        // final point size (Dynamic Type per policy)
let px = 24.cdpPx(AppStrategies.product)                            // physical pixels

// Per window (multi-window apps, iOS < 17): the view's own configuration
struct Card: View {
    @CustomDimension(16, strategy: AppStrategies.product) private var padding
    var body: some View { Text("Card").padding(padding) }
}

// UIKit
let c = DimensConfiguration.current(in: view)
view.layoutMargins.left = 16.cdp(AppStrategies.product, c)          // Double points
```

## 4. Make it the default (optional)

```swift
ScalingStrategies.defaultStrategy = AppStrategies.product   // app-wide: 16.cdp now uses product
ContentView()
    .scalingStrategy(AppStrategies.hud)                     // one subtree: @CustomDimension(16) uses hud
    .appDimens()
```

## 5. The same thing as text (for JSON and remote config)

```swift
let remote = try scalingFormula("base * pow(sw / 360, 0.8)")
let gap = try 16.cdp("base * (sw / 360)")                  // inline, shared per text (throws on a bad formula)
@CustomDimension(16, formula: "base * (sw / 360)") private var gutter   // SwiftUI, per window
```

The text form uses the same names (flags are 1 or 0), `throws` on a typo, and works in the strategies JSON (`{"id": "hud", "formula": "base * pow(sw / 360, 0.8)"}`). See [Text formulas](text-formulas.md).

## 6. Need more structure?

Rules per device class, factor bounds, a font-scale cap or a different reference frame go in the full configuration:

```swift
let brand = try ScalingStrategy.define("brand",
    reference: ReferenceScreen(width: 360, height: 640),
    curve: .power(0.8),
    minFactor: 0.85, maxFactor: 1.6,
    fontScale: .clamp(1.3),
    rules: [.on([.tablet, .desktop], ScalingPatch(curve: .logarithmic(0.4)), name: "large")])
```

See [Configuration](configuration.md) and [JSON format](json.md).

## 7. Check the numbers

```swift
print(AppStrategies.product.explain())
// [scale#1] phone smallestWidth=390dp / ref 300 = 1.3 -> custom = 1.0833 => factor 1.0833
```

[Back to the custom docs](README.md)
