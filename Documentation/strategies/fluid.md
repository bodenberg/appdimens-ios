# Bounded fluid ramp

[Strategy catalog](../STRATEGIES.md) · [Mathematics](../MATHEMATICS-AND-CALCULUS.md) · [API](../API.md)

## What it is

Use **fluid** for responsive values that grow only within a fixed viewport band, from 320 to 768 points.

## Mathematical theory

**Formula:** `t = clamp((d − 320) / (768 − 320), 0, 1)`; `result = v × (0.8 + 0.4 × t)`.

`d` is the resolved axis: the smallest window side by default, or the width or height when selected through `StrategyOptions`. The factor is constant at ×0.8 for `d ≤ 320`, linear between the bounds, and constant at ×1.2 for `d ≥ 768`. It is continuous at both bounds.

## Worked calculation

For `d=544`, `t = 0.5`, the factor is `1.0`, and a 24-point token stays `24 pt`. For `d=390`, `t = 70/448 ≈ 0.156`, the factor is `0.8625`, and the result is `24 × 0.8625 ≈ 20.7 pt`.

## Swift usage

```swift
import AppDimensDynamic

let landscape = DimensConfiguration(screenWidth: 844, screenHeight: 390, displayScale: 3)
let gutter = 24.fluidDp(landscape)                                            // ≈ 20.7, smallest width 390
let gutterWidth = DynamicDimens.resolve(24, strategy: .fluid, configuration: landscape,
                                        options: StrategyOptions(qualifier: .width)) // 28.8, width 844 ≥ 768
```

## Recommended use

Use for gutters, hero typography, and desktop-capable layouts with explicit minimum and maximum visual sizes.

## Advantages

* Deterministic and stateless: identical configuration produces identical output.
* Constant-time calculation with no I/O, global cache, or UI-framework dependency.
* Supports explicit qualifiers through `StrategyOptions`.

## Trade-offs and misuse

The 320 to 768 band and the ×0.8 to ×1.2 range are fixed. They are product decisions, not device categories, so check that they match your viewport needs. Below 320 points the factor stays at ×0.8, and above 768 points it stays at ×1.2. If the product needs other limits, pick a different strategy or measure the constraint with [resize](resize.md).

## Validation checklist

1. Verify the bounds: the factor is ×0.8 at 320 points or below, ×1.0 at 544 points, and ×1.2 at 768 points or above. Fluid is not an identity at 300 points, where it returns ×0.8.
2. Compare phone portrait and landscape.
3. Test iPad full screen and a narrow split-view window.
4. Resize continuously on macOS or iPadOS and look for unintended jumps.
5. Test large Dynamic Type separately; geometric strategies do not automatically apply `fontScale`.

## Performance

Resolution is `O(1)`. On the default path the fluid factor is precomputed once per window. Width and height resolutions evaluate the linear ramp on each call, with no transcendental math. An explicit default-path call is a branch and a multiply once inlined, which is sub-nanosecond on current hardware; ambient calls take one uncontended lock. For hot loops, `DimensFactors(c).resolve(_:strategy:)` with `.fluid` reads the default factor.
