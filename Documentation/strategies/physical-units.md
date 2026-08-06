# Physical units

[Strategy catalog](../STRATEGIES.md) · [Mathematics](../MATHEMATICS-AND-CALCULUS.md) · [API](../API.md)

## Purpose

Print-like or calibrated output.

## Formula / behavior

72 points/inch; optional calibrated PPI for pixels.

## Swift usage

Use `DimensUnits.points` or `.pixels`; provide PPI when physical accuracy matters.

```swift
let configuration = DimensConfiguration(screenWidth: 390, screenHeight: 844)
let value = DimensUnits.points(10, from: .millimeter, configuration: configuration)
```

## Selection guidance

Start with `scaled`. Adopt this strategy only when its behavior matches an explicit design requirement, then test the 300-point baseline, phone portrait/landscape, tablet full screen, and a narrow multi-window allocation.

## Performance

Resolution is stateless and allocation-free. For repeated rendering, construct `DimensFactors` once when the window configuration changes rather than rediscovering metrics per element.
