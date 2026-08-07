# Contain / fit scaling

[Strategy catalog](../STRATEGIES.md) · [Mathematics](../MATHEMATICS-AND-CALCULUS.md) · [API](../API.md)

## What it is

Use **fit** for content that must remain fully inside a reference canvas.

## Mathematical theory

**Formula:** `result = v × min(w/300, h/533)`.

The smaller normalized axis is the active constraint. This is the same geometry as aspect-fit: it preserves proportions and can leave unused space on the other axis.

## Worked calculation

At `390×844`, the ratios are `1.3` and `1.583`; fit selects `1.3`, so a 180-point logo becomes `234 pt`.

## Swift usage

```swift
import AppDimensDynamic

let c = DimensConfiguration(screenWidth: 390, screenHeight: 844, displayScale: 3)
`let logo = 180.fitDp(c)`
`let card = DynamicDimens.resolve(320, strategy: .fit, configuration: c)`
```

Use the numeric extension for concise token code or `DynamicDimens.resolve` when the strategy is selected at runtime. Both return `Double`; convert to `CGFloat` at the view boundary.

## Recommended use

Use for illustrations, document previews, game boards, or groups that must never crop.

## Advantages

* Deterministic and stateless: identical configuration produces identical output.
* Constant-time calculation with no I/O, global cache, or UI-framework dependency.
* Supports explicit qualifiers through `StrategyOptions`.

## Trade-offs and misuse

Letterboxing or empty margins are expected. This does not inspect the actual child size; the formula assumes the 300×533 reference canvas.

## Validation checklist

1. Verify the identity/reference behavior at `300 × 533`.
2. Compare phone portrait and landscape.
3. Test iPad full screen and a narrow split-view window.
4. Resize continuously on macOS or iPadOS and look for unintended jumps.
5. Test large Dynamic Type separately; geometric strategies do not automatically apply `fontScale`.

## Performance

Resolution is `O(1)`. For repeated rendering, construct `DimensFactors` once per window configuration where the strategy has a precomputed fast path; otherwise reuse `DimensConfiguration` and avoid rediscovering window metrics per element.
