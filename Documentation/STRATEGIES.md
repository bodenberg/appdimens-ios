# Scaling strategies

All strategies share the same window configuration and baseline `300 × 533` points.

| Strategy | Formula / behavior | Recommended use |
|---|---|---|
| scaled | `value × axis / 300` | general layout |
| auto | scaled formula after conditional value selection | responsive design tokens |
| density | scaled value × display scale | explicit pixel paths |
| diagonal | diagonal ratio to `hypot(300, 533)` | two-dimensional surfaces |
| perimeter | `(width + height) / 833` | balanced 2D growth |
| fit | minimum of width and height baseline ratios | content that must fit |
| fill | maximum baseline ratio | content that must cover |
| fluid | clamped interpolation between scale limits | bounded responsive UI |
| interpolated | blend fixed and linear scaling | restrained scaling |
| logarithmic | logarithmically damped growth | large displays |
| percent | literal percentage of selected axis | proportional space |
| power | `axisRatio ^ exponent` | perceptual scaling |
| physical | unchanged; use Units for conversion | physical measurement |
| plain | unchanged | conditional branch only |

## Examples

```swift
let config = DimensConfiguration(screenWidth: 1024, screenHeight: 768)
let icon = 24.powerDp(config, options: .init(power: 0.75))
let card = 320.fitDp(config)
let background = 320.fillDp(config)
let gutter = 100.percentDp(config, percent: 4, qualifier: .width)
let fluid = 16.fluidDp(config, options: .init(
    fluidViewport: 320...1024,
    fluidScale: 0.85...1.3
))
```

## Aspect and multi-window

Every strategy accepts the common options. `ignoreMultiWindows` returns the unscaled base value when the current window is constrained relative to its display. Aspect correction is applied by the principal scaled path; strategies with their own geometric formula already incorporate both axes.

## Performance

Construct `DimensFactors` once after a window change for render loops. Standard calls are O(1); no I/O, locks, reflection, or global dictionary is used.
