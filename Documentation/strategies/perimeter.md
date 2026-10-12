# Perimeter scaling

[Strategy catalog](../STRATEGIES.md) · [Mathematics](../MATHEMATICS-AND-CALCULUS.md) · [API](../API.md)

## What it is

Use **perimeter** for balanced two-axis growth without square roots.

## Mathematical theory

**Formula:** `result = v × (min + max) / 833`, where `min` and `max` are the shorter and longer window sides and `833 = 300 + 533`.

Width and height contribute additively, so the result is the same in portrait and landscape. Its derivative is constant in either axis, so it reacts uniformly to resizing and is cheaper to reason about than a diagonal.

## Worked calculation

At `390×844`, the factor is `(390 + 844)/833 ≈ 1.4814`; a 20-point token becomes `20 × 1.4814 ≈ 29.63 pt`.

## Swift usage

```swift
import AppDimensDynamic

let c = DimensConfiguration(screenWidth: 390, screenHeight: 844, displayScale: 3)
let handle = 20.perimeterDp(c)                                                  // ≈ 29.63
let runtime = DynamicDimens.resolve(20, strategy: .perimeter, configuration: c) // ≈ 29.63
```

## Recommended use

Use for canvas frames, overview screens, or decorative geometry when an arithmetic average-like response matches the design.

## Advantages

* Deterministic and stateless: identical configuration produces identical output.
* Constant-time calculation with no I/O, global cache, or UI-framework dependency.
* Ignores `qualifier`: it always reads both window sides.

## Trade-offs and misuse

A very long single axis still increases the result. Use fit when both dimensions must constrain content.

## Validation checklist

1. Verify the identity/reference behavior at `300 × 533`: `833 / 833 = 1`.
2. Compare phone portrait and landscape.
3. Test iPad full screen and a narrow split-view window.
4. Resize continuously on macOS or iPadOS and look for unintended jumps.
5. Test large Dynamic Type separately; geometric strategies do not automatically apply `fontScale`.

## Performance

Resolution is `O(1)`. The perimeter factor is precomputed once per window and needs no `sqrt`, so an explicit default-path call is a branch and a multiply once inlined, which is sub-nanosecond on current hardware. Ambient calls take one uncontended lock. For hot loops, `DimensFactors(c)` holds the perimeter factor for `.perimeter`.
