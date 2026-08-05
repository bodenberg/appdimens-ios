# Architecture and algorithm

## Dependency direction

```text
AppDimensUI  ───▶  AppDimens
(SwiftUI/UIKit)   (Foundation/CoreGraphics only)
```

The package deliberately avoids an umbrella target that creates circular imports. Consumers select only the module they need.

## Resolution pipeline

1. Find the last override whose qualifiers all match.
2. Select the configured current axis and corresponding reference axis.
3. Calculate `linearScale = currentLength / referenceLength`.
4. Apply strategy:
   - `none`: `1`
   - `linear` and `clamped`: `linearScale`
   - `balanced`: `sqrt(linearScale)`, damping screen extremes
5. Clamp scale to `minimumScale...maximumScale` (defaults `0.75...1.5`).
6. Multiply the selected source value.
7. For text, optionally multiply Dynamic Type scale.
8. Apply absolute limits.
9. Round to the display pixel grid.

The default shortest-axis canvas is 360 points. For `360 × 800`, a value remains unchanged. For a shortest side of 720, balanced scaling is `sqrt(720/360) ≈ 1.414`, rather than doubling every control.

## iOS-specific decisions

- **Container over screen:** `GeometryReader` observes the available window; `UIScreen.main.bounds` is wrong for split-screen layouts.
- **Points over dp:** both are logical concepts, but no fake Android density conversion is performed.
- **Dynamic Type over sp:** font accessibility categories are part of context and opt in via text resolution.
- **Traits over device lists:** idiom and size classes survive new hardware and multitasking configurations.
- **No global mutable cache:** calculation is constant-time and value semantics eliminate stale rotation/window values and locking hazards.

## Thread safety and performance

Core public data structures are immutable-by-convention value types and `Sendable`. A declaration may be stored as a static value and resolved on any actor. Resolution is O(number of overrides), normally a tiny list, with no allocation except declaration construction.
