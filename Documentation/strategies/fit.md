# Contain / fit scaling

[Strategy catalog](../STRATEGIES.md) · [Mathematics](../MATHEMATICS-AND-CALCULUS.md) · [API](../API.md)

## What it is

Use **fit** for content that must remain fully inside a reference canvas.

## Mathematical theory

**Formula:** `result = v × min(min/300, max/533)`, where `min` and `max` are the shorter and longer window sides.

The smaller normalized side is the active constraint. This is the same geometry as aspect-fit: it preserves proportions and can leave unused space on the other axis. Because the sides are sorted, the result is the same in portrait and landscape.

## Worked calculation

At `390×844`, the ratios are `min/300 = 1.3` and `max/533 ≈ 1.5835`; fit selects `1.3`, so a 180-point logo becomes `180 × 1.3 = 234 pt`.

## Swift usage

```swift
import AppDimensDynamic

let c = DimensConfiguration(screenWidth: 390, screenHeight: 844, displayScale: 3)
let logo = 180.fitDp(c)                                                      // 234.0
let card = DynamicDimens.resolve(320, strategy: .fit, configuration: c)      // 416.0
```

## Recommended use

Use for illustrations, document previews, game boards, or groups that must never crop.

## Advantages

* Deterministic and stateless: identical configuration produces identical output.
* Constant-time calculation with no I/O, global cache, or UI-framework dependency.
* Ignores `qualifier`: it always reads both window sides.

## Trade-offs and misuse

Letterboxing or empty margins are expected. This does not inspect the actual child size; the formula assumes the 300×533 reference canvas.

## Validation checklist

1. Verify the identity/reference behavior at `300 × 533`: the factor is 1.
2. Compare phone portrait and landscape.
3. Test iPad full screen and a narrow split-view window.
4. Resize continuously on macOS or iPadOS and look for unintended jumps.
5. Test large Dynamic Type separately; geometric strategies do not automatically apply `fontScale`.

## Performance

Resolution is `O(1)`. The fit factor is precomputed once per window, so each call is a branch and a multiply once inlined, which is sub-nanosecond on current hardware. Ambient calls take one uncontended lock. For hot loops, `DimensFactors(c)` holds the fit factor for `.fit`.
