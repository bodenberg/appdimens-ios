# Percent

[Strategy catalog](../STRATEGIES.md) · [Mathematics](../MATHEMATICS-AND-CALCULUS.md) · [API](../API.md)

## Purpose

Explicit fractions of a window axis.

## Formula / behavior

selected axis × percent × value / 10,000.

## Swift usage

With percent 100, a value of 10 means 10% of the selected dimension.

```swift
let configuration = DimensConfiguration(screenWidth: 390, screenHeight: 844)
let value = DynamicDimens.resolve(16, strategy: .percent, configuration: configuration)
```

## Selection guidance

Start with `scaled`. Adopt this strategy only when its behavior matches an explicit design requirement, then test the 300-point baseline, phone portrait/landscape, tablet full screen, and a narrow multi-window allocation.

## Performance

Resolution is stateless and allocation-free. For repeated rendering, construct `DimensFactors` once when the window configuration changes rather than rediscovering metrics per element.
