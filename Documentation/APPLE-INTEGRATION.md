# Apple integration

[Documentation hub](README.md) · [API](API.md) · [Metal](METAL.md) · [Troubleshooting](TROUBLESHOOTING.md)

AppDimens resolves every value against a **window** snapshot (`DimensConfiguration`): window size in points, display scale, Dynamic Type scale, UI mode and multi-window state — the Apple equivalent of Android's `Configuration`.

## SwiftUI

```swift
WindowGroup { ContentView().appDimens() }      // AppDimensProvider { ContentView() }
```

* Measures the root `GeometryReader` and adds the safe-area insets back (full window; the keyboard does not rescale the UI).
* Reads `displayScale` (platform backing scale on macOS / watchOS) and `sizeCategory` (body size ÷ 17 pt).
* UI mode: `UiModeType.platformDefault` (`.normal`, `.television`, `.desk`, `.watch`, `.vrHeadset`, `.car`) or `AppDimensProvider(uiMode:)`.
* Publishes to `\.appDimensConfiguration` and to the ambient store. Disable the latter for secondary windows with `updatesAmbient: false`.

### Invalidation

| OS | `16.sdp` in a `body` | `@Environment(\.appDimensConfiguration)` / `@ScaledDimension` |
|---|---|---|
| iOS 17+, macOS 14+, tvOS 17+, watchOS 10+, visionOS | re-evaluated automatically (Swift Observation) | re-evaluated |
| iOS 13–16, macOS 10.15–13 | value is current whenever the body runs; add an environment read to subscribe | re-evaluated |

Multi-window apps (iPad scenes, macOS windows) should resolve per window: `16.sdp(dimens)` with `@Environment(\.appDimensConfiguration) var dimens`, or `@ScaledDimension`. The ambient store follows the most recently laid-out window.

## UIKit

```swift
AppDimens.startAutomaticUpdates()
```

Installs an invisible tracker view in every window (layout + trait callbacks) and observes key-window, scene activation, orientation and content-size notifications. The ambient snapshot follows the key window. Alternatives:

* `AppDimens.refresh(from: view)` in `viewWillTransition(to:with:)` / `traitCollectionDidChange(_:)`
* `16.sdp(in: view)` — resolve against the window hosting `view`
* `DimensConfiguration.current(window:)` — explicit snapshot

Multi-window detection compares the window with its screen (`isMultiWindow` when narrower or shorter than 95 %).

## AppKit

`AppDimens.startAutomaticUpdates()` follows the key window's content area (`contentLayoutRect`), resizes, full screen, screen and backing-scale changes. Font scale is 1 (macOS has no Dynamic Type for fixed sizes).

## watchOS

The SwiftUI provider and the ambient API work; the window probe returns the root view size at @2x. Metal is not available.

## Threading

* Ambient reads/writes are thread-safe (one unfair lock) and coherent (no torn values).
* Explicit-configuration APIs are pure functions.
* UIKit/AppKit snapshot constructors are `@MainActor`.
