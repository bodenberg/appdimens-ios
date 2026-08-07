# Cover / fill scaling

[Strategy catalog](../STRATEGIES.md) · [Mathematics](../MATHEMATICS-AND-CALCULUS.md) · [API](../API.md)

## What it is

Use **fill** for backgrounds and media that must cover the reference canvas.

## Mathematical theory

**Formula:** `result = v × max(w/300, h/533)`.

The larger normalized axis wins. This is aspect-fill geometry: it guarantees coverage but lets the other axis extend beyond its boundary.

## Worked calculation

At `390×844`, fill selects `844/533 ≈ 1.583`; a 300-point token becomes about `475.05 pt`.

## Swift usage

```swift
import AppDimensDynamic

let c = DimensConfiguration(screenWidth: 390, screenHeight: 844, displayScale: 3)
`let backdrop = 300.fillDp(c)`
`let hero = DynamicDimens.resolve(240, strategy: .fill, configuration: c)`
```

Use the numeric extension for concise token code or `DynamicDimens.resolve` when the strategy is selected at runtime. Both return `Double`; convert to `CGFloat` at the view boundary.

## Recommended use

Use for backgrounds, bleed artwork, and dominant visuals where uncovered edges are unacceptable.

## Advantages

* Deterministic and stateless: identical configuration produces identical output.
* Constant-time calculation with no I/O, global cache, or UI-framework dependency.
* Supports explicit qualifiers through `StrategyOptions`.

## Trade-offs and misuse

Cropping or oversized content is inherent. Do not use for text, tap targets, or content that must remain visible.

## Validation checklist

1. Verify the identity/reference behavior at `300 × 533`.
2. Compare phone portrait and landscape.
3. Test iPad full screen and a narrow split-view window.
4. Resize continuously on macOS or iPadOS and look for unintended jumps.
5. Test large Dynamic Type separately; geometric strategies do not automatically apply `fontScale`.

## Performance

Resolution is `O(1)`. For repeated rendering, construct `DimensFactors` once per window configuration where the strategy has a precomputed fast path; otherwise reuse `DimensConfiguration` and avoid rediscovering window metrics per element.
