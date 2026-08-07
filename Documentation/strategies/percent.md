# Literal percent scaling

[Strategy catalog](../STRATEGIES.md) · [Mathematics](../MATHEMATICS-AND-CALCULUS.md) · [API](../API.md)

## What it is

Use **percent** for columns, gutters, or geometry specified as an axis percentage.

## Mathematical theory

**Formula:** `result = d × percent × v / 10,000`.

`v` and `percent` multiply to the effective percentage. The clearest convention is `percent=100` and `v` equal to the desired percentage: `v=10` means 10%.

## Worked calculation

For a 390-point width, `v=10` and `percent=100` produce `39 pt`.

## Swift usage

```swift
import AppDimensDynamic

let c = DimensConfiguration(screenWidth: 390, screenHeight: 844, displayScale: 3)
`let tenth = 10.percentDp(c, percent: 100, qualifier: .width)`
`let quarter = DynamicDimens.resolve(25, strategy: .percent, configuration: c, options: .init(qualifier: .height, percent: 100))`
```

Use the numeric extension for concise token code or `DynamicDimens.resolve` when the strategy is selected at runtime. Both return `Double`; convert to `CGFloat` at the view boundary.

## Recommended use

Reserve for requirements that literally say “X percent of the window.” Prefer SwiftUI layout containers for flexible sibling allocation and percent for numeric boundaries.

## Advantages

* Deterministic and stateless: identical configuration produces identical output.
* Constant-time calculation with no I/O, global cache, or UI-framework dependency.
* Supports explicit qualifiers through `StrategyOptions`.

## Trade-offs and misuse

Percent has no intrinsic minimum or maximum and can create unusably small tap targets. It is not the same as a 10-point token scaled by 10%.

## Validation checklist

1. Verify the identity/reference behavior at `300 × 533`.
2. Compare phone portrait and landscape.
3. Test iPad full screen and a narrow split-view window.
4. Resize continuously on macOS or iPadOS and look for unintended jumps.
5. Test large Dynamic Type separately; geometric strategies do not automatically apply `fontScale`.

## Performance

Resolution is `O(1)`. For repeated rendering, construct `DimensFactors` once per window configuration where the strategy has a precomputed fast path; otherwise reuse `DimensConfiguration` and avoid rediscovering window metrics per element.
