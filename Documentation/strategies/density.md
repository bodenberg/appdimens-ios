# Density-aware scaling

[Strategy catalog](../STRATEGIES.md) · [Mathematics](../MATHEMATICS-AND-CALCULUS.md) · [API](../API.md)

## What it is

Use **density** for pixel buffers, bitmap kernels, and legacy pixel specifications.

## Mathematical theory

**Formula:** `result = v × displayScale`.

The result is a pixel count, and it does not depend on the window size: the window plays no part in the formula. A 3× display produces three times the value of a 1× display, which is correct for a pixel buffer and wrong for point-based layout.

## Worked calculation

With `v=16` and `displayScale=3`, the result is `48 px` whatever the window size. For comparison, `16.sdpPx(c)` on a 390-point window scales the token first and gives `20.8 × 3 = 62.4 px`.

## Swift usage

```swift
import AppDimensDynamic

let c = DimensConfiguration(screenWidth: 390, screenHeight: 844, displayScale: 3)
let pixels = 16.densityDp(c)                  // 48.0
let bufferSide = 64.dynamic(.density, c)      // 192.0
let scaledPixels = 16.sdpPx(c)                // ≈ 62.4, scaled first, then × displayScale
```

With `import AppDimensDensity`, the ambient `16.dsdp` returns the same pixel count as a `CGFloat`.

## Recommended use

Use only at an API boundary that explicitly consumes pixels, such as a raster buffer. Use scaled points for SwiftUI frames, UIKit constraints, padding, and corner radii.

## Advantages

* Deterministic and stateless: identical configuration produces identical output.
* Constant-time calculation with no I/O, global cache, or UI-framework dependency.
* Ignores `qualifier` and the window size; its only input is `displayScale`.

## Trade-offs and misuse

Using this value as points double-applies density and creates oversized UI. It is not physical PPI, and it cannot correct a layout that must respond to the window.

## Validation checklist

1. At `displayScale` 1 the result equals the token at every window size; at 3× it is three times the token.
2. Check pixel buffers on 1×, 2× and 3× displays.
3. Confirm that layout code never receives this value in points.
4. Confirm that pixel buffers are recreated when the display scale changes.
5. Density does not read Dynamic Type, so text size is unaffected.

## Performance

Resolution is `O(1)`: one multiply by the precomputed display factor, which makes it the cheapest strategy. The explicit call is sub-nanosecond on current hardware once inlined; ambient calls take one uncontended lock. The value depends only on the display scale, so cache it per display rather than per window.
