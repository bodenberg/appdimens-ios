# Constraint resize

[Strategy catalog](../STRATEGIES.md) · [Mathematics](../MATHEMATICS-AND-CALCULUS.md) · [API](../API.md)

## Purpose

Fit-to-container problems.

## Formula / behavior

binary search for the largest fitting candidate.

## Swift usage

Generate bounded steps and call `largestFitting`; keep the predicate monotonic.

```swift
let configuration = DimensConfiguration(screenWidth: 390, screenHeight: 844)
let value = DimensResize.largestFitting(DimensResize.steps(minimum: 10, maximum: 30, step: 1)) { $0 <= 24 }
```

## Selection guidance

Start with `scaled`. Adopt this strategy only when its behavior matches an explicit design requirement, then test the 300-point baseline, phone portrait/landscape, tablet full screen, and a narrow multi-window allocation.

## Performance

Resolution is stateless and allocation-free. For repeated rendering, construct `DimensFactors` once when the window configuration changes rather than rediscovering metrics per element.
