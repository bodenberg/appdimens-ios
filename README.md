# AppDimens Dynamic for iOS

A native, deterministic port of **AppDimens Dynamic** for Swift, SwiftUI and UIKit. It keeps the Android library's recognizable `dynamic`, `screen` and qualifier vocabulary, but follows Apple's layout model: values are **points**, the current window/container is the source of truth, Dynamic Type is explicit, and no global screen singleton or mutable cache is required.

## Why this is an iOS port—not an Android emulation

| Android concept | AppDimens iOS |
|---|---|
| `dp` | logical point (`CGFloat`) |
| `sp` / font scale | `text: true` plus SwiftUI Dynamic Type |
| density pixels | `pixels(in:)` only when a pixel value is truly needed |
| resource qualifiers | composable `DimensionQualifier` values |
| `DisplayMetrics` | injected `DimensionContext` |
| Compose recomposition | SwiftUI `Environment` updated by `GeometryReader` |

The core module has no UIKit/SwiftUI dependency and is also buildable on Linux, which makes calculations easy to test in CI. UI adapters live in a separate module.

## Requirements

- Swift 5.9+
- Xcode 15+
- iOS 15+, macOS 12+, tvOS 15+, or watchOS 8+
- No third-party dependencies

## Install from GitHub with Xcode

This library is distributed directly from GitHub with Swift Package Manager—there is no CocoaPod binary or separate registry.

1. In Xcode open **File → Add Package Dependencies…**.
2. Paste `https://github.com/bodenberg/appdimens.git`.
3. Choose **Up to Next Major Version** and the latest tagged release.
4. Add `AppDimens` for calculator-only targets, or both `AppDimens` and `AppDimensUI` for SwiftUI/UIKit.

Or in `Package.swift`:

```swift
.package(url: "https://github.com/bodenberg/appdimens.git", from: "3.0.0")
```

```swift
.target(name: "MyApp", dependencies: [
    .product(name: "AppDimens", package: "appdimens"),
    .product(name: "AppDimensUI", package: "appdimens")
])
```

## SwiftUI quick start

```swift
import SwiftUI
import AppDimens
import AppDimensUI

struct Card: View {
    @AppDimension(16.dynamic.when(.minWidth(600), 24)) private var padding
    @AppDimension(44.dynamic.limits(min: 44, max: 64)) private var buttonHeight

    var body: some View {
        VStack { Text("Accessible"); Button("Continue") {} }
            .padding(padding)
            .frame(minHeight: buttonHeight)
    }
}

@main struct DemoApp: App {
    var body: some Scene { WindowGroup { Card().appDimens() } }
}
```

Place `.appDimens()` once at the scene/root view. It tracks the actual container, including iPad split view, rotation, Stage Manager and resizable windows.

## Core / UIKit quick start

```swift
import AppDimens
import AppDimensUI

let spacing = 16.dynamic
    .screen(.lowest)
    .strategy(.balanced)
    .when(.minShortestSide(600), 24)
    .limits(min: 12, max: 32)

let context = DimensionContext.current(for: view)
stackView.spacing = spacing.points(in: context)
```

See [full documentation](Documentation/README.md), [API guide](Documentation/API.md), [architecture](Documentation/ARCHITECTURE.md), [Android migration](Documentation/MIGRATION_ANDROID.md), and runnable snippets in [`Examples`](Examples).

## Design guarantees

- Immutable declarations with value semantics and `Sendable` conformance.
- Deterministic results: identical declaration + context = identical value.
- Pixel-grid rounding for crisp rendering.
- Explicit min/max guards against unusable controls on extreme screens.
- Last matching override wins; multiple qualifiers form an intersection.
- Accessibility text scaling is separate from geometric layout scaling.

## License

Apache License 2.0. See [LICENSE](LICENSE).
