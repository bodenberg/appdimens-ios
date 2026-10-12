# Performance

[Documentation hub](README.md) · [API](API.md) · [Metal](METAL.md)

## Design

* **All transcendental math happens once per window.** `DimensConfiguration.init` computes `DimenMetrics`: every strategy factor (`scale`, width/height factors, SDPA multiplier, power, fluid, auto, interpolated, logarithmic, diagonal, perimeter, fit, fill, AR multiplier). Kernels on the default path are one branch and one multiply — Android's 3.2 "fast lane" with no cache to invalidate.
* **No allocation** on any resolution path; all hot APIs are `@inlinable` and specialize into the caller.
* **Ambient reads** take one uncontended unfair lock around pointer-backed storage (no Swift exclusivity checks, no reference counting). Observation registration (~20 ns) happens only on the main thread and only after a SwiftUI provider is installed.
* Equality/hash of `DimensConfiguration` cover raw inputs only, so redundant updates are detected cheaply and ignored.

## Measured (Linux x86-64 VM, release, 1 M values per run)

| Benchmark | Per value |
|---|---|
| `(i & 63).sdp(configuration)` | ≈ 0.6 ns |
| `DimensFactors.resolve(_:strategy: .power)` | ≈ 0.6 ns |
| `(i & 63).sdp` ambient (pthread mutex) | ≈ 16 ns |
| `(i & 63).pwsdpa` ambient | ≈ 16 ns |
| `DimensConfiguration(...)` + metrics | ≈ 40 ns |

On Apple platforms the ambient lock is `os_unfair_lock`, typically cheaper than the Linux mutex. Reproduce with:

```bash
swift test -c release --filter PerformanceTests
```

## Choosing the fastest path

| Situation | Use |
|---|---|
| SwiftUI / UIKit view code | `16.sdp` — cost is negligible next to layout |
| Thousands of values per frame (charts, particles, text layout) | `let f = DimensFactors(c)` then `f.resolve(_:strategy:)` or `f.resolve(&buffer, strategy:)` |
| Several values from one coherent snapshot | `AppDimens.withConfiguration { c in … 16.sdp(c) … }` |
| Background threads / tests | explicit `16.sdp(c)` |
| GPU | `AppDimensUniforms` + `appdimens_*` helpers |
