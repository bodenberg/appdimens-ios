# Density-aware scaling

[Strategy catalog](../STRATEGIES.md) · [Mathematics](../MATHEMATICS-AND-CALCULUS.md) · [API](../API.md)

## What it is

Use **density** for pixel buffers, bitmap kernels, and legacy pixel specifications.

## Mathematical theory

**Formula:** `result = v × d / 300 × displayScale`.

The first factor performs ordinary geometric scaling; the display scale then converts logical points into device pixels. A 2× Retina display therefore produces twice the numeric pixel count, not twice the visible size.

## Worked calculation

With `v=16`, `d=390`, and `displayScale=3`, the result is `62.4 px`. The corresponding logical length remains `20.8 pt`.

## Swift usage

```swift
import AppDimensDynamic

let c = DimensConfiguration(screenWidth: 390, screenHeight: 844, displayScale: 3)
`let pixels = 1.densityDp(c)`
`let bufferSide = 64.dynamic(.density, c)`
```

Use the numeric extension for concise token code or `DynamicDimens.resolve` when the strategy is selected at runtime. Both return `Double`; convert to `CGFloat` at the view boundary.

## Recommended use

Use only at an API boundary that explicitly consumes pixels, such as a raster buffer. Use scaled points for SwiftUI frames, UIKit constraints, padding, and corner radii.

## Advantages

* Deterministic and stateless: identical configuration produces identical output.
* Constant-time calculation with no I/O, global cache, or UI-framework dependency.
* Supports explicit qualifiers through `StrategyOptions`.

## Trade-offs and misuse

Using this value as points double-applies density and creates oversized UI. It is not physical PPI.

## Validation checklist

1. Verify the identity/reference behavior at `300 × 533`.
2. Compare phone portrait and landscape.
3. Test iPad full screen and a narrow split-view window.
4. Resize continuously on macOS or iPadOS and look for unintended jumps.
5. Test large Dynamic Type separately; geometric strategies do not automatically apply `fontScale`.

## Performance

Resolution is `O(1)`. For repeated rendering, construct `DimensFactors` once per window configuration where the strategy has a precomputed fast path; otherwise reuse `DimensConfiguration` and avoid rediscovering window metrics per element.
