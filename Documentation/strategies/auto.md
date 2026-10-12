# Adaptive conditions (`autoDp()` / `autoSp()`)

[Strategy catalog](../STRATEGIES.md) · [Mathematics](../MATHEMATICS-AND-CALCULUS.md) · [API](../API.md)

## What it is

Auto selects a design token from explicit breakpoints, then applies the AUTO curve to the selected value. That curve is linear (`v × d / 300`) up to 480 points and logarithmic beyond. It is a breakpoint tool, not a new device model. Use it when the design truly changes at a boundary, for example a larger sidebar gutter at 700 points, not merely because devices have different names.

## Selection theory and precedence

Each entry has a priority: 1 is UI mode plus qualifier threshold, 2 is UI mode, 3 is qualifier threshold, and 4 is orientation only. Entries are sorted by priority, then by the larger qualifier threshold, then by the order they were added. The first matching entry wins; if none matches, the base value wins. A qualifier threshold matches inclusively (`dimension ≥ minimum`).

The selected value is the input to the AUTO curve, not the final size. For `v=16` at 390 points with no entry matching, the result is `16 × 390/300 = 20.8 pt`. At 600 points the same token is `16 × (1.6 + 0.4 × ln 1.4) ≈ 27.75 pt`, not the linear 32 pt. The curve is continuous at 480 points, but its slope falls by a factor of 2.5 there.

## Complete Swift example

```swift
import AppDimensDynamic

let phone = DimensConfiguration(screenWidth: 390, screenHeight: 844, displayScale: 3)
let tablet = DimensConfiguration(screenWidth: 1024, screenHeight: 768, displayScale: 2)

let padding = 16.autoDp()
    .screen(.desk, customValue: 32)               // priority 2: UI mode
    .screen(.smallWidth, 600, customValue: 24)    // priority 3: smallest width ≥ 600
    .screen(.landscape, customValue: 12)          // priority 4: orientation only

let phonePadding = padding.sdp(phone)     // 20.8: no entry matches, base 16 on the AUTO curve
let tabletPadding = padding.sdp(tablet)   // ≈ 44.86: priority-3 entry, 24 on the AUTO curve

let label = 15.autoSp()
    .screen(.width, 700, customValue: 17)         // priority 3: width ≥ 700
let labelSize = label.ssp(tablet)                 // ≈ 31.78: 17 × AUTO(768), font scale 1
```

`autoSp()` builders multiply the resolved value by `fontScale` when enabled. Pass `fontScale: false` only for text-like geometry that intentionally must not follow Dynamic Type.

## Recommendation

Keep breakpoint lists short, name them as design tokens, and use window widths rather than device models. Prefer scaled for continuous changes and auto only for discrete structural changes. Test one point below, exactly at, and one point above each threshold, plus conflicting conditions.

## Trade-offs

Breakpoints create discontinuities and can become hard to maintain when scattered through views. A fluid curve is better for smooth bounded growth. Custom values pass through the AUTO curve, so a 24-point entry on a 768-point window is not 24 points. `ignoreMultiWindows(true)` returns the unscaled selected value in a multi-window configuration; validate that behavior rather than assuming full-screen tablet sizing.

## Performance

Resolution is `O(1)` on the kernel. On the smallest-width path the AUTO factor is precomputed once per window, so no `log` runs per call. Width and height qualifiers evaluate the AUTO function on each call, including `log` above 480 points. Choosing an entry is a short linear scan over the few entries a builder holds, so builder resolution costs more than a single multiply. Builders are immutable values: create them once, for example as static constants, rather than inside a `body`. Ambient `sdp` reads take one uncontended lock.
