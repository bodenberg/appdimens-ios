# Power-law scaling

[Strategy catalog](../STRATEGIES.md) · [Mathematics](../MATHEMATICS-AND-CALCULUS.md) · [API](../API.md)

## What it is

Use **power** for a tunable perceptual curve.

## Mathematical theory

**Formula:** `result = v × (d/300)ᵖ`.

The exponent controls elasticity. `p=0` is fixed, `0<p<1` damps growth, `p=1` equals scaled, and `p>1` amplifies growth.

## Worked calculation

For `v=24`, `d=390`, `p=0.75`, the result is `24×1.3⁰·⁷⁵ ≈ 29.22 pt`.

## Swift usage

```swift
import AppDimensDynamic

let c = DimensConfiguration(screenWidth: 390, screenHeight: 844, displayScale: 3)
`let options = StrategyOptions(power: 0.75)`
`let icon = 24.powerDp(c, options: options)`
```

Use the numeric extension for concise token code or `DynamicDimens.resolve` when the strategy is selected at runtime. Both return `Double`; convert to `CGFloat` at the view boundary.

## Recommended use

Start near `0.75` for large-screen damping, then tune from design comparisons rather than device-name checks.

## Advantages

* Deterministic and stateless: identical configuration produces identical output.
* Constant-time calculation with no I/O, global cache, or UI-framework dependency.
* Supports explicit qualifiers through `StrategyOptions`.

## Trade-offs and misuse

Superlinear exponents can cause rapid growth. Negative exponents shrink values on larger windows and should have an explicit design rationale.

## Validation checklist

1. Verify the identity/reference behavior at `300 × 533`.
2. Compare phone portrait and landscape.
3. Test iPad full screen and a narrow split-view window.
4. Resize continuously on macOS or iPadOS and look for unintended jumps.
5. Test large Dynamic Type separately; geometric strategies do not automatically apply `fontScale`.

## Performance

Resolution is `O(1)`. For repeated rendering, construct `DimensFactors` once per window configuration where the strategy has a precomputed fast path; otherwise reuse `DimensConfiguration` and avoid rediscovering window metrics per element.
