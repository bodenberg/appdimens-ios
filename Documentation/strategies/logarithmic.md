# Logarithmic scaling

[Strategy catalog](../STRATEGIES.md) · [Mathematics](../MATHEMATICS-AND-CALCULUS.md) · [API](../API.md)

## What it is

Use **logarithmic** for strong damping on very large windows.

## Mathematical theory

**Formula:** with `r = d/300`, `result = v × (1 + 0.4 × ln r)` for `r > 1`, and `result = v × (1 − 0.4 × ln(1/r))` otherwise.

The derivative with respect to `r` above the baseline is `0.4v/r`, so each additional unit of width has less effect than the previous one. The two branches meet continuously at `r = 1`, where the result is `v`.

## Worked calculation

For `v=28` and `d=390`, `r = 1.3`; the result is `28 × (1 + 0.4 ln 1.3) ≈ 28 × 1.1049 ≈ 30.94 pt`.

## Swift usage

```swift
import AppDimensDynamic

let c = DimensConfiguration(screenWidth: 390, screenHeight: 844, displayScale: 3)
let title = 28.logarithmicDp(c)                                                    // ≈ 30.94
let runtime = DynamicDimens.resolve(28, strategy: .logarithmic, configuration: c)  // ≈ 30.94
```

## Recommended use

Use selectively for display typography or controls that must grow across phones, tablets, and desktop windows without tracking width linearly.

## Advantages

* Deterministic and stateless: identical configuration produces identical output.
* Constant-time calculation with no I/O, global cache, or UI-framework dependency.
* Supports explicit qualifiers through `StrategyOptions`.

## Trade-offs and misuse

The factor reaches zero at about 24.6 points (`300 × e^−2.5`) and becomes negative below it. Normal application windows are far above that, but validate any synthetic or very small configuration.

## Validation checklist

1. Verify the identity/reference behavior at `300 × 533`: the factor is 1.
2. Compare phone portrait and landscape.
3. Test iPad full screen and a narrow split-view window.
4. Resize continuously on macOS or iPadOS and look for unintended jumps.
5. Test large Dynamic Type separately; geometric strategies do not automatically apply `fontScale`.

## Performance

Resolution is `O(1)`. On the default smallest-width path the logarithmic factor is precomputed once per window, so no `log` runs per call. Width, height and inverted-axis resolutions evaluate `log` on each call, so cache those values if they sit in a hot loop. An explicit default-path call is a branch and a multiply once inlined, which is sub-nanosecond on current hardware; ambient calls take one uncontended lock. For hot loops, `DimensFactors(c)` holds the default factor for `.logarithmic`.
