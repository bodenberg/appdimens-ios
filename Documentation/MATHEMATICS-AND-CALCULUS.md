# Mathematics and calculus

[Documentation hub](README.md) · [Strategies](STRATEGIES.md)

Let `v` be the design value, `d` the selected window dimension in points, and `B = 300` the reference. Apple points are already density independent.

| Strategy | Scale / result | Character |
|---|---|---|
| scaled | `v × d/B` | linear, default |
| density | `v × d/B × displayScale` | pixel-density-aware |
| diagonal | `v × hypot(w,h)/hypot(300,533)` | screen diagonal |
| perimeter | `v × (w+h)/833` | frame size |
| fit | `v × min(w/300,h/533)` | contain |
| fill | `v × max(w/300,h/533)` | cover |
| interpolated | `v × (1 + (d/B−1)t)`, `t∈[0,1]` | blend |
| power | `v × (d/B)^p` | sub/super-linear |
| percent | `d × percent × v / 10,000` | axis fraction |
| fluid | `v × lerp(scaleLow,scaleHigh,clamp((d−low)/(high−low)))` | bounded ramp |
| logarithmic | symmetric log correction around `d/B=1` | damped growth |

## Aspect correction

The optional aspect branch normalizes `aspect = max(w,h)/min(w,h)` against `1.78`, then applies sensitivity `k` to the linear slope. It is opt-in because a project should not silently change its baseline curve.

## Text

`sp = dp × fontScale` when Dynamic Type scaling is enabled. `sem/hem/wem` use the same geometric curve without multiplying by `fontScale`.

## Continuity and monotonicity

Scaled, diagonal, perimeter, fit and fill are continuous for positive dimensions. Fluid is continuous at its clamps. Percent is linear in the selected axis. Power requires a positive ratio (guaranteed by `DimensConfiguration`). The logarithmic branch is joined at ratio `1`.

## Rounding

The engine returns `Double`. Convert to `CGFloat` only at the UI boundary and allow SwiftUI/UIKit to rasterize points using display scale. Premature integer rounding creates cumulative layout drift.
