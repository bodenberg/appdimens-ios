# Literal percent scaling

[Strategy catalog](../STRATEGIES.md) · [Mathematics](../MATHEMATICS-AND-CALCULUS.md) · [API](../API.md)

## What it is

Use **percent** for columns, gutters, or geometry specified as an axis percentage. In the strategy engine, `percent` is the linear `p` satellite, which uses the same curve as scaled. The literal percentage of a window axis is the `space` family in `AppDimensPercent`.

## Mathematical theory

**Satellite formula (`percent` strategy, `p` prefix):** `result = v × d / 300`, identical to scaled, including the aspect-ratio variant (`psdpa`).

**Literal percent (`space` family):** `result = (p / 100) × D`, where `D` is the window width (`spaceW`), the window height (`spaceH`), the smallest side (`spaceSw`), or a reference length passed to `space(_:)`.

The two answer different questions. The satellite grows with the window at scaled speed. The literal percent is a fixed share of the axis.

## Worked calculation

For `v=16` and `d=390`, the satellite gives `16×390/300 = 20.8 pt`. For literal percentages, 10 % of a 390-point width is `0.10 × 390 = 39 pt`, and 25 % of an 844-point height is `211 pt`.

## Swift usage

```swift
import AppDimensDynamic
import AppDimensPercent

let c = DimensConfiguration(screenWidth: 390, screenHeight: 844, displayScale: 3)
let padding = 16.psdp(c)                                                      // 20.8, satellite
let column = 25.spaceW(c)                                                     // 97.5, 25 % of width
let sheetHeight = 50.spaceH(c)                                                // 422.0, 50 % of height
let gutter = 10.space(200)                                                    // 20 (CGFloat), 10 % of 200 pt
let runtime = DynamicDimens.resolve(16, strategy: .percent, configuration: c) // 20.8
```

Ambient literal forms such as `25.spaceW` return `CGFloat` for the current window, and `25.spaceW(c)` returns `Double` for an explicit window. `10.space(200)` does not read the window at all.

## Recommended use

Reserve literal percentages for requirements that literally say "X percent of the window." Prefer SwiftUI layout containers for flexible sibling allocation, and literal percent for numeric boundaries. Use the `p` satellite when a token name calls for it; its numbers match scaled.

## Advantages

* Deterministic and stateless: identical configuration produces identical output.
* Constant-time calculation with no I/O, global cache, or UI-framework dependency.
* The satellite supports explicit qualifiers through `StrategyOptions`; the literal `space` forms take the axis from their name.

## Trade-offs and misuse

Literal percent has no intrinsic minimum or maximum. 10 % of a 390-point width is 39 pt, but 1 % is 3.9 pt, which is unusable as a tap target. Clamp it in your code with `max(_:_:)` where a minimum applies.

## Validation checklist

1. Verify the satellite identity: `16.psdp(c)` returns `16` for `DimensConfiguration(screenWidth: 300, screenHeight: 533)`. Verify literal values separately: `25.spaceW(c)` is 25 % of the window width.
2. Compare phone portrait and landscape.
3. Test iPad full screen and a narrow split-view window.
4. Resize continuously on macOS or iPadOS and look for unintended jumps.
5. Test large Dynamic Type separately; geometric strategies do not automatically apply `fontScale`.

## Performance

Resolution is `O(1)`. The satellite follows the scaled rules: precomputed factors and no transcendental math per call. A literal percent is one multiply of `p / 100` by the axis read from the configuration. On the default path an explicit call is a branch and a multiply once inlined, which is sub-nanosecond on current hardware; ambient calls take one uncontended lock. For hot loops, `DimensFactors(c)` provides the default-path factor for `.percent`, which is the smallest-width factor.
