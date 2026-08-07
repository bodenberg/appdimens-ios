# Interpolated scaling

[Strategy catalog](../STRATEGIES.md) · [Mathematics](../MATHEMATICS-AND-CALCULUS.md) · [API](../API.md)

## What it is

Use **interpolated** for gradual migration from fixed values to linear scaling.

## Mathematical theory

**Formula:** `result = v × [1 + (d/300−1)t]`, with `t` clamped to `0...1`.

Linear interpolation blends the identity scale (`t=0`) and scaled (`t=1`). Intermediate values reduce responsiveness without introducing breakpoints.

## Worked calculation

For `v=16`, `d=390`, `t=0.5`, the scale is `1.15` and the result is `18.4 pt`.

## Swift usage

```swift
import AppDimensDynamic

let c = DimensConfiguration(screenWidth: 390, screenHeight: 844, displayScale: 3)
`let options = StrategyOptions(interpolation: 0.35)`
`let radius = 16.interpolatedDp(c, options: options)`
```

Use the numeric extension for concise token code or `DynamicDimens.resolve` when the strategy is selected at runtime. Both return `Double`; convert to `CGFloat` at the view boundary.

## Recommended use

Use when a fixed design feels too rigid but full linear scaling is too aggressive, or while migrating an existing app token by token.

## Advantages

* Deterministic and stateless: identical configuration produces identical output.
* Constant-time calculation with no I/O, global cache, or UI-framework dependency.
* Supports explicit qualifiers through `StrategyOptions`.

## Trade-offs and misuse

It is still unbounded as the window grows. Choose fluid when hard visual limits are required.

## Validation checklist

1. Verify the identity/reference behavior at `300 × 533`.
2. Compare phone portrait and landscape.
3. Test iPad full screen and a narrow split-view window.
4. Resize continuously on macOS or iPadOS and look for unintended jumps.
5. Test large Dynamic Type separately; geometric strategies do not automatically apply `fontScale`.

## Performance

Resolution is `O(1)`. For repeated rendering, construct `DimensFactors` once per window configuration where the strategy has a precomputed fast path; otherwise reuse `DimensConfiguration` and avoid rediscovering window metrics per element.
