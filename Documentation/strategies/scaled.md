# Linear scaling

[Strategy catalog](../STRATEGIES.md) · [Mathematics](../MATHEMATICS-AND-CALCULUS.md) · [API](../API.md)

## What it is

Use **scaled** for general spacing, radii, controls, and design tokens.

## Mathematical theory

**Formula:** `result = v × d / 300`.

The output preserves ratios: doubling the effective axis doubles the token. At the 300-point reference it is the identity function.

## Worked calculation

For `v=16` and `d=390`, the result is `16×390/300 = 20.8 pt`.

## Swift usage

```swift
import AppDimensDynamic

let c = DimensConfiguration(screenWidth: 390, screenHeight: 844, displayScale: 3)
`let padding = 16.sdp(c)`
`let width = 120.wdp(c)`
`let rowHeight = 44.hdp(c)`
```

Use the numeric extension for concise token code or `DynamicDimens.resolve` when the strategy is selected at runtime. Both return `Double`; convert to `CGFloat` at the view boundary.

## Recommended use

Prefer this default until a concrete requirement proves that another curve is better. Use `.smallWidth` for rotation-stable tokens, `.width` for horizontal geometry, and `.height` only for vertical geometry.

## Advantages

* Deterministic and stateless: identical configuration produces identical output.
* Constant-time calculation with no I/O, global cache, or UI-framework dependency.
* Supports explicit qualifiers through `StrategyOptions`.

## Trade-offs and misuse

Linear growth can make controls excessively large on wide desktop windows. Consider power, logarithmic, or fluid there.

## Validation checklist

1. Verify the identity/reference behavior at `300 × 533`.
2. Compare phone portrait and landscape.
3. Test iPad full screen and a narrow split-view window.
4. Resize continuously on macOS or iPadOS and look for unintended jumps.
5. Test large Dynamic Type separately; geometric strategies do not automatically apply `fontScale`.

## Performance

Resolution is `O(1)`. For repeated rendering, construct `DimensFactors` once per window configuration where the strategy has a precomputed fast path; otherwise reuse `DimensConfiguration` and avoid rediscovering window metrics per element.
