# Linear default

[Strategy catalog](../STRATEGIES.md) · [Mathematics](../MATHEMATICS-AND-CALCULUS.md) · [API](../API.md)

## Purpose

Spacing, radii, component and text baselines.

## Formula / behavior

`value × selectedDimension / 300`.

## Swift usage

Use `16.sdp(c)`, `16.wdp(c)`, or `16.hdp(c)`. Enable aspect correction only after QA.

```swift
let configuration = DimensConfiguration(screenWidth: 390, screenHeight: 844)
let value = DynamicDimens.resolve(16, strategy: .scaled, configuration: configuration)
```

## Selection guidance

Start with `scaled`. Adopt this strategy only when its behavior matches an explicit design requirement, then test the 300-point baseline, phone portrait/landscape, tablet full screen, and a narrow multi-window allocation.

## Performance

Resolution is stateless and allocation-free. For repeated rendering, construct `DimensFactors` once when the window configuration changes rather than rediscovering metrics per element.
