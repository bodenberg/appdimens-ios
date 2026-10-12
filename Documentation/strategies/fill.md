# Cover / fill scaling

[Strategy catalog](../STRATEGIES.md) · [Mathematics](../MATHEMATICS-AND-CALCULUS.md) · [API](../API.md)

## What it is

Use **fill** for backgrounds and media that must cover the reference canvas.

## Mathematical theory

**Formula:** `result = v × max(min/300, max/533)`, where `min` and `max` are the shorter and longer window sides.

The larger normalized side wins. This is aspect-fill geometry: it guarantees coverage but lets the other axis extend beyond its boundary. Because the sides are sorted, the result is the same in portrait and landscape.

## Worked calculation

At `390×844`, `min/300 = 1.3` and `max/533 ≈ 1.5835`, so fill selects `1.5835`; a 300-point token becomes `300 × 1.5835 ≈ 475.05 pt`.

## Swift usage

```swift
import AppDimensDynamic

let c = DimensConfiguration(screenWidth: 390, screenHeight: 844, displayScale: 3)
let backdrop = 300.fillDp(c)                                                 // ≈ 475.05
let hero = DynamicDimens.resolve(240, strategy: .fill, configuration: c)     // ≈ 380.04
```

## Recommended use

Use for backgrounds, bleed artwork, and dominant visuals where uncovered edges are unacceptable.

## Advantages

* Deterministic and stateless: identical configuration produces identical output.
* Constant-time calculation with no I/O, global cache, or UI-framework dependency.
* Ignores `qualifier`: it always reads both window sides.

## Trade-offs and misuse

Cropping or oversized content is inherent. Do not use for text, tap targets, or content that must remain visible.

## Validation checklist

1. Verify the identity/reference behavior at `300 × 533`: the factor is 1.
2. Compare phone portrait and landscape.
3. Test iPad full screen and a narrow split-view window.
4. Resize continuously on macOS or iPadOS and look for unintended jumps.
5. Test large Dynamic Type separately; geometric strategies do not automatically apply `fontScale`.

## Performance

Resolution is `O(1)`. The fill factor is precomputed once per window, so each call is a branch and a multiply once inlined, which is sub-nanosecond on current hardware. Ambient calls take one uncontended lock. For hot loops, `DimensFactors(c)` holds the fill factor for `.fill`.
