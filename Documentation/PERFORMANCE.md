# Performance

## Design

- Calculation hot paths are `@inlinable` and O(1).
- Configuration is an immutable `Hashable`, `Sendable` value.
- There are no process-wide mutable caches, locks, notification observers, or dictionaries.
- SwiftUI reads one environment value shared by the scene.
- `DimensFactors` precomputes ratios for repeated render-loop use.
- Strategy dispatch computes only the operands selected by its branch; plain and physical values do no geometry work.
- Metal uniforms occupy four aligned `SIMD4<Float>` lanes (64 bytes).
- Metal buffers are created once and updated in place after configuration changes.
- Resize uses O(log n) binary search after building its bounded step table.

## Avoiding unnecessary SwiftUI work

Place `.appDimens()` once at the scene root. Do not nest providers. `@ScaledDimension` depends only on the configuration environment and recalculates when that value changes.

`DimensConfiguration` is `Hashable`, so writing the same metrics does not invalidate environment consumers. Keep the provider above stable screen content, and never attach one provider to every row. A real window resize or Dynamic Type change must invalidate dependent views; that is necessary work rather than an avoidable recomposition.

## Hot loops

Precompute factors whenever the configuration changes instead of repeating diagonal, perimeter, fit or fill calculations for every element:

```swift
let factors = DimensFactors(configuration)
let widths = source.map { factors.resolve($0, strategy: .fit) }
```

The fast path is immutable, `Sendable`, allocation-free per resolution and falls back to the complete strategy engine for option-dependent curves. Measure the consuming application in Instruments—absolute nanosecond claims are intentionally avoided because CPU, compiler optimization, thermal state and workload change the result.

## Metal

```swift
let buffer = AppDimensMetal.makeBuffer(device: device, configuration: config)!
if config != previousConfig {
    AppDimensMetal.update(buffer, configuration: config)
    previousConfig = config
}
```

Never allocate a new buffer per frame. Keep layout values in points and use `displayScale` only for explicit pixel conversion.

## Validation

CI runs debug tests, Thread Sanitizer, release compilation, and aggregate module builds against iOS, tvOS, watchOS, visionOS, and macOS SDKs. The watch build proves that unavailable UI, SIMD-uniform, and Metal APIs are removed at compilation while the aggregate module remains importable. Every SDK job uploads its complete `xcodebuild` log and prints extracted compiler diagnostics in the job summary on failure.
