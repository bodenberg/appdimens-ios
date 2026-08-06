# Bounded fluid ramp

[Strategy catalog](../STRATEGIES.md) · [Mathematics](../MATHEMATICS-AND-CALCULUS.md) · [API](../API.md)

## Purpose

Controlled growth over a known device band.

## Formula / behavior

linear interpolation between viewport and scale ranges.

## Swift usage

Use `.fluid` with `StrategyOptions(fluidViewport: 320...768, fluidScale: 0.8...1.2)`.

```swift
let configuration = DimensConfiguration(screenWidth: 390, screenHeight: 844)
let value = DynamicDimens.resolve(16, strategy: .fluid, configuration: configuration)
```

## Selection guidance

Start with `scaled`. Adopt this strategy only when its behavior matches an explicit design requirement, then test the 300-point baseline, phone portrait/landscape, tablet full screen, and a narrow multi-window allocation.

## Performance

Resolution is stateless and allocation-free. For repeated rendering, construct `DimensFactors` once when the window configuration changes rather than rediscovering metrics per element.
