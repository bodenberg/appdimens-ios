# Adaptive conditions

[Strategy catalog](../STRATEGIES.md) · [Mathematics](../MATHEMATICS-AND-CALCULUS.md) · [API](../API.md)

## Purpose

Breakpoint-driven product requirements.

## Formula / behavior

ordered mode/orientation/threshold selection followed by scaling.

## Swift usage

Use `AutoDp`/`AutoSp`; later matching rules have explicit priority semantics.

```swift
let configuration = DimensConfiguration(screenWidth: 390, screenHeight: 844)
let value = AutoDp(16).qualifier(20, .width, minimum: 600).resolve(configuration)
```

## Selection guidance

Start with `scaled`. Adopt this strategy only when its behavior matches an explicit design requirement, then test the 300-point baseline, phone portrait/landscape, tablet full screen, and a narrow multi-window allocation.

## Performance

Resolution is stateless and allocation-free. For repeated rendering, construct `DimensFactors` once when the window configuration changes rather than rediscovering metrics per element.
