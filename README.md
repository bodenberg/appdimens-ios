# AppDimens Dynamic for Apple — principal library

Direct Apple port of the **principal `appdimens-dynamic` artifact** from Android, focused in this phase on `common`, `core`, `plain` and `scaled`. Satellite strategies (`auto`, `percent`, `power`, `fluid`, Metal and others) are intentionally deferred to later phases.

## Contract

` sdp / wdp / hdp ` always use the current **window/scene configuration**, exactly as Android uses `Configuration`/`LocalConfiguration`. A child view never becomes a new scaling reference. Container-relative sizing is not mixed with these APIs.

Baseline: `300` points, reference aspect ratio: `1.78`.

## Installation

In Xcode choose **File › Add Package Dependencies…** and enter:

```text
https://github.com/bodenberg/appdimens-ios
```

Select the `AppDimens` product. With SwiftPM:

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

## Scope of this phase

Implemented now:

- common enums and all eight inverters;
- window-based configuration;
- scaled dp/sp/em families and `a`/`i` variants;
- rotation, qualifier and UI-mode facilitators;
- value-semantic `scaledDp` builder;
- automatic SwiftUI and UIKit integration;
- deterministic tests.

Deferred deliberately: every satellite artifact and Metal. They will be ported individually only after the principal contract is stable.

See [principal parity audit](Documentation/PRINCIPAL-PARITY.md).
