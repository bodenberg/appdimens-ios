# Linear scaling

[Strategy catalog](../STRATEGIES.md) · [Mathematics](../MATHEMATICS-AND-CALCULUS.md) · [API](../API.md)

## What it is

Use **scaled** for general spacing, radii, controls, and design tokens.

## Mathematical theory

**Formula:** `result = v × d / 300`, where `d` is the resolved axis in points: the smallest window side for `.smallWidth` (the default), the window width for `.width`, or the window height for `.height`.

The output preserves ratios: doubling the effective axis doubles the token. At the 300-point reference it is the identity function.

**Aspect-ratio variant (`sdpa`, `applyAspectRatio: true`):** `result = v × (1 + (d − 300) × (0.10/30 + k × ln(AR / 1.78)))`, where `AR = max(w, h) / min(w, h)` and `k` defaults to `0.08/30`. The slope now depends on the window's shape. Pass `sensitivityK` to replace `k`.

## Worked calculation

For `v=16` and `d=390`, the result is `16×390/300 = 20.8 pt`.

With aspect correction on the same 390×844 window, `AR = 844/390 ≈ 2.164`, the multiplier is `1 + 90 × (0.10/30 + (0.08/30) × ln(2.164/1.78)) ≈ 1.3469`, and the result is `16 × 1.3469 ≈ 21.55 pt`.

## Swift usage

```swift
import AppDimensDynamic

let c = DimensConfiguration(screenWidth: 390, screenHeight: 844, displayScale: 3)
let padding = 16.sdp(c)                                                       // 20.8
let width = 120.wdp(c)                                                        // 156.0
let rowHeight = 44.hdp(c)                                                     // ≈ 123.79
let corner = 16.sdpa(c)                                                       // ≈ 21.55, aspect-ratio variant
let runtime = DynamicDimens.resolve(16, strategy: .scaled, configuration: c)  // 20.8
```

Explicit-configuration calls (`16.sdp(c)`) return `Double` and suit tests and background work. Ambient calls (`16.sdp`) return `CGFloat` for the window installed by `.appDimens()` in SwiftUI or by `AppDimens.startAutomaticUpdates()` in UIKit and AppKit. Convert `Double` results to `CGFloat` at the view boundary.

## Recommended use

Prefer this default until a concrete requirement proves that another curve is better. Use `.smallWidth` for rotation-stable tokens, `.width` for horizontal geometry, and `.height` only for vertical geometry.

## Advantages

* Deterministic and stateless: identical configuration produces identical output.
* Constant-time calculation with no I/O, global cache, or UI-framework dependency.
* Supports explicit qualifiers through `StrategyOptions`.

## Trade-offs and misuse

Linear growth can make controls excessively large on wide desktop windows. Consider power, logarithmic, or fluid there.

## Validation checklist

1. Verify the identity/reference behavior: `16.sdp(c)` returns `16` for `DimensConfiguration(screenWidth: 300, screenHeight: 533)`.
2. Compare phone portrait and landscape.
3. Test iPad full screen and a narrow split-view window.
4. Resize continuously on macOS or iPadOS and look for unintended jumps.
5. Test large Dynamic Type separately; geometric strategies do not automatically apply `fontScale`.

## Performance

Resolution is `O(1)`. Every scaled path reads factors that `DimenMetrics` precomputes once per window, so no `log`, `pow` or `sqrt` runs per call. On the default path an explicit call (`16.sdp(c)`) is a branch and a multiply once inlined, which is sub-nanosecond on current hardware; measure your own app before relying on that figure. An ambient call (`16.sdp`) takes one uncontended lock to read the window snapshot. For hot loops, build `DimensFactors(c)` once per window configuration and call `resolve(_:strategy:)` for each value.
