# Logarithmic scaling

[Strategy catalog](../STRATEGIES.md) · [Mathematics](../MATHEMATICS-AND-CALCULUS.md) · [API](../API.md)

## What it is

Use **logarithmic** for strong damping on very large windows.

## Mathematical theory

**Formula:** `v × (1 + 0.4 ln r)` for `r≥1`; `v × (1 − 0.4 ln(1/r))` otherwise.

The derivative above the baseline is `0.4v/r`, so each additional unit of width has less effect than the previous one. The two branches meet continuously at `r=1`.

## Worked calculation

For `v=28` and `d=390`, `r=1.3`; the result is `28×(1+0.4 ln 1.3) ≈ 30.94 pt`.

## Swift usage

```swift
import AppDimensDynamic

let c = DimensConfiguration(screenWidth: 390, screenHeight: 844, displayScale: 3)
`let title = 28.logarithmicDp(c)`
```

Use the numeric extension for concise token code or `DynamicDimens.resolve` when the strategy is selected at runtime. Both return `Double`; convert to `CGFloat` at the view boundary.

## Recommended use

Use selectively for display typography or controls that must grow across phones, tablets, and desktop windows without tracking width linearly.

## Advantages

* Deterministic and stateless: identical configuration produces identical output.
* Constant-time calculation with no I/O, global cache, or UI-framework dependency.
* Supports explicit qualifiers through `StrategyOptions`.

## Trade-offs and misuse

On extremely small ratios the mathematical scale can approach or cross zero. Normal application windows are positive, but validate any synthetic configuration.

## Validation checklist

1. Verify the identity/reference behavior at `300 × 533`.
2. Compare phone portrait and landscape.
3. Test iPad full screen and a narrow split-view window.
4. Resize continuously on macOS or iPadOS and look for unintended jumps.
5. Test large Dynamic Type separately; geometric strategies do not automatically apply `fontScale`.

## Performance

Resolution is `O(1)`. For repeated rendering, construct `DimensFactors` once per window configuration where the strategy has a precomputed fast path; otherwise reuse `DimensConfiguration` and avoid rediscovering window metrics per element.
