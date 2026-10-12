# Diagonal scaling

[Strategy catalog](../STRATEGIES.md) · [Mathematics](../MATHEMATICS-AND-CALCULUS.md) · [API](../API.md)

## What it is

Use **diagonal** for canvas objects whose perceived size depends on both axes.

## Mathematical theory

**Formula:** `result = v × √(min² + max²) / 611.6305`, where `min` and `max` are the shorter and longer window sides, and `611.6305 = √(300² + 533²)` is the reference diagonal.

The Euclidean norm treats the window as one length. Unlike smallest-width scaling, a change in the longer side changes the result even when the shorter side stays fixed. The qualifier is ignored, and the result is the same in portrait and landscape.

## Worked calculation

At `390×844`, `√(390² + 844²) ≈ 929.75` and the factor is `929.75 / 611.6305 ≈ 1.520`; an 18-point token becomes `18 × 1.520 ≈ 27.36 pt`.

## Swift usage

```swift
import AppDimensDynamic

let c = DimensConfiguration(screenWidth: 390, screenHeight: 844, displayScale: 3)
let marker = 18.diagonalDp(c)                                                  // ≈ 27.36
let value = DynamicDimens.resolve(18, strategy: .diagonal, configuration: c)   // ≈ 27.36, qualifier ignored
```

## Recommended use

Choose for maps, games, charts, or freeform canvases where both axes contribute to perceived scale.

## Advantages

* Deterministic and stateless: identical configuration produces identical output.
* Constant-time calculation with no I/O, global cache, or UI-framework dependency.
* Ignores `qualifier`: it always reads both window sides.

## Trade-offs and misuse

Very tall windows may enlarge UI even though horizontal room did not increase. Avoid for text columns and ordinary controls.

## Validation checklist

1. Verify the identity/reference behavior at `300 × 533`: the factor is 1 within the rounding of the `611.6305` constant.
2. Compare phone portrait and landscape.
3. Test iPad full screen and a narrow split-view window.
4. Resize continuously on macOS or iPadOS and look for unintended jumps.
5. Test large Dynamic Type separately; geometric strategies do not automatically apply `fontScale`.

## Performance

Resolution is `O(1)`. The diagonal factor is precomputed once per window, so no `sqrt` runs per call. An explicit default-path call is a branch and a multiply once inlined, which is sub-nanosecond on current hardware; ambient calls take one uncontended lock. For hot loops, `DimensFactors(c)` holds the diagonal factor for `.diagonal`.
