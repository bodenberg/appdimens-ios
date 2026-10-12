# Power-law scaling

[Strategy catalog](../STRATEGIES.md) · [Mathematics](../MATHEMATICS-AND-CALCULUS.md) · [API](../API.md)

## What it is

Use **power** for a smooth, damped growth curve. Values grow with the window, but more slowly than linear scaling. The exponent is fixed at 0.75 and is not configurable.

## Mathematical theory

**Formula:** `result = v × (d/300)^0.75`.

Because `0.75 < 1`, growth is sublinear: doubling `d` multiplies the result by `2^0.75 ≈ 1.68` instead of `2`. The result equals `v` at the 300-point reference, and it is smaller than `v` below 300 points.

With `applyAspectRatio` (`pwsdpa`), the result is multiplied by `1 + k × ln(AR / 1.78)`, with `k = 0.08/30` by default.

## Worked calculation

For `v=24` and `d=390`, `(390/300)^0.75 = 1.3^0.75 ≈ 1.2175`, so the result is `24 × 1.2175 ≈ 29.22 pt`.

## Swift usage

```swift
import AppDimensDynamic
import AppDimensPower

let c = DimensConfiguration(screenWidth: 390, screenHeight: 844, displayScale: 3)
let icon = 24.powerDp(c)                                                    // ≈ 29.22
let runtime = DynamicDimens.resolve(24, strategy: .power, configuration: c) // ≈ 29.22
let iconCatalog = 24.pwsdp(c)                                               // ≈ 29.22, AppDimensPower catalog
let gap = 16.pwsdp                                                          // CGFloat, ambient window
let threshold = 16.pwsdpQualifier(24, .smallWidth, 600)                     // 24 when smallest width ≥ 600, otherwise 16; both power-scaled
```

In SwiftUI, `@ScaledDimension(16, strategy: .power) var gap` resolves the same curve against the window that owns the view.

## Recommended use

Use power when you want a smooth, damped response on large screens and the fixed 0.75 exponent is acceptable. Compare it with scaled and logarithmic in design review rather than choosing curves by device name.

## Advantages

* Deterministic and stateless: identical configuration produces identical output.
* Constant-time calculation with no I/O, global cache, or UI-framework dependency.
* Supports explicit qualifiers through `StrategyOptions`.

## Trade-offs and misuse

The exponent cannot be tuned. Values shrink below 300 points, so very narrow windows get smaller tokens than the base value; confirm that this is intended. If the design needs a different response, choose another strategy such as [logarithmic](logarithmic.md) or [fluid](fluid.md).

## Validation checklist

1. Verify the identity at the reference: `16.powerDp(c)` returns `16` for `DimensConfiguration(screenWidth: 300, screenHeight: 533)`.
2. Compare phone portrait and landscape.
3. Test iPad full screen and a narrow split-view window.
4. Resize continuously on macOS or iPadOS and look for unintended jumps.
5. Test large Dynamic Type separately; geometric strategies do not automatically apply `fontScale`.

## Performance

Resolution is `O(1)`. On the default smallest-width path the power factor is precomputed once per window, so no `pow` runs per call. Width, height and inverted-axis resolutions evaluate `pow` on each call, so cache those values if they sit in a hot loop. On the default path an explicit call is a branch and a multiply once inlined, which is sub-nanosecond on current hardware; ambient calls take one uncontended lock. For hot loops, `DimensFactors` holds the default power factor:

```swift
let factors = DimensFactors(c)
let icons = [16.0, 24.0, 32.0].map { factors.resolve($0, strategy: .power) }  // ≈ [19.48, 29.22, 38.96]
```
