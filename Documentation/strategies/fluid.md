# Bounded fluid ramp

[Strategy catalog](../STRATEGIES.md) · [Mathematics](../MATHEMATICS-AND-CALCULUS.md) · [API](../API.md)

## What it is

Use **fluid** for responsive values that grow only within a known viewport band.

## Mathematical theory

**Formula:** `t = clamp((d−L)/(U−L),0,1)`; `result = v × lerp(a,b,t)`.

This is piecewise linear: constant below `L`, linear between `L` and `U`, and constant above `U`. It is continuous at both bounds.

## Worked calculation

For `d=544`, the default band gives `t=0.5`, scale `1.0`, and a 24-point token remains `24 pt`.

## Swift usage

```swift
import AppDimensDynamic

let c = DimensConfiguration(screenWidth: 390, screenHeight: 844, displayScale: 3)
`let options = StrategyOptions(qualifier: .width, fluidViewport: 320...768, fluidScale: 0.8...1.2)`
`let gutter = 24.fluidDp(c, options: options)`
```

Use the numeric extension for concise token code or `DynamicDimens.resolve` when the strategy is selected at runtime. Both return `Double`; convert to `CGFloat` at the view boundary.

## Recommended use

Use for gutters, hero typography, and desktop-capable layouts with explicit minimum and maximum visual sizes.

## Advantages

* Deterministic and stateless: identical configuration produces identical output.
* Constant-time calculation with no I/O, global cache, or UI-framework dependency.
* Supports explicit qualifiers through `StrategyOptions`.

## Trade-offs and misuse

The bounds are product decisions, not device categories. A zero-width viewport range becomes a step; reversed ranges should be avoided.

## Validation checklist

1. Verify the identity/reference behavior at `300 × 533`.
2. Compare phone portrait and landscape.
3. Test iPad full screen and a narrow split-view window.
4. Resize continuously on macOS or iPadOS and look for unintended jumps.
5. Test large Dynamic Type separately; geometric strategies do not automatically apply `fontScale`.

## Performance

Resolution is `O(1)`. For repeated rendering, construct `DimensFactors` once per window configuration where the strategy has a precomputed fast path; otherwise reuse `DimensConfiguration` and avoid rediscovering window metrics per element.
