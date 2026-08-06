# Performance

## Design

- Calculation hot paths are `@inlinable` and O(1).
- Configuration is an immutable `Hashable`, `Sendable` value.
- There are no process-wide mutable caches, locks, notification observers, or dictionaries.
- SwiftUI reads one environment value shared by the scene.
- `DimensFactors` precomputes ratios for repeated render-loop use.
- Metal uniforms occupy four aligned `SIMD4<Float>` lanes (64 bytes).
- Metal buffers are created once and updated in place after configuration changes.
- Resize uses O(log n) binary search after building its bounded step table.

## Avoiding unnecessary SwiftUI work

Place `.appDimens()` once at the scene root. Do not nest providers. `@ScaledDimension` depends only on the configuration environment and recalculates when that value changes.

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

CI runs debug tests, Thread Sanitizer, release compilation, and aggregate module builds against iOS, tvOS, watchOS, visionOS, and macOS SDKs.
