# Interpolated scaling

[Strategy catalog](../STRATEGIES.md) · [Mathematics](../MATHEMATICS-AND-CALCULUS.md) · [API](../API.md)

## What it is

Use **interpolated** for gradual migration from fixed values to linear scaling.

## Mathematical theory

**Formula:** `result = v × (1 + (d/300 − 1) × 0.5)`.

The blend is fixed at 50 %, so the result is halfway between the identity (`v`) and linear scaling (`v × d/300`). Intermediate values reduce responsiveness without introducing breakpoints. With `applyAspectRatio`, the result is also multiplied by the aspect-ratio factor `1 + k × ln(AR / 1.78)`.

## Worked calculation

For `v=16` and `d=390`, `d/300 − 1 = 0.3`, the scale is `1 + 0.3 × 0.5 = 1.15`, and the result is `16 × 1.15 = 18.4 pt`.

## Swift usage

```swift
import AppDimensDynamic

let c = DimensConfiguration(screenWidth: 390, screenHeight: 844, displayScale: 3)
let radius = 16.interpolatedDp(c)                                                  // 18.4
let runtime = DynamicDimens.resolve(16, strategy: .interpolated, configuration: c) // 18.4
```

## Recommended use

Use when a fixed design feels too rigid but full linear scaling is too aggressive, or while migrating an existing app token by token.

## Advantages

* Deterministic and stateless: identical configuration produces identical output.
* Constant-time calculation with no I/O, global cache, or UI-framework dependency.
* Supports explicit qualifiers through `StrategyOptions`.

## Trade-offs and misuse

It is still unbounded as the window grows, and the 50 % blend is fixed. Choose fluid when hard visual limits are required.

## Validation checklist

1. Verify the identity/reference behavior at `300 × 533`: the factor is 1.
2. Compare phone portrait and landscape.
3. Test iPad full screen and a narrow split-view window.
4. Resize continuously on macOS or iPadOS and look for unintended jumps.
5. Test large Dynamic Type separately; geometric strategies do not automatically apply `fontScale`.

## Performance

Resolution is `O(1)`. On the default path the interpolated factor is precomputed once per window, and width or height resolutions are linear with no transcendental math. An explicit default-path call is a branch and a multiply once inlined, which is sub-nanosecond on current hardware; ambient calls take one uncontended lock. For hot loops, `DimensFactors(c)` holds the default factor for `.interpolated`.
