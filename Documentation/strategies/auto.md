# Adaptive conditions (`AutoDp` / `AutoSp`)

[Strategy catalog](../STRATEGIES.md) · [Mathematics](../MATHEMATICS-AND-CALCULUS.md) · [API](../API.md)

## What it is

Auto selects a design token from explicit conditions and then applies the normal scaled equation. It is a breakpoint tool, not a new curve. Use it when the design truly changes at a boundary—for example, a larger sidebar gutter at 700 points—not merely because devices have different names.

## Selection theory and precedence

A condition can combine UI mode, minimum qualifier, and orientation. Matching entries are sorted by specificity: mode contributes 4, qualifier 2, and orientation 1. Higher specificity wins; equal specificity prefers the larger minimum, then the entry registered first. If nothing matches, the base value wins.

This gives deterministic, order-resistant breakpoint behavior. At a threshold, matching is inclusive (`dimension >= minimum`). After selection, scaled math is `selectedValue × selectedDimension / 300`; optional aspect and multi-window rules apply there.

## Complete Swift example

```swift
import AppDimensDynamic

let token = AutoDp(16)
    .qualifier(20, .width, minimum: 600)
    .screen(24, condition: AutoCondition(
        mode: .mac,
        orientation: .landscape,
        qualifier: .width,
        minimum: 900
    ))
    .aspectRatio(true, sensitivity: 0.08)

let phone = DimensConfiguration(screenWidth: 390, screenHeight: 844)
let tablet = DimensConfiguration(screenWidth: 1024, screenHeight: 768, uiMode: .mac)
let phonePadding = token.resolve(phone)   // base 16 is selected, then scaled
let tabletPadding = token.resolve(tablet) // most-specific matching value is selected

let label = AutoSp(15, fontScale: true)
    .screen(17, condition: .init(qualifier: .width, minimum: 700))
    .resolve(tablet)
```

`AutoSp` multiplies the resolved geometry by `fontScale` when enabled. Use `fontScale: false` only for text-like geometry that intentionally must not follow Dynamic Type.

## Recommendation

Keep breakpoint lists short, name them as design tokens, and use window widths rather than device models. Prefer scaled for continuous changes and auto only for discrete structural changes. Test one point below, exactly at, and one point above each threshold, plus conflicting conditions.

## Trade-offs

Breakpoints create discontinuities and can become hard to maintain when scattered through views. A fluid curve is better for smooth bounded growth. `ignoreMultiWindows(true)` returns the unscaled selected value in a multi-window configuration; validate that behavior rather than assuming full-screen tablet sizing.
