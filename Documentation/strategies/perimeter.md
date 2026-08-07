# Perimeter scaling

[Strategy catalog](../STRATEGIES.md) · [Mathematics](../MATHEMATICS-AND-CALCULUS.md) · [API](../API.md)

## What it is

Use **perimeter** for balanced two-axis growth without square roots.

## Mathematical theory

**Formula:** `result = v × (w + h) / 833`.

Width and height contribute additively. Its derivative is constant in either axis, so it reacts uniformly to resizing and is cheaper to reason about than a diagonal.

## Worked calculation

At `390×844`, the factor is `1234/833 ≈ 1.481`; a 20-point token becomes about `29.63 pt`.

## Swift usage

```swift
import AppDimensDynamic

let c = DimensConfiguration(screenWidth: 390, screenHeight: 844, displayScale: 3)
`let handle = 20.perimeterDp(c)`
```

Use the numeric extension for concise token code or `DynamicDimens.resolve` when the strategy is selected at runtime. Both return `Double`; convert to `CGFloat` at the view boundary.

## Recommended use

Use for canvas frames, overview screens, or decorative geometry when an arithmetic average-like response matches the design.

## Advantages

* Deterministic and stateless: identical configuration produces identical output.
* Constant-time calculation with no I/O, global cache, or UI-framework dependency.
* Supports explicit qualifiers through `StrategyOptions`.

## Trade-offs and misuse

A very long single axis still increases the result. Use fit when both dimensions must constrain content.

## Validation checklist

1. Verify the identity/reference behavior at `300 × 533`.
2. Compare phone portrait and landscape.
3. Test iPad full screen and a narrow split-view window.
4. Resize continuously on macOS or iPadOS and look for unintended jumps.
5. Test large Dynamic Type separately; geometric strategies do not automatically apply `fontScale`.

## Performance

Resolution is `O(1)`. For repeated rendering, construct `DimensFactors` once per window configuration where the strategy has a precomputed fast path; otherwise reuse `DimensConfiguration` and avoid rediscovering window metrics per element.
