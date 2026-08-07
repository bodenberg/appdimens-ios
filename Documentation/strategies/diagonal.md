# Diagonal scaling

[Strategy catalog](../STRATEGIES.md) · [Mathematics](../MATHEMATICS-AND-CALCULUS.md) · [API](../API.md)

## What it is

Use **diagonal** for canvas objects whose perceived size depends on both axes.

## Mathematical theory

**Formula:** `result = v × hypot(w,h) / hypot(300,533)`.

The Euclidean norm treats the window vector `(w,h)` as one length. Unlike smallest-width scaling, a height change can affect the result even when width stays fixed.

## Worked calculation

At `390×844`, the factor is `hypot(390,844)/611.628 ≈ 1.520`; an 18-point token becomes about `27.36 pt`.

## Swift usage

```swift
import AppDimensDynamic

let c = DimensConfiguration(screenWidth: 390, screenHeight: 844, displayScale: 3)
`let marker = 18.diagonalDp(c)`
`let value = DynamicDimens.resolve(18, strategy: .diagonal, configuration: c)`
```

Use the numeric extension for concise token code or `DynamicDimens.resolve` when the strategy is selected at runtime. Both return `Double`; convert to `CGFloat` at the view boundary.

## Recommended use

Choose for maps, games, charts, or freeform canvases where both axes contribute to perceived scale.

## Advantages

* Deterministic and stateless: identical configuration produces identical output.
* Constant-time calculation with no I/O, global cache, or UI-framework dependency.
* Supports explicit qualifiers through `StrategyOptions`.

## Trade-offs and misuse

Very tall windows may enlarge UI even though horizontal room did not increase. Avoid for text columns and ordinary controls.

## Validation checklist

1. Verify the identity/reference behavior at `300 × 533`.
2. Compare phone portrait and landscape.
3. Test iPad full screen and a narrow split-view window.
4. Resize continuously on macOS or iPadOS and look for unintended jumps.
5. Test large Dynamic Type separately; geometric strategies do not automatically apply `fontScale`.

## Performance

Resolution is `O(1)`. For repeated rendering, construct `DimensFactors` once per window configuration where the strategy has a precomputed fast path; otherwise reuse `DimensConfiguration` and avoid rediscovering window metrics per element.
